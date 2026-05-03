package karl2d_game

import k2 "../../karl2d"

import "../tiled"
import hm "core:/container/handle_map"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"

NPC_Handle :: distinct hm.Handle32
npcEntities: hm.Dynamic_Handle_Map(NPCData, NPC_Handle)

Disposition :: enum {
	Neutral,
	Friendly,
	Hostile,
}

SpecialFlags :: enum {
	SPAWNER,
	IMMORTAL,
}

NPCSpecials :: bit_set[SpecialFlags]

NPCData :: struct {
	handle:              NPC_Handle,
	conversation_handle: Conversation_Handle,
	x, y:                f32,
	health:              int,
	disposition:         Disposition,
	specials:            NPCSpecials,
	move_speed:          f32,
	damage:              int,
	prefab:              NPCPrefab,
	hit_cooldown_timer:  f32,
	spawner_timer:       f32,
	tile_id:             i32,
}

add_npc_from_prefabs :: proc(
	x, y: f32,
	prefab: NPCPrefab,
	specials: NPCSpecials,
) -> Maybe(NPC_Handle) {
	handle: Maybe(NPC_Handle)
	ok := false
	if prefab == .NONE {
		warnf("NPC: Attempted to spawn NPC with NONE prefab, skipping")
		return nil
	}
	if .SPAWNER in specials && npcsPrefab[prefab].spawn_prefab == .NONE {
		npcsPrefab[prefab].spawn_prefab = prefab
		return nil
	}
	if handle, ok = add_npc(
		   x,
		   y,
		   prefab,
		   npcsPrefab[prefab].health,
		   npcsPrefab[prefab].disposition,
		   specials,
	   ).?; ok {
		return handle
	}
	return nil
}

npc_actions :: proc(
	dt: f32,
	collision_layers: []tiled.Layer,
	map_width, map_height, tile_width, tile_height: i32,
) {
	it := hm.iterator_make(&npcEntities)
	for npc, npc_handle in hm.iterate(&it) {
		if npc.hit_cooldown_timer > 0 {
			npc.hit_cooldown_timer -= dt
			if npc.hit_cooldown_timer < 0 {
				npc.hit_cooldown_timer = 0
			}
		}

		if .SPAWNER in npc.specials {
			npc.spawner_timer -= dt

			spawn_rate := npcsPrefab[npc.prefab].spawn_rate
			if spawn_rate > 0 {
				elapsed := spawn_rate - npc.spawner_timer
				phase := (math.sin(elapsed * math.PI * 2) + 1) * 0.5
				// Reuse hit_cooldown_timer as a normalized pulse alpha signal for rendering.
				npc.hit_cooldown_timer = math.remap_clamped(phase, 0, 1, 0.2, 1.0)
			}

			if npc.spawner_timer <= 0 {
				npc.spawner_timer = npcsPrefab[npc.prefab].spawn_rate
				add_npc_from_prefabs(npc.x, npc.y, npcsPrefab[npc.prefab].spawn_prefab, {})
			}
			continue
		}

		if npc.disposition != .Hostile {
			continue
		}

		player_rect := k2.Rect{player.x, player.y, 16, 16}
		npc_rect := k2.Rect{npc.x, npc.y, 16, 16}

		if _, does := k2.rect_overlap(npc_rect, player_rect); does {
			take_damage_player(npc.damage)
			continue
		}

		if npc_can_see_player(npc^) {
			npc_move_towards_player(
				npc,
				dt,
				collision_layers,
				map_width,
				map_height,
				tile_width,
				tile_height,
			)
		}
	}
}

