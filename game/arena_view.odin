package karl2d_game

import k2 "../../karl2d"
import hm "core:/container/handle_map"
import "core:fmt"
import "core:math/rand"
import "core:strings"
import "core:time"

// another fake view to control game mechanics
ARENA_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

Tier :: struct {
	enemies: []struct {
		prefab: NPCPrefab,
		count:  int,
	},
	timer:   time.Duration,
	rewards: []struct {
		prefab: ItemPrefab,
		chance: f32,
	},
	gold:    int,
}

@(private = "file")
purse: int = 0

@(private = "file")
spawn_timer: f32 = 0.0

@(private = "file")
current_tier: int = 0

@(private = "file")
current_tier_duration_timer: time.Duration

@(private = "file")
spawn_points: [dynamic]k2.Vec2

@(private = "file")
current_tiers: []Tier = {
	Tier {
		enemies = {{.PUNCHING_BAG, 1}},
		timer = time.Second * 30,
		rewards = {{.RED_POTION, 1.0}, {.CUTLASS, 1.0}},
		gold = 10,
	},
	Tier {
		enemies = {{.PUNCHING_BAG, 3}},
		timer = time.Second * 30,
		rewards = {{.RED_POTION, 1.0}},
		gold = 40,
	},
	Tier {
		enemies = {{.PUNCHING_BAG, 3}},
		timer = time.Second * 30,
		rewards = {{.RED_POTION, 1.0}, {.RED_POTION, 0.5}, {.RED_POTION, 0.25}},
		gold = 40,
	},
	Tier {
		enemies = {{.PUNCHING_BAG, 3}},
		timer = time.Second * 30,
		rewards = {{.RED_POTION, 1.0}},
		gold = 40,
	},
	Tier {
		enemies = {{.PUNCHING_BAG, 3}},
		timer = time.Second * 30,
		rewards = {{.RED_POTION, 1.0}, {.RED_POTION, 0.5}, {.RED_POTION, 0.25}},
		gold = 40,
	},
	Tier {
		enemies = {{.PUNCHING_BAG, 3}},
		timer = time.Second * 30,
		rewards = {{.RED_POTION, 1.0}},
		gold = 40,
	},
}

ARENA_MIN_WAVE_COOLDOWN: f32 : 3.0
ARENA_MAX_WAVE_COOLDOWN: f32 : 10.0

