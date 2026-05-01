package karl2d_game

import "../tiled"
import k2 "../../karl2d"
import "core:math"

player : Player

Player :: struct {
	x, y: f32,
    facing: Facing,
    anim_frame: int,
    anim_timer: f32,
}

Facing :: enum {
    Up,
    Down,
    Left,
    Right,
}

WalkingAnimation := [Facing][4]i32 {
    .Up = {5142, 5143, 5144, 5145},
    .Down = {4839, 4840, 4841, 4842},
    .Left = {4940, 4941, 4942, 4943},
    .Right = {5041, 5042, 5043, 5044},
}

Player_Speed: f32 : 100
Gamepad_Deadzone: f32 : 0.2
Player_Frame_Duration: f32 : 0.12
Player_Bounds_Width: f32 : 16
Player_Bounds_Height: f32 : 16

player_init :: proc() {
    player.x = 16 * 4
    player.y = 16 * 4
    player.facing = .Down
    player.anim_frame = 0
    player.anim_timer = 0
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
    move_x: f32 = 0
    move_y: f32 = 0

    if k2.key_is_held(.A) do move_x -= 1
    if k2.key_is_held(.D) do move_x += 1
    if k2.key_is_held(.W) do move_y -= 1
    if k2.key_is_held(.S) do move_y += 1

    if k2.is_gamepad_active(0) {
        stick_x := k2.get_gamepad_axis(0, .Left_Stick_X)
        stick_y := k2.get_gamepad_axis(0, .Left_Stick_Y)

        if math.abs(stick_x) >= Gamepad_Deadzone do move_x += stick_x
        if math.abs(stick_y) >= Gamepad_Deadzone do move_y += stick_y
    }

    move_len := math.sqrt(move_x * move_x + move_y * move_y)
    if move_len > 1 {
        move_x /= move_len
        move_y /= move_len
    }

    moving := false

    if move_x < 0 && !player_collision_check(p.x + move_x * Player_Speed * dt, p.y, collision_layers, map_width, map_height, tile_width, tile_height) {
        p.x += move_x * Player_Speed * dt
        moving = true
    }
    if move_x > 0 && !player_collision_check(p.x + move_x * Player_Speed * dt, p.y, collision_layers, map_width, map_height, tile_width, tile_height) {
        p.x += move_x * Player_Speed * dt
        moving = true
    }
    if move_y < 0 && !player_collision_check(p.x, p.y + move_y * Player_Speed * dt, collision_layers, map_width, map_height, tile_width, tile_height) {
        p.y += move_y * Player_Speed * dt
        moving = true
    }
    if move_y > 0 && !player_collision_check(p.x, p.y + move_y * Player_Speed * dt, collision_layers, map_width, map_height, tile_width, tile_height) {
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

draw_player :: proc(tileset: tiled.Tileset, texture: k2.Texture, p: Player) {
    tile_id := WalkingAnimation[p.facing][p.anim_frame]
    tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
    tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
    source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}
    // k2.DrawTextureRec(texture, source, {p.x, p.y}, k2.WHITE)
    k2.draw_texture_rect(texture, source, {p.x, p.y})
}
