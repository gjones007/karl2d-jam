package karl2d_game

import k2 "../../karl2d"
import "../tiled"
import hm "core:/container/handle_map"
import "core:math"
import "core:math/ease"
import "core:time"

import "core:fmt"

player: Player

Player :: struct {
	x, y:                  f32,
	facing:                Facing,
	anim_frame:            int,
	anim_timer:            f32,
	weapon_prefab:         ItemPrefab,
	attacking:             bool,
	attack_rotation:       f32,
	hit_cooldown_timer:    f32,
	swing_timer:           time.Duration,
	attack_swing_duration: time.Duration,
	flux_map:              ease.Flux_Map(f32),
	hp:                    i32,
	inventory:             Inventory_Handle,
}

Facing :: enum {
	Up,
	Down,
	Left,
	Right,
}

WalkingAnimation := [Facing][4]i32 {
	.Up    = {5142, 5143, 5144, 5145},
	.Down  = {4839, 4840, 4841, 4842},
	.Left  = {4940, 4941, 4942, 4943},
	.Right = {5041, 5042, 5043, 5044},
}

Player_Speed: f32 : 85
Player_Frame_Duration: f32 : 0.12
Player_Bounds_Width: f32 : 16
Player_Bounds_Height: f32 : 16
PLAYER_SWING_DURATION: time.Duration : 200 * time.Millisecond
SWING_EASING_TYPE: ease.Ease : .Quartic_In
PLAYER_HIT_COOLDOWN: f32 : 1.2
PLAYER_MAX_HP: i32 : 100
Player_Swing_Arc: f32 : math.PI / 3

player_init :: proc(level_spawn: k2.Vec2 = {0, 0}) {
	player.x = level_spawn.x
	player.y = level_spawn.y
	player.facing = .Down
	player.anim_frame = 0
	player.anim_timer = 0
	player.hp = 100
	player.inventory = {0, 0}
	player.swing_timer = 0
	player.attack_rotation = 0
	player.attack_swing_duration = PLAYER_SWING_DURATION
	player.inventory = add_inventory()
	add_inventory_item(player.inventory, .SILVER_SWORD)
	// add_inventory_item(player.inventory, .BLACK_SWORD)
	// add_inventory_item(player.inventory, .GOLD_SWORD)
	// add_inventory_item(player.inventory, .PURPLE_SWORD)
	// add_inventory_item(player.inventory, .CUTLASS)
	// add_inventory_item(player.inventory, .CUTLASS2)
	// add_inventory_item(player.inventory, .AXE)
	// add_inventory_item(player.inventory, .BATTLEAXE)
	player.weapon_prefab = .SILVER_SWORD
	player.flux_map = ease.flux_init(f32)
	player.hit_cooldown_timer = 0
}

take_damage_player :: proc(damage: int) {
	if player.hit_cooldown_timer > 0 do return

	player.hp -= auto_cast damage
	player.hit_cooldown_timer = PLAYER_HIT_COOLDOWN
	debugf("Player: Took %d damage, hp is now %d", damage, player.hp)
	if player.hp <= 0 {
		debugf("Player: HP is 0 or less, player has died")
		init_message_prompt(
			proc() {new_game(selected_map)},
			"You Died",
			"You have succumbed to your injuries. Better luck next time!",
			"Respawn",
			// "Main Menu",
		)
	}
}

player_attempt_floor_pickup :: proc() {
	debugf("Player: Attempting to pick up item at location (x: %v, y: %v)", player.x, player.y)
	if item_handle, ok := get_item_at_location(player.x, player.y).?; ok {
		item := hm.get(&itemEntities, item_handle)
		if remove_item(item_handle) {
			debugf("Player: Successfully removed item at location (x: %v, y: %v)", item.x, item.y)
		} else {
			warnf("Player: Failed to remove item at location (x: %v, y: %v)", item.x, item.y)
		}

		if item.prefab == .RED_POTION {
			heal_amount := itemPrefab[item.prefab].damage
			player.hp = min(player.hp + auto_cast heal_amount, PLAYER_MAX_HP)
			debugf("Player: Used Red Potion for %d healing, hp is now %d", heal_amount, player.hp)
		} else {
			add_inventory_item(player.inventory, item.prefab)
		}
	}
}

