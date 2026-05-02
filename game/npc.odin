package karl2d_game

import hm "core:/container/handle_map"

NPC_Handle :: distinct hm.Handle32
npcEntities: hm.Dynamic_Handle_Map(NPCData, NPC_Handle)

Disposition :: enum {
	Neutral,
	Friendly,
	Hostile,
}

NPCData :: struct {
	handle:      NPC_Handle,
	x, y:        f32,
	health:      int,
	// tile_id:     i32,
	disposition: Disposition,
	prefab:      NPCPrefab,
}

add_npc_from_prefabs :: proc(x, y: f32, prefab: NPCPrefab) -> Maybe(NPC_Handle) {
	handle: Maybe(NPC_Handle)
	#partial switch prefab {
	case .DWARF_MINER:
		handle = add_npc(x, y, .DWARF_MINER, 100, .Friendly)
	case:
		warnf("NPC: Attempted to spawn unknown NPC prefab %v", prefab)
		return nil
	}
	return handle
}

add_npc :: proc(
	x, y: f32,
	prefab: NPCPrefab,
	health: int,
	disposition: Disposition,
) -> Maybe(NPC_Handle) {
	npc := hm.add(
		&npcEntities,
		NPCData{x = x, y = y, health = health, disposition = disposition, prefab = prefab},
	)
	creature := hm.get(&npcEntities, npc)
	debugf("NPC: Spawned NPC (handle: %v, disposition: %v)", npc, creature.disposition)
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
