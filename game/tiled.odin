package karl2d_game

import k2 "../../karl2d"
import "../tiled"
import "core:mem"

// tiled_map_file :: #load("../mine.tmj")
tiled_tileset_file :: #load("../fullsheet.tsj")
tiled_tileset_image_file :: #load("../assets/fullsheet.png")

tiled_map_arena_file :: #load("../assets/arena.tmj")
tiled_map_cave_file :: #load("../assets/cave.tmj")

tiled_map: tiled.Map
tileset_textures: []k2.Texture
level_allocator: mem.Allocator
selected_map: GameMaps = .Arena

GameMaps :: enum {
	// Mine,
	Arena,
	Cave,
}

Layers :: enum {
	Ground,
	Walls,
	Decoration,
	Objects,
}

load_map :: proc(alloc: mem.Allocator) -> (tiled_map: tiled.Map, tileset_textures: []k2.Texture) {
	switch selected_map {
	// case .Mine:
	// 	tiled_map = tiled.parse_tilemap(tiled_map_file, alloc)
	case .Arena:
		tiled_map = tiled.parse_tilemap(tiled_map_arena_file, alloc)
	case .Cave:
		tiled_map = tiled.parse_tilemap(tiled_map_cave_file, alloc)
	}

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
