package karl2d_gamepad_example

import k2 "../../karl2d"
import "../tiled"
import "core:fmt"
import "core:mem"

tiled_map_file :: #load("../mine.tmj")
tiled_tileset_file :: #load("../fullsheet.tsj")
tiled_tileset_image_file :: #load("../assets/fullsheet.png")

tiled_map: tiled.Map
tileset_textures: []k2.Texture
level_allocator: mem.Allocator

load_map :: proc(alloc: mem.Allocator) -> (tiled_map: tiled.Map, tileset_textures: []k2.Texture) {
	tiled_map = tiled.parse_tilemap(tiled_map_file, alloc)
	tileset_textures = make_slice([]k2.Texture, len(tiled_map.tilesets), alloc)

	for i in 0 ..< len(tiled_map.tilesets) {
		map_tileset := tiled_map.tilesets[i]

		ts := tiled.parse_tileset(tiled_tileset_file, alloc)
		ts.first_gid = map_tileset.first_gid
		if len(ts.source) == 0 do ts.source = map_tileset.source

		// Some exported tilesets omit tilecount; derive it from dimensions so gid range checks still work.
		if ts.tile_count <= 0 && ts.columns > 0 && ts.tile_height > 0 {
			row_stride := ts.tile_height + ts.spacing
			if row_stride > 0 {
				rows := ts.image_height / row_stride
				ts.tile_count = ts.columns * rows
			}
		}

		tiled_map.tilesets[i] = ts
		tileset_textures[i] = k2.load_texture_from_bytes(tiled_tileset_image_file)
	}

	return
}

unload_map :: proc(alloc: mem.Allocator, textures: []k2.Texture) {
  for tex in textures {
    k2.destroy_texture(tex)
  }

  free_all(alloc)
}

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
}

step :: proc() -> bool {
	if !k2.update() {
		return false
	}

	k2.clear(k2.DARK_BLUE)

	gamepad_demo(0, {0, 0})
	gamepad_demo(1, {500, 0})
	gamepad_demo(2, {0, 300})
	gamepad_demo(3, {500, 300})

	k2.set_camera(nil)
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

	k2.present()
	free_all(context.temp_allocator)
	return true
}

shutdown :: proc() {
	unload_map(level_allocator, tileset_textures)
	k2.shutdown()
}
