package karl2d_game

import k2 "../../karl2d"
import "../tiled"
import hm "core:/container/handle_map"
// import json "core:encoding/json"
import "core:math"
// import "core:os"
import "core:reflect"
import "core:strings"

GAME_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

@(private = "file")
dt: f32
@(private = "file")
game_camera: k2.Camera

@(private = "file")
GameFile: struct {
	IsOpen:                  bool,
	title:                   string,
	options:                 [dynamic]string,
	selected:                int,
	attackResolvedThisSwing: bool,
	hasExitPoint:            bool,
	exitTriggered:           bool,
	exitBlockedShown:        bool,
	exitPoint:               k2.Vec2,
} = {}

ATTACK_DAMAGE :: 25
dumb_lighting := false

resolve_player_exit :: proc() {
	if !GameFile.hasExitPoint || GameFile.exitTriggered {
		return
	}

	exit_rect := k2.Rect{GameFile.exitPoint.x - 8, GameFile.exitPoint.y - 8, TILE_SIZE, TILE_SIZE}
	player_rect := k2.Rect{player.x, player.y, TILE_SIZE, TILE_SIZE}

	if _, does := k2.rect_overlap(player_rect, exit_rect); does {
		if !has_inventory_item(player.inventory, .RUBY_RING) {
			if !GameFile.exitBlockedShown {
				GameFile.exitBlockedShown = true
				init_message_prompt(
					nil,
					"The Exit Is Sealed",
					"Guilt prevents you from leaving. You need the Ruby Ring to leave, Karak paid you for its retrieval.",
					"Ok",
				)
			}
			return
		}

		GameFile.exitTriggered = true
		init_message_prompt(
			proc() {set_view(&TITLE_GRAPHIC_VIEW)},
			"You Escaped!",
			"With the Ruby Ring in hand, you found the exit and made it out alive. Karak will be pleased, and you can finally rest easy knowing you won't have to go back down there again.",
			"Main Menu",
		)
	} else {
		GameFile.exitBlockedShown = false
	}
}

get_player_attack_rect :: proc(p: Player) -> k2.Rect {
	r := k2.Rect{p.x, p.y, TILE_SIZE, TILE_SIZE}
	switch p.facing {
	case .Up:
		r.y -= TILE_SIZE
	case .Down:
		r.y += TILE_SIZE
	case .Left:
		r.x -= TILE_SIZE
	case .Right:
		r.x += TILE_SIZE
	}
	return r
}

resolve_player_attack_hits :: proc() {
	if !player.attacking {
		GameFile.attackResolvedThisSwing = false
		return
	}

	if GameFile.attackResolvedThisSwing do return

	attack_rect := get_player_attack_rect(player)
	hit_handles := make([dynamic]NPC_Handle, context.temp_allocator)

	it := hm.iterator_make(&npcEntities)
	for npc, npc_handle in hm.iterate(&it) {
		npc_rect := k2.Rect{npc.x, npc.y, TILE_SIZE, TILE_SIZE}
		if _, does := k2.rect_overlap(attack_rect, npc_rect); does {
			if npc.disposition == .Friendly {
				debugf("Player attack hit friendly NPC (handle: %v), ignoring", npc_handle)
				continue
			}
			append(&hit_handles, npc_handle)
		}
	}

	for h in hit_handles {
		take_damage_npc(h, ATTACK_DAMAGE)
	}

	if len(hit_handles) > 0 {
		GameFile.attackResolvedThisSwing = true
	}
}

@(private = "file")
open_view :: proc() {
	GameFile.hasExitPoint = false
	GameFile.exitTriggered = false
	GameFile.exitBlockedShown = false
	GameFile.exitPoint = {0, 0}

	level_allocator = context.allocator
	tiled_map, tileset_textures = load_map(level_allocator)
	init_npc_prefabs()
	init_items_prefabs()

	level_spawn := k2.Vec2{0, 0}
	for layer in tiled_map.layers {
		if layer.type == .tilelayer do continue
		for object in layer.objects {
			if object.name == "PLAYER_SPAWN" {
				level_spawn.x = auto_cast object.x
				level_spawn.y = auto_cast object.y
			}
			if object.name == "GUIDE_SPAWN" {
				if handle, ok := add_npc_from_prefabs(
					   auto_cast object.x,
					   auto_cast object.y,
					   .DWARF_MINER,
					   {},
				   ).?; ok {
					conversation_handle: Conversation_Handle
					conversation_line := 0
					for property in tiled_map.properties {
						if strings.starts_with(property.name, "guide_") {
							if !hm.is_valid(&conversationEntities, conversation_handle) {
								conversation_handle = add_conversation("Karak")
							}

							if property_value, is_string := property.value.(string); is_string {
								add_conversation_dialogue(
									conversation_handle,
									conversation_line,
									property_value,
								)
								conversation_line += 1
							}
						}
					}

					if hm.is_valid(&conversationEntities, conversation_handle) {
						npc := hm.get(&npcEntities, handle)
						npc.conversation_handle = conversation_handle
					}
				}
			}
			if object.name == "EXIT" {
				GameFile.hasExitPoint = true
				GameFile.exitPoint = {auto_cast object.x, auto_cast object.y}
			}

			loop: {
				s := strings.split(object.name, ".", allocator = context.temp_allocator)
				debugf("Split object name into %v parts", len(s))
				switch s[0] {
				case "N":
					debugf("Checking NPC prefab against object name %v", s[1])
					for npc in NPCPrefab {
						debugf("Checking NPC prefab %v against object name %v", npc, s[1])
						flags := NPCSpecials{}
						if reflect.enum_string(npc) == s[1] {
							for flag in s[2:] {
								for specials in SpecialFlags {
									if reflect.enum_string(specials) == flag {
										flags += {specials}
									}
								}
							}
							debugf(
								"Spawning NPC from prefab %v at (%v, %v)",
								npc,
								object.x,
								object.y,
								flags,
							)
							add_npc_from_prefabs(
								auto_cast object.x,
								auto_cast object.y,
								npc,
								flags,
							)
							break loop
						}
					}

				case "I":
					for item in ItemPrefab {
						debugf("Checking Item prefab %v against object name %v", item, s[1])
						if reflect.enum_string(item) == s[1] {
							debugf(
								"Spawning Item from prefab %v at (%v, %v)",
								item,
								object.x,
								object.y,
							)
							add_item_from_prefabs(auto_cast object.x, auto_cast object.y, item)
							break loop
						}
					}
				}
			}
		}
	}

	player_init(level_spawn)

	game_camera = k2.Camera {
		offset = k2.get_screen_size() / 2,
		zoom   = 3,
	}
}