player_attempt_npc_conversation :: proc() {
	it := hm.iterator_make(&npcEntities)
	for npc, npc_handle in hm.iterate(&it) {
		npc_rect := k2.Rect{npc.x, npc.y, 16, 16}
		player_rect := k2.Rect{player.x, player.y, 16, 16}
		if _, does := k2.rect_overlap(npc_rect, player_rect); does {
			debugf("Player: Attempting to interact with NPC (handle: %v)", npc_handle)
			if hm.is_valid(&conversationEntities, npc.conversation_handle) {
				debugf("Player: Starting conversation with NPC (handle: %v)", npc_handle)
				handle_conversation(npc)
			} else {
				debugf(
					"Player: NPC (handle: %v) has no conversation handle, cannot start conversation",
					npc_handle,
				)
			}
		}
	}
}

movement_collision_check :: proc(
	x, y: f32,
	collision_layers: []tiled.Layer,
	map_width, map_height, tile_width, tile_height: i32,
) -> bool {
	map_px_width := f32(map_width * tile_width)
	map_px_height := f32(map_height * tile_height)
	right := x + Player_Bounds_Width - 1
	bottom := y + Player_Bounds_Height - 1

	if x < 0 || y < 0 || right >= map_px_width || bottom >= map_px_height {
		return true
	}

	tile_wf := f32(tile_width)
	tile_hf := f32(tile_height)
	left_tx := i32(x / tile_wf)
	right_tx := i32(right / tile_wf)
	top_ty := i32(y / tile_hf)
	bottom_ty := i32(bottom / tile_hf)

	for layer in collision_layers {
		if layer.type != .tilelayer || len(layer.data) == 0 do continue

		check_left := max(left_tx, 0)
		check_right := min(right_tx, layer.width - 1)
		check_top := max(top_ty, 0)
		check_bottom := min(bottom_ty, layer.height - 1)

		for ty in check_top ..= check_bottom {
			for tx in check_left ..= check_right {
				idx := ty * layer.width + tx
				if layer.data[idx] != 0 {
					return true
				}
			}
		}
	}

	return false
}

update_player_controls :: proc(
	p: ^Player,
	dt: f32,
	collision_layers: []tiled.Layer,
	map_width, map_height, tile_width, tile_height: i32,
) {
	if is_input_active(.INPUT_UI_TOGGLE_INVENTORY) do open_inventory_view()
	if is_input_active(.INPUT_UI_TOGGLE_MAINMENU) do init_main_menu()

	if player.hit_cooldown_timer > 0 {
		player.hit_cooldown_timer -= dt
		if player.hit_cooldown_timer < 0 {
			player.hit_cooldown_timer = 0
		}
	}
	if p.attacking {
		// Keep movement enabled while swing easing is active.
		ease.flux_update(&p.flux_map, f64(dt))
		if len(p.flux_map.values) == 0 {
			p.attacking = false
			p.attack_rotation = 0
			p.swing_timer = 0
		}
	}

	// if is_input_active(.INPUT_UI_TOGGLE_INVENTORY) {
	// 	open_inventory_view()
	// 	return
	// }

	if is_input_active(.INPUT_GAME_FLOOR_PICK_UP) {
		warnf("Player: INPUT_GAME_FLOOR_PICK_UP is active, attempting pickup")
		player_attempt_floor_pickup()
		play_sound(.ItemPickup)

		// TODO: GOING TO PIGGYBACK ON THIS FOR NOW
		player_attempt_npc_conversation()
		return
	}

	if is_input_active(.INPUT_GAME_ATTACK) && !p.attacking {
		play_sound(.PlayerAttack)
		p.attacking = true
		p.swing_timer = 0
		player_init_swing_easing()
	}

	move_x: f32 = 0
	move_y: f32 = 0

	if is_input_active(.INPUT_GAME_WALK_WEST) do move_x -= input_strength(.INPUT_GAME_WALK_WEST)
	if is_input_active(.INPUT_GAME_WALK_EAST) do move_x += input_strength(.INPUT_GAME_WALK_EAST)
	if is_input_active(.INPUT_GAME_WALK_NORTH) do move_y -= input_strength(.INPUT_GAME_WALK_NORTH)
	if is_input_active(.INPUT_GAME_WALK_SOUTH) do move_y += input_strength(.INPUT_GAME_WALK_SOUTH)

	move_len := math.sqrt(move_x * move_x + move_y * move_y)
	if move_len > 1 {
		move_x /= move_len
		move_y /= move_len
	}

	moving := false

	if move_x < 0 &&
	   !movement_collision_check(
			   p.x + move_x * Player_Speed * dt,
			   p.y,
			   collision_layers,
			   map_width,
			   map_height,
			   tile_width,
			   tile_height,
		   ) {
		p.x += move_x * Player_Speed * dt
		moving = true
	}
	if move_x > 0 &&
	   !movement_collision_check(
			   p.x + move_x * Player_Speed * dt,
			   p.y,
			   collision_layers,
			   map_width,
			   map_height,
			   tile_width,
			   tile_height,
		   ) {
		p.x += move_x * Player_Speed * dt
		moving = true
	}
	if move_y < 0 &&
	   !movement_collision_check(
			   p.x,
			   p.y + move_y * Player_Speed * dt,
			   collision_layers,
			   map_width,
			   map_height,
			   tile_width,
			   tile_height,
		   ) {
		p.y += move_y * Player_Speed * dt
		moving = true
	}
	if move_y > 0 &&
	   !movement_collision_check(
			   p.x,
			   p.y + move_y * Player_Speed * dt,
			   collision_layers,
			   map_width,
			   map_height,
			   tile_width,
			   tile_height,
		   ) {
		p.y += move_y * Player_Speed * dt
		moving = true
	}

	if moving {
		if math.abs(move_x) >= math.abs(move_y) {
			p.facing = .Left if move_x < 0 else .Right
		} else {
			p.facing = .Up if move_y < 0 else .Down
		}
	}

	if moving {
		p.anim_timer += dt
		if p.anim_timer >= Player_Frame_Duration {
			p.anim_timer -= Player_Frame_Duration
			p.anim_frame = (p.anim_frame + 1) % 4
			// play_sound(.PlayerWalk)
		}
	} else {
		p.anim_frame = 0
		p.anim_timer = 0
	}
}