@(private = "file")
open_view :: proc() {
	// we are controlling the game view, so it must be available
	if !is_view_open(&GAME_VIEW) do pop_view()

	spawn_timer = 0.0
	current_tier = 0
	purse = 0
	clear(&spawn_points)

	if len(current_tiers) > 0 {
		current_tier_duration_timer = current_tiers[current_tier].timer
	} else {
		current_tier_duration_timer = 0
	}

	for layer in tiled_map.layers {
		if layer.type == .tilelayer do continue
		for object in layer.objects {
			if strings.starts_with(object.name, "enemy_spawn") {
				append(&spawn_points, k2.Vec2{auto_cast object.x, auto_cast object.y})
			}
		}
	}

	when ODIN_OS == .JS {
		// You could do this on non-JS (web) as well, I just try both so we get test coverage of
		// these different modes of operation.
		game_music = k2.load_audio_stream_from_bytes(#load(MUSIC_FILE))
	} else {
		game_music = k2.load_audio_stream_from_file(MUSIC_FILE)
	}
	k2.set_audio_stream_loop(game_music, true)
	k2.play_audio_stream(game_music)
}

tier_spawn_cooldown :: proc(tier: Tier) -> f32 {
	tier_seconds := f32(tier.timer / time.Second)
	if tier_seconds <= 0 {
		return ARENA_MIN_WAVE_COOLDOWN
	}

	return clamp(tier_seconds / 3.0, ARENA_MIN_WAVE_COOLDOWN, ARENA_MAX_WAVE_COOLDOWN)
}

arena_center :: proc() -> k2.Vec2 {
	return {
		f32(tiled_map.width * tiled_map.tile_width) / 2.0 - 8,
		f32(tiled_map.height * tiled_map.tile_height) / 2.0 - 8,
	}
}

arena_pick_spawn_point :: proc() -> k2.Vec2 {
	if len(spawn_points) == 0 {
		return arena_center()
	}

	idx := clamp(int(rand.float32_range(0, f32(len(spawn_points)))), 0, len(spawn_points) - 1)
	return spawn_points[idx]
}

arena_spawn_wave :: proc(tier: Tier) {
	if len(tier.enemies) == 0 do return

	remaining := make([dynamic]int, context.temp_allocator)
	total_remaining := 0

	for enemy in tier.enemies {
		count := max(enemy.count, 0)
		append(&remaining, count)
		total_remaining += count
	}

	for total_remaining > 0 {
		pick := clamp(int(rand.float32_range(0, f32(total_remaining))), 0, total_remaining - 1)

		chosen_index := -1
		running := 0
		for i in 0 ..< len(remaining) {
			if remaining[i] <= 0 do continue
			running += remaining[i]
			if pick < running {
				chosen_index = i
				break
			}
		}

		if chosen_index < 0 do break

		spawn := arena_pick_spawn_point()
		add_npc_from_prefabs(spawn.x, spawn.y, tier.enemies[chosen_index].prefab, {})
		remaining[chosen_index] -= 1
		total_remaining -= 1
	}
}

arena_apply_tier_rewards :: proc(tier: Tier) {
	purse += tier.gold

	center := arena_center()
	for reward in tier.rewards {
		if reward.chance <= 0 do continue
		if rand.float32_range(0, 1) <= reward.chance {
			add_item_from_prefabs(center.x, center.y, reward.prefab)
		}
	}
}

arena_hostile_enemy_count :: proc() -> int {
	count := 0
	it := hm.iterator_make(&npcEntities)
	for npc, _ in hm.iterate(&it) {
		if npc.disposition != .Hostile do continue
		if .SPAWNER in npc.specials do continue
		count += 1
	}
	return count
}

@(private = "file")
control_view :: proc() -> bool {
	if len(current_tiers) == 0 {
		return true
	}

	frame_dt := k2.get_frame_time()

	spawn_timer -= frame_dt
	if spawn_timer <= 0 {
		arena_spawn_wave(current_tiers[current_tier])
		spawn_timer += tier_spawn_cooldown(current_tiers[current_tier])
	}

	current_tier_duration_timer -= time.Duration(frame_dt * f32(time.Second))

	if current_tier_duration_timer <= 0 && current_tier + 1 < len(current_tiers) {
		arena_apply_tier_rewards(current_tiers[current_tier])
		current_tier += 1
		current_tier_duration_timer = current_tiers[current_tier].timer
		spawn_timer = 0
	}

	return true
}

@(private = "file")
render_view :: proc() {
	k2.update_audio_stream(game_music)

	ui_width := k2.get_screen_size().x / 2
	next_wave_seconds := max(spawn_timer, 0)
	tier_seconds_remaining := max(f32(current_tier_duration_timer / time.Second), 0)
	enemies_remaining := arena_hostile_enemy_count()

	k2.draw_text(fmt.tprintf("Gold: %d", purse), {8, 24}, UI_TEXT_SIZE, TITLE_COLOR)
	k2.draw_text(
		fmt.tprintf("Tier %d/%d", current_tier + 1, len(current_tiers)),
		{ui_width - 220, 24},
		UI_TEXT_SIZE,
		TITLE_COLOR,
	)
	k2.draw_text(
		fmt.tprintf("Next Wave: %.1fs", next_wave_seconds),
		{ui_width - 220, 48},
		UI_TEXT_SIZE,
		TEXT_COLOR,
	)
	k2.draw_text(
		fmt.tprintf("Tier Time: %.0fs", tier_seconds_remaining),
		{ui_width - 220, 72},
		UI_TEXT_SIZE,
		TEXT_COLOR,
	)
	k2.draw_text(
		fmt.tprintf("Enemies: %d", enemies_remaining),
		{ui_width - 220, 96},
		UI_TEXT_SIZE,
		TEXT_COLOR,
	)
}

@(private = "file")
close_view :: proc() {
	k2.destroy_audio_stream(game_music)
}