// SAVEGAME :: "savegame.json"

// save_game :: proc() {
// 	save_data := struct {
// 		player: Player,
// 	} {
// 		player = player,
// 	}

// 	if bytes, marshal_err := json.marshal(save_data, opt = {pretty = true}); marshal_err != nil {
// 		debugf(marshal_err)
// 	} else {
// 		if err := os.write_entire_file("savegame.json", bytes); err != nil {
// 			debugf("Error saving game: %v", err)
// 		} else {
// 			debugf("Game saved successfully")
// 		}
// 	}
// }

load_game :: proc() {
	// json_str, err := k2.load_file("savegame.json", context.temp_allocator)
	// if err != nil {
	// 	debugf("Error loading game: %v", err)
	// 	return
	// }

	// save_data := struct {
	// 	player: Player,
	// }{}

	// err = json.unmarshal(json_str, &save_data)
	// if err != nil {
	// 	debugf("Error unmarshaling save data: %v", err)
	// 	return
	// }

	// player = save_data.player
	// debugf("Game loaded successfully")
}

@(private = "file")
control_view :: proc() -> bool {
	when ODIN_OS != .JS {
		if k2.key_went_down(.F1) {
			if !is_view_open(&GAME_CONTROL_VIEW) {
				push_view(&GAME_CONTROL_VIEW)
			} else {
				pop_view()
			}
		}
	}
	// if k2.key_went_down(.S) && k2.key_is_held(.Left_Control) {
	// 	save_game()
	// }
	// if k2.key_went_down(.L) && k2.key_is_held([.Left_Control]) {
	// 	load_game()		
	// }

	npc_actions(
		dt,
		{tiled_map.layers[int(Layers.Walls)]},
		tiled_map.width,
		tiled_map.height,
		tiled_map.tile_width,
		tiled_map.tile_height,
	)
	if player.hp <= 0 {
		return true
	}
	update_player_controls(
		&player,
		dt,
		{tiled_map.layers[int(Layers.Walls)]},
		tiled_map.width,
		tiled_map.height,
		tiled_map.tile_width,
		tiled_map.tile_height,
	)
	resolve_player_attack_hits()
	resolve_player_exit()
	return false
}

draw_tile_layers :: proc(camera: k2.Camera) {
	top_left := k2.screen_to_world(k2.Vec2{}, camera)
	bottom_right := k2.screen_to_world(k2.get_screen_size(), camera)

	for layer in tiled_map.layers {
		if layer.type != .tilelayer do continue
		tileset := &tiled_map.tilesets[0]

		for y in int(
			top_left.y / f32(tileset.tile_height),
		) ..< int(bottom_right.y / f32(tileset.tile_height)) + 1 {
			for x in int(
				top_left.x / f32(tileset.tile_width),
			) ..< int(bottom_right.x / f32(tileset.tile_width)) + 1 {

				if y < 0 || y >= int(tiled_map.height) || x < 0 || x >= int(tiled_map.width) do continue

				ggid := layer.data[y * int(tiled_map.width) + x]
				gid, flags := tiled.strip_flags(ggid)
				// if tileset.columns <= 0 || tileset.tile_width <= 0 || tileset.tile_height <= 0 do continue

				i := y * int(tiled_map.width) + x

				tile_id := gid - tileset.first_gid
				world_x := f32((i32(i) % tiled_map.width) * tileset.tile_width)
				world_y := f32((i32(i) / tiled_map.width) * tileset.tile_height)
				tileset_x := f32(
					(tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing),
				)
				tileset_y := f32(
					(tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing),
				)
				source: k2.Rect = {
					tileset_x,
					tileset_y,
					f32(tileset.tile_width),
					f32(tileset.tile_height),
				}

				if .flip_horizontal in flags do source.w *= -1
				if .flip_vertical in flags do source.h *= -1
				k2.draw_texture_rect(tileset_textures[0], source, {world_x, world_y})
			}
		}
	}
}

