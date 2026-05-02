package karl2d_game

import k2 "../../karl2d"
import "../tiled"
import hm "core:/container/handle_map"
import "core:math"

player: Player

Player :: struct {
	x, y:           f32,
	facing:         Facing,
	anim_frame:     int,
	anim_timer:     f32,
	weapon_tile_id: i32,
	attacking:      bool,
	attack_timer:   f32,
	attack_frame:   int,
	hp:             i32,
	inventory:      Inventory_Handle,
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

Player_Speed: f32 : 100
Player_Frame_Duration: f32 : 0.12
Player_Bounds_Width: f32 : 16
Player_Bounds_Height: f32 : 16

player_init :: proc() {
	player.x = 16 * 4
	player.y = 16 * 4
	player.facing = .Down
	player.anim_frame = 0
	player.anim_timer = 0
	player.hp = 100
	player.inventory = {0, 0}
	player.attack_timer = 0
	player.attack_frame = 0
	player.weapon_tile_id = SWORD_GOLD
	player.inventory = add_inventory()
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
		add_inventory_item(player.inventory, item.prefab)
	}
}

player_attempt_npc_interact :: proc() {
	it := hm.iterator_make(&npcEntities)
	for npc, npc_handle in hm.iterate(&it) {
		npc_rect := k2.Rect{npc.x, npc.y, 16, 16}
		player_rect := k2.Rect{player.x, player.y, 16, 16}
		if _, does := k2.rect_overlap(npc_rect, player_rect); does {
			debugf("Player: Attempting to interact with NPC (handle: %v)", npc_handle)
			if npc.disposition == .Friendly {

				init_bool_prompt(
					proc() {
						add_inventory_item(player.inventory, .WORN_PICKAXE)
						// debugf("Player: Accepted interaction with NPC (handle: %v)", npc_handle)
						// init_message_prompt(nil, "npc.name", "npc.description")
						// return true
					},
					proc() {
						// debugf("Player: Declined interaction with NPC (handle: %v)", npc_handle)
						// return true
					},
					"Converse",
					"Message Text",
					"Talk",
					"Leave",
				)

				// init_message_view(npc.name, npc.description)
			} else {
				debugf(
					"Player: NPC (handle: %v) is not friendly, skipping interaction",
					npc_handle,
				)
			}
		}
	}
}

player_collision_check :: proc(
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
	if p.attacking {
		p.attack_timer += dt
		if p.attack_timer >= Player_Frame_Duration {
			p.attack_timer -= Player_Frame_Duration
			p.attack_frame += 1
			if p.attack_frame >= 4 {
				p.attack_frame = 0
				p.attacking = false
			}
		}
		return
	}

	// if is_input_active(.INPUT_UI_TOGGLE_INVENTORY) do init_main_menu()
	if is_input_active(.INPUT_GAME_FLOOR_PICK_UP) {
		warnf("Player: INPUT_GAME_FLOOR_PICK_UP is active, attempting pickup")
		player_attempt_floor_pickup()
		play_sound(.ItemPickup)

		// TODO: GOING TO PIGGYBACK ON THIS FOR NOW
		player_attempt_npc_interact()
		return
	}


	if is_input_active(.INPUT_GAME_ATTACK) {
		play_sound(.PlayerAttack)
		p.attacking = true
		p.attack_timer = 0
		p.attack_frame = 0
		return
	}

	move_x: f32 = 0
	move_y: f32 = 0

	if is_input_active(.INPUT_GAME_WALK_WEST) do move_x -= input_strength(.INPUT_GAME_WALK_WEST)
	if is_input_active(.INPUT_GAME_WALK_EAST) do move_x += input_strength(.INPUT_GAME_WALK_EAST)
	if is_input_active(.INPUT_GAME_WALK_NORTH) do move_y -= input_strength(.INPUT_GAME_WALK_NORTH)
	if is_input_active(.INPUT_GAME_WALK_SOUTH) do move_y += input_strength(.INPUT_GAME_WALK_SOUTH)

	if is_input_active(.INPUT_UI_TOGGLE_INVENTORY) do init_main_menu()

	move_len := math.sqrt(move_x * move_x + move_y * move_y)
	if move_len > 1 {
		move_x /= move_len
		move_y /= move_len
	}

	moving := false

	if move_x < 0 &&
	   !player_collision_check(
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
	   !player_collision_check(
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
	   !player_collision_check(
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
	   !player_collision_check(
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
			play_sound(.PlayerWalk)
		}
	} else {
		p.anim_frame = 0
		p.anim_timer = 0
	}
}

push_view_player_inventory :: proc(p: ^Player) {
}

draw_player :: proc(tileset: tiled.Tileset, texture: k2.Texture, p: Player) {
	tile_id := WalkingAnimation[p.facing][p.anim_frame]
	tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
	tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
	source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}
	k2.draw_texture_rect(texture, source, {p.x, p.y})

	// draw the sword swing, but animate the tile in front of the player
	// rotate around the front
	if p.attacking {
		attack_tile_id := p.weapon_tile_id
		tileset_x := f32(
			(attack_tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing),
		)
		tileset_y := f32(
			(attack_tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing),
		)
		source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}
		dest := k2.Rect{p.x + 8, p.y + 8, f32(tileset.tile_width), f32(tileset.tile_height)}
		origin := k2.Vec2{8, 8}
		rotation: f32 = p.anim_timer / Player_Frame_Duration * math.PI * 2
		if p.facing == .Up {
			dest.y -= 16
			rotation -= math.PI / 4
		} else if p.facing == .Down {
			dest.y += 16
			rotation += math.PI / 4
		} else if p.facing == .Left {
			dest.x -= 16
			rotation -= math.PI / 4
		} else if p.facing == .Right {
			dest.x += 16
			rotation += math.PI / 4
		}
		k2.draw_texture_fit(texture, source, dest, origin, rotation)
	}
}

draw_player_ui :: proc(tileset: tiled.Tileset, texture: k2.Texture, p: Player) {
	for i in 0 ..< (p.hp + 1) / 25 {
		tile_id := RED_HEARTS[i]

		tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
		tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
		source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}

		k2.draw_texture_rect(texture, source, {8 + f32(i) * 20, 8})
	}
}