player_init_swing_easing :: proc() {
	// setup easing for attack swing
	ease.flux_clear(&player.flux_map)
	player.attack_rotation = -Player_Swing_Arc
	_ = ease.flux_to(
		&player.flux_map,
		&player.attack_rotation,
		Player_Swing_Arc,
		SWING_EASING_TYPE,
		player.attack_swing_duration,
	)
}

push_view_player_inventory :: proc(p: ^Player) {
}

draw_player :: proc(tileset: tiled.Tileset, texture: k2.Texture, p: Player) {
	tile_id := WalkingAnimation[p.facing][p.anim_frame]
	tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
	tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
	source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}
	k2.draw_texture_rect(
		texture,
		source,
		{p.x, p.y},
		tint = p.hit_cooldown_timer > 0 ? k2.color_alpha(k2.RED, u8(math.cos(p.hit_cooldown_timer * math.PI * 2) * 255)) : k2.WHITE,
	)

	// Draw weapon in front of the player and rotate around the side nearest the player.
	if p.attacking {
		attack_tile_id := itemPrefab[p.weapon_prefab].tile_id
		weapon_tileset_x := f32(
			(attack_tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing),
		)
		weapon_tileset_y := f32(
			(attack_tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing),
		)
		weapon_source: k2.Rect = {
			weapon_tileset_x,
			weapon_tileset_y,
			f32(tileset.tile_width),
			f32(tileset.tile_height),
		}

		dest := k2.Rect{p.x, p.y, f32(tileset.tile_width), f32(tileset.tile_height)}
		origin := k2.Vec2{8, 8}
		base_rotation: f32 = 0
		swing_direction: f32 = 1

		switch p.facing {
		case .Up:
			dest.y -= 4
			dest.x += 8
			origin = {8, 14}
			base_rotation = 0
			swing_direction = -1
		case .Down:
			dest.y += 16
			dest.x += 4
			origin = {2, 8}
			base_rotation = math.PI * 0.5
			swing_direction = 1
		case .Left:
			dest.y += 8
			// origin = {14, 8}
			origin = {8, 14}
			base_rotation = math.PI * 1.5
			swing_direction = -1
		case .Right:
			dest.x += 16
			dest.y += 8
			origin = {2, 8}
			base_rotation = 0
			swing_direction = 1
		}

		weapon_source.w *= itemPrefab[p.weapon_prefab].flip_horizontal ? -1 : 1

		k2.draw_texture_fit(
			texture,
			weapon_source,
			dest,
			origin,
			base_rotation + p.attack_rotation * swing_direction,
		)
	}
}

draw_player_ui :: proc(tileset: tiled.Tileset, texture: k2.Texture, p: Player) {
	k2.draw_rect_outline({4, 4, 68, 12}, 2, k2.RED)
	k2.draw_rect({6, 6, f32(p.hp) * 0.64, 8}, k2.RED)
}