npc_move_towards_player :: proc(
	data: ^NPCData,
	dt: f32,
	collision_layers: []tiled.Layer,
	map_width, map_height, tile_width, tile_height: i32,
) {
	dir := la.normalize(cast(la.Vector2f32){player.x - data.x, player.y - data.y})
	move_x := dir.x * data.move_speed * dt
	move_y := dir.y * data.move_speed * dt

	if move_x < 0 &&
	   !movement_collision_check(
			   data.x + move_x,
			   data.y,
			   collision_layers,
			   map_width,
			   map_height,
			   tile_width,
			   tile_height,
		   ) {
		data.x += move_x
	}
	if move_x > 0 &&
	   !movement_collision_check(
			   data.x + move_x,
			   data.y,
			   collision_layers,
			   map_width,
			   map_height,
			   tile_width,
			   tile_height,
		   ) {
		data.x += move_x
	}
	if move_y < 0 &&
	   !movement_collision_check(
			   data.x,
			   data.y + move_y,
			   collision_layers,
			   map_width,
			   map_height,
			   tile_width,
			   tile_height,
		   ) {
		data.y += move_y
	}
	if move_y > 0 &&
	   !movement_collision_check(
			   data.x,
			   data.y + move_y,
			   collision_layers,
			   map_width,
			   map_height,
			   tile_width,
			   tile_height,
		   ) {
		data.y += move_y
	}
}

// TODO: account for walls and other obstacles, attack range, etc.
npc_should_move_towards_player :: proc(npc: NPCData) -> bool {
	if npc.disposition != .Hostile {
		return false
	}
	if !npc_can_see_player(npc) {
		return false
	}
	if distance(npc.x, npc.y, player.x, player.y) < 16 {
		return false
	}
	return true
}

npc_can_see_player :: proc(npc: NPCData) -> bool {
	distance := distance(npc.x, npc.y, player.x, player.y)
	if distance > 1000 {
		return false
	}
	return true
}

add_npc :: proc(
	x, y: f32,
	prefab: NPCPrefab,
	health: int,
	disposition: Disposition,
	specials: bit_set[SpecialFlags] = {},
) -> Maybe(NPC_Handle) {

	if .SPAWNER in specials {
		npc := hm.add(
			&npcEntities,
			NPCData {
				x = x,
				y = y,
				conversation_handle = Conversation_Handle{},
				health = 9999,
				disposition = .Hostile,
				prefab = prefab,
				move_speed = 0,
				damage = 0,
				hit_cooldown_timer = 0,
				spawner_timer = rand.float32_range(0, npcsPrefab[prefab].spawn_rate),
				specials = NPCSpecials{.SPAWNER, .IMMORTAL},
				tile_id = SPAWNER,
			},
		)
		creature := hm.get(&npcEntities, npc)
		debugf("NPC: Spawned NPC (handle: %v, disposition: %v)", npc, creature.disposition)
		play_sound(.EnemySpawn)
		return npc
	} else {
		npc := hm.add(
			&npcEntities,
			NPCData {
				x = x,
				y = y,
				conversation_handle = Conversation_Handle{},
				health = health,
				disposition = disposition,
				prefab = prefab,
				move_speed = npcsPrefab[prefab].move_speed,
				damage = npcsPrefab[prefab].damage,
				hit_cooldown_timer = 0,
				spawner_timer = rand.float32_range(0, npcsPrefab[prefab].spawn_rate),
				specials = specials,
				tile_id = npcsPrefab[prefab].tile_id,
			},
		)
		creature := hm.get(&npcEntities, npc)
		debugf("NPC: Spawned NPC (handle: %v, disposition: %v)", npc, creature.disposition)
		play_sound(.EnemySpawn)
		return npc
	}
}

take_damage_npc :: proc(handle: NPC_Handle, damage: int) {
	npc := hm.get(&npcEntities, handle)
	if .IMMORTAL in npc.specials {
		npc.hit_cooldown_timer = 0
		return
	}

	if npc.hit_cooldown_timer > 0 do return

	npc.health -= damage
	npc.hit_cooldown_timer = PLAYER_HIT_COOLDOWN
	debugf("NPC: NPC %v took %d damage, health is now %d", handle, damage, npc.health)

	if npc.health <= 0 {
		play_sound(.EnemyDeath)
		debugf("NPC: NPC %v has died", handle)
		remove_npc(handle)
	} else {
		play_sound(.EnemyHit)
	}
}

remove_npc :: proc(handle: NPC_Handle) -> bool {
	if ok, err := hm.remove(&npcEntities, handle); err != nil {
		debugf("NPC: Removed NPC (handle: %v)", handle)
		return true
	} else {
		warnf("NPC: Failed to remove NPC (handle: %v): %v", handle, err)
		return false
	}
}

flush_all_npcs :: proc() {
	hm.clear(&npcEntities)
}
