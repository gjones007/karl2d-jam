package karl2d_game

import k2 "../../karl2d"
import "../tiled"
import "core:fmt"

gamepad_demo :: proc(gamepad: k2.Gamepad_Index, offset: k2.Vec2) {
	if !k2.is_gamepad_active(gamepad) {
		title := fmt.tprintf("Gamepad %v (not connected)", gamepad + 1)
		ts := k2.measure_text(title, 30)
		k2.draw_text(title, offset + {250, 60} - {ts.x / 2, 0}, 30, color = k2.WHITE)
		return
	}

	title := fmt.tprintf("Gamepad %v", gamepad + 1)
	ts := k2.measure_text(title, 30)
	k2.draw_text(title, offset + {250, 60} - {ts.x / 2, 0}, 30, color = k2.WHITE)

	button_color :: proc(
		gamepad: k2.Gamepad_Index,
		button: k2.Gamepad_Button,
		active := k2.WHITE,
		inactive := k2.GRAY,
	) -> k2.Color {
		return k2.gamepad_button_is_held(gamepad, button) ? active : inactive
	}

	g := gamepad
	o := offset
	k2.draw_circle(o + {120, 120}, 10, button_color(g, .Left_Face_Up))
	k2.draw_circle(o + {120, 160}, 10, button_color(g, .Left_Face_Down))
	k2.draw_circle(o + {100, 140}, 10, button_color(g, .Left_Face_Left))
	k2.draw_circle(o + {140, 140}, 10, button_color(g, .Left_Face_Right))

	k2.draw_circle(o + {320 + 50, 120}, 10, button_color(g, .Right_Face_Up))
	k2.draw_circle(o + {320 + 50, 160}, 10, button_color(g, .Right_Face_Down))
	k2.draw_circle(o + {300 + 50, 140}, 10, button_color(g, .Right_Face_Left))
	k2.draw_circle(o + {340 + 50, 140}, 10, button_color(g, .Right_Face_Right))

	k2.draw_rect_vec(o + {250 - 30, 140}, {20, 10}, button_color(g, .Middle_Face_Left))
	k2.draw_rect_vec(o + {250 + 10, 140}, {20, 10}, button_color(g, .Middle_Face_Right))

	left_stick := k2.Vec2 {
		k2.get_gamepad_axis(gamepad, .Left_Stick_X),
		k2.get_gamepad_axis(gamepad, .Left_Stick_Y),
	}

	right_stick := k2.Vec2 {
		k2.get_gamepad_axis(gamepad, .Right_Stick_X),
		k2.get_gamepad_axis(gamepad, .Right_Stick_Y),
	}

	left_trigger := k2.get_gamepad_axis(gamepad, .Left_Trigger)
	right_trigger := k2.get_gamepad_axis(gamepad, .Right_Trigger)

	k2.set_gamepad_vibration(gamepad, left_trigger, right_trigger)

	k2.draw_rect_vec(o + {80, 50}, {20, 10}, button_color(g, .Left_Shoulder))
	k2.draw_rect_vec(
		o + {50, 50} + {0, left_trigger * 20},
		{20, 10},
		button_color(g, .Left_Trigger, k2.WHITE, k2.GRAY),
	)

	k2.draw_rect_vec(o + {420, 50}, {20, 10}, button_color(g, .Right_Shoulder))
	k2.draw_rect_vec(
		o + {450, 50} + {0, right_trigger * 20},
		{20, 10},
		button_color(g, .Right_Trigger, k2.WHITE, k2.GRAY),
	)
	k2.draw_circle(
		o + {200, 200} + 20 * left_stick,
		20,
		button_color(g, .Left_Stick_Press, k2.WHITE, k2.GRAY),
	)
	k2.draw_circle(
		o + {300, 200} + 20 * right_stick,
		20,
		button_color(g, .Right_Stick_Press, k2.WHITE, k2.GRAY),
	)
}

main :: proc() {
	init()
	for step() {}
	shutdown()
}

init :: proc() {
	k2.init(1000, 636, "Karl2D Game Demo")

	level_allocator = context.allocator
	tiled_map, tileset_textures = load_map(level_allocator)
	player_init()
	sounds_init()
	camera = k2.Camera {
		zoom = 2,
	}

}

update_controls :: proc() {
    update_player_controls(
      &player,
      dt,
      { tiled_map.layers[int(Layers.Walls)] },
      tiled_map.width,
      tiled_map.height,
      tiled_map.tile_width,
      tiled_map.tile_height,
    )
}

dt: f32
camera : k2.Camera

step :: proc() -> bool {
	if !k2.update() {
		return false
	}

	update_controls()

    dt = k2.get_frame_time()
	k2.clear(k2.DARK_BLUE)

	k2.set_camera(camera)
	screen_rect := k2.rect_from_pos_size({}, k2.get_screen_size())

	for layer in tiled_map.layers {
		if layer.type != .tilelayer do continue //implement image layers and other static renderables here
		for gid, i in layer.data {
			if gid == 0 do continue

			gid, flags := tiled.strip_flags(gid)
			tileset, tileset_idx := tiled.get_tileset_from_gid(tiled_map.tilesets, gid)
			if tileset == nil do continue
			if tileset_idx < 0 || tileset_idx >= len(tileset_textures) do continue
			if tileset.columns <= 0 || tileset.tile_width <= 0 || tileset.tile_height <= 0 do continue

			tile_id := gid - tileset.first_gid
			world_x := f32((i32(i) % tiled_map.width) * tileset.tile_width)
			world_y := f32((i32(i) / tiled_map.width) * tileset.tile_height)
			tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
			tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
			source: k2.Rect = {
				tileset_x,
				tileset_y,
				f32(tileset.tile_width),
				f32(tileset.tile_height),
			}

			if .flip_horizontal in flags do source.w *= -1
			if .flip_vertical in flags do source.h *= -1

			k2.draw_texture_rect(tileset_textures[tileset_idx], source, {world_x, world_y})
		}
	}
	draw_player(tiled_map.tilesets[0], tileset_textures[0], player) // pass in whatever


	k2.present()
	free_all(context.temp_allocator)
	return true
}

shutdown :: proc() {
	unload_map(level_allocator, tileset_textures)
	k2.shutdown()
}
