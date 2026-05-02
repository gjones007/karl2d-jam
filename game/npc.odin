package karl2d_game

import k2 "../../karl2d"

import hm "core:/container/handle_map"
import la "core:math/linalg"

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

NPCData :: struct {
	handle:        NPC_Handle,
	x, y:          f32,
	health:        int,
	disposition:   Disposition,
	specials:      bit_set[SpecialFlags],
	move_speed:    f32,
	damage:        int,
	prefab:        NPCPrefab,
	spawner_timer: f32,
}

add_npc_from_prefabs :: proc(x, y: f32, prefab: NPCPrefab) -> Maybe(NPC_Handle) {
	handle: Maybe(NPC_Handle)
	if prefab == .NONE {
		warnf("NPC: Attempted to spawn NPC with NONE prefab, skipping")
		return nil
	}
	handle = add_npc(x, y, prefab, npcsPrefab[prefab].health, npcsPrefab[prefab].disposition)
	return handle
}

npc_actions :: proc(dt: f32) {
	it := hm.iterator_make(&npcEntities)
	for npc, npc_handle in hm.iterate(&it) {
		if .SPAWNER in npcsPrefab[npc.prefab].specials {
			npc.spawner_timer -= dt
			if npc.spawner_timer <= 0 {
				npc.spawner_timer = npcsPrefab[npc.prefab].spawn_rate
				add_npc_from_prefabs(npc.x, npc.y, npcsPrefab[npc.prefab].spawn_prefab)
			}
			continue
		}
		if npc_should_move_towards_player(npc^) {
			player_rect := k2.Rect{player.x, player.y, 16, 16}
			npc_rect := k2.Rect{npc.x, npc.y, 16, 16}
			npc_move_towards_player(npc, dt)
		} else {take_damage_player(npc.damage)}
	}
}

npc_move_towards_player :: proc(data: ^NPCData, dt: f32) {
	dir := la.normalize(cast(la.Vector2f32){player.x - data.x, player.y - data.y})
	data.x += dir.x * data.move_speed * dt
	data.y += dir.y * data.move_speed * dt
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

// TODO: use the walls
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
) -> Maybe(NPC_Handle) {
	npc := hm.add(
		&npcEntities,
		NPCData {
			x = x,
			y = y,
			health = health,
			disposition = disposition,
			prefab = prefab,
			move_speed = npcsPrefab[prefab].move_speed,
		},
	)
	creature := hm.get(&npcEntities, npc)
	debugf("NPC: Spawned NPC (handle: %v, disposition: %v)", npc, creature.disposition)
	play_sound(.EnemySpawn)
	return npc
}

take_damage_npc :: proc(handle: NPC_Handle, damage: int) {
	npc := hm.get(&npcEntities, handle)
	npc.health -= damage
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