draw_items :: proc(camera: k2.Camera) {
	top_left := k2.screen_to_world(k2.Vec2{}, camera)
	bottom_right := k2.screen_to_world(k2.get_screen_size(), camera)

	it := hm.iterator_make(&itemEntities)
	for item, _ in hm.iterate(&it) {
		if item.x + TILE_SIZE < top_left.x || item.x > bottom_right.x || item.y + TILE_SIZE < top_left.y || item.y > bottom_right.y do continue

		tileset := tiled_map.tilesets[0]
		texture := tileset_textures[0]
		tile_id := itemPrefab[item.prefab].tile_id - tileset.first_gid
		tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
		tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
		source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}
		k2.draw_texture_rect(texture, source, {item.x, item.y})

		if distance(player.x + 8, player.y + 8, item.x + 8, item.y + 8) < 24 {
			tile_id = SEE_ICON - tileset.first_gid
			tileset_x = f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
			tileset_y = f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
			source = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}

			alpha := cast(u8)math.remap_clamped(
				distance(player.x + 8, player.y + 8, item.x + 8, item.y + 8),
				0,
				50,
				0,
				255,
			)
			k2.draw_texture_fit(
				texture,
				source,
				{item.x, item.y, 8, 8},
				{-8, 8},
				tint = k2.color_alpha(k2.WHITE, 255 - alpha),
			)
		}
	}
}

draw_npcs :: proc(camera: k2.Camera) {
	top_left := k2.screen_to_world(k2.Vec2{}, camera)
	bottom_right := k2.screen_to_world(k2.get_screen_size(), camera)

	it := hm.iterator_make(&npcEntities)
	for npc, _ in hm.iterate(&it) {
		if npc.x + TILE_SIZE < top_left.x || npc.x > bottom_right.x || npc.y + TILE_SIZE < top_left.y || npc.y > bottom_right.y do continue

		tileset := tiled_map.tilesets[0]
		texture := tileset_textures[0]
		tile_id := npc.tile_id - tileset.first_gid
		tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
		tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
		source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}

		tint := k2.WHITE
		if npc.hit_cooldown_timer > 0 {
			alpha: u8
			if .SPAWNER in npc.specials {
				alpha = cast(u8)math.remap_clamped(npc.hit_cooldown_timer, 0.0, 1.0, 0.0, 255.0)
			} else {
				alpha = cast(u8)math.remap_clamped(
					npc.hit_cooldown_timer,
					0.0,
					PLAYER_HIT_COOLDOWN,
					0.0,
					255.0,
				)
			}
			tint = k2.color_alpha(k2.RED, alpha)
		}

		k2.draw_texture_rect(texture, source, {npc.x, npc.y}, tint = tint)

		if npc.disposition == .Friendly &&
		   hm.is_valid(&conversationEntities, npc.conversation_handle) {
			{
				tile_id = TALK_ICON - tileset.first_gid
				tileset_x = f32(
					(tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing),
				)
				tileset_y = f32(
					(tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing),
				)
				source = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}

				alpha := cast(u8)math.remap_clamped(
					distance(player.x + 8, player.y + 8, npc.x + 8, npc.y + 8),
					0,
					50,
					0,
					255,
				)
				k2.draw_texture_fit(
					texture,
					source,
					{npc.x, npc.y, 8, 8},
					{-8, 8},
					tint = k2.color_alpha(k2.YELLOW, 255 - alpha),
				)
			}
		}
	}
}

@(private = "file")
render_view :: proc() {
	dt = k2.get_frame_time()

	// camera.target is the center of the camera in world coordinates
	game_camera.target.x = player.x + 8
	game_camera.target.y = player.y + 8
	game_camera.offset = k2.get_screen_size() / 2

	k2.set_camera(game_camera)

	draw_tile_layers(game_camera)
	draw_items(game_camera)
	draw_npcs(game_camera)
	draw_player(tiled_map.tilesets[0], tileset_textures[0], player)
	k2.set_camera(ui_camera)
	draw_player_ui(tiled_map.tilesets[0], tileset_textures[0], player)
}

@(private = "file")
close_view :: proc() {
	flush_all_inventories()
	flush_all_npcs()
	flush_all_conversations()
	flush_all_items()
	unload_map(level_allocator, tileset_textures)
}

// manhattan distance, copied from another project... might change this
distance :: proc(start_x, start_y, end_x, end_y: f32) -> f32 {
	dx := f32(math.max(start_x, end_x) - math.min(start_x, end_x))
	dy := f32(math.max(start_y, end_y) - math.min(start_y, end_y))
	return math.sqrt((dx * dx) + (dy * dy))
}
