package karl2d_game

import k2 "../../karl2d"
import "../tiled"
import hm "core:/container/handle_map"
import "core:math"

GAME_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

@(private = "file")
dt: f32
@(private = "file")
camera: k2.Camera
@(private = "file")
ui_camera: k2.Camera


@(private = "file")
GameFile: struct {
	IsOpen:                  bool,
	title:                   string,
	options:                 [dynamic]string,
	selected:                int,
	attackResolvedThisSwing: bool,
} = {}

ATTACK_DAMAGE :: 25

get_player_attack_rect :: proc(p: Player) -> k2.Rect {
	r := k2.Rect{p.x, p.y, 16, 16}
	switch p.facing {
	case .Up:
		r.y -= 16
	case .Down:
		r.y += 16
	case .Left:
		r.x -= 16
	case .Right:
		r.x += 16
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
		npc_rect := k2.Rect{npc.x, npc.y, 16, 16}
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
	level_allocator = context.allocator
	tiled_map, tileset_textures = load_map(level_allocator)

	init_npc_prefabs()
	init_items_prefabs()
	player_init()
	//TODO: testing
	add_npc_from_prefabs(16 * 4, 16 * 4, .DWARF_MINER)
	add_item_from_prefabs(16 * 4, 16 * 5, .WORN_PICKAXE)

	camera = k2.Camera {
		offset = k2.get_screen_size() / 2,
		zoom   = 3,
	}
	ui_camera = k2.Camera {
		// offset = k2.get_screen_size() / 2,
		zoom = 2,
	}
}

@(private = "file")
control_view :: proc() -> bool {
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
	return false
}

draw_tile_layers :: proc() {
	for layer in tiled_map.layers {
		if layer.type != .tilelayer do continue
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

			dist := distance(
				player.x + 8,
				player.y + 8,
				world_x + source.w / 2,
				world_y + source.h / 2,
			)
			alpha := cast(u8)math.remap_clamped(dist, 50, 125, 0, 255)
			k2.draw_rect_vec(
				{world_x, world_y},
				{source.w, source.h},
				k2.color_alpha(k2.BLACK, alpha),
			)
		}
	}
}

draw_items :: proc() {
	it := hm.iterator_make(&itemEntities)
	for item, item_hm in hm.iterate(&it) {
		tileset := tiled_map.tilesets[0]
		texture := tileset_textures[0]
		tile_id := itemPrefab[item.prefab].tile_id - tileset.first_gid
		tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
		tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
		source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}
		k2.draw_texture_rect(texture, source, {item.x, item.y})
	}
}

draw_npcs :: proc() {
	it := hm.iterator_make(&npcEntities)
	for npc, npc_hm in hm.iterate(&it) {
		tileset := tiled_map.tilesets[0]
		texture := tileset_textures[0]
		tile_id := npcsPrefab[npc.prefab].tile_id - tileset.first_gid
		tileset_x := f32((tile_id % tileset.columns) * (tileset.tile_width + tileset.spacing))
		tileset_y := f32((tile_id / tileset.columns) * (tileset.tile_height + tileset.spacing))
		source: k2.Rect = {tileset_x, tileset_y, f32(tileset.tile_width), f32(tileset.tile_height)}
		k2.draw_texture_rect(texture, source, {npc.x, npc.y})
	}
}

@(private = "file")
render_view :: proc() {
	dt = k2.get_frame_time()

	// camera.target is the center of the camera in world coordinates
	camera.target.x = player.x + 8
	camera.target.y = player.y + 8
	camera.offset = k2.get_screen_size() / 2

	k2.set_camera(camera)

	screen_rect := k2.rect_from_pos_size({}, k2.get_screen_size())

	draw_tile_layers()
	draw_items()
	draw_npcs()
	draw_player(tiled_map.tilesets[0], tileset_textures[0], player)
	k2.set_camera(ui_camera)
	draw_player_ui(tiled_map.tilesets[0], tileset_textures[0], player)
}

@(private = "file")
close_view :: proc() {
	flush_all_inventories()
	flush_all_npcs()
	flush_all_items()
	unload_map(level_allocator, tileset_textures)
}

distance :: proc(start_x, start_y, end_x, end_y: f32) -> f32 {
	dx := f32(math.max(start_x, end_x) - math.min(start_x, end_x))
	dy := f32(math.max(start_y, end_y) - math.min(start_y, end_y))
	return math.sqrt((dx * dx) + (dy * dy))
}
