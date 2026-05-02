package karl2d_game

import "core:time"

OVERLAY_COLOR :: [4]u8{0, 0, 0, 115}
FRAME_COLOR :: [4]u8{33, 36, 46, 250}
FRAME_BORDER_COLOR :: [4]u8{204, 212, 225, 255}
TITLE_COLOR :: [4]u8{242, 245, 250, 255}
TEXT_COLOR :: [4]u8{242, 245, 250, 255}
ITEM_COLOR :: [4]u8{214, 222, 237, 255}
ITEM_SELECTED_BG :: [4]u8{232, 196, 71, 255}
ITEM_SELECTED_FG :: [4]u8{28, 20, 8, 255}

RED_HEARTS := [?]i32{162, 163, 164, 165}
GREEN_HEARTS := [?]i32{263, 264, 265, 266}
BLUE_HEARTS := [?]i32{364, 365, 366, 367}

WHITE_QUESTIONMARK: i32 = 61
YELLOW_QUESTIONMARK: i32 = 62
RED_QUESTIONMARK: i32 = 63
DARKRED_QUESTIONMARK: i32 = 64
BROWN_QUESTIONMARK: i32 = 65
DARKBLUE_QUESTIONMARK: i32 = 66

BOX: i32 = 7667
CHEST: i32 = 7668

RED_POTION: i32 = 7457
PINK_POTION: i32 = 7458
ORANGE_POTION: i32 = 7459
YELLOW_POTION: i32 = 7460
LIGHTGREEN_POTION: i32 = 7461
GREEN_POTION: i32 = 7462
LIGHTBLUE_POTION: i32 = 7463
BLUE_POTION: i32 = 7464

SWORD: i32 = 8063
SWORD2: i32 = 9999
SWORD_BLK: i32 = 10000
SWORD_GOLD: i32 = 10001

WORN_PICKAXE: i32 = 8266 // these are off by 1 ??
GOOD_PICKAXE: i32 = 8267
PERFECT_PICKAXE: i32 = 8268

DWARF_MINER: i32 = 5206

MUMMY: i32 = 263
SPAWNER: i32 = 8531

ItemType :: enum {
	POTION,
	WEAPON,
	MISC,
}

ItemPrefab :: enum {
	NONE,
	SWORD_GOLD,
	WORN_PICKAXE,
	RED_POTION,
	PINK_POTION,
	ORANGE_POTION,
	YELLOW_POTION,
	LIGHTGREEN_POTION,
	GREEN_POTION,
	LIGHTBLUE_POTION,
	BLUE_POTION,
}

ItemPrefabInfo :: struct {
	type:        ItemType,
	name:        string,
	description: string,
	tile_id:     i32,
	swing_speed: time.Duration,
}

itemPrefab: [ItemPrefab]ItemPrefabInfo

init_items_prefabs :: proc() {
	itemPrefab[.SWORD_GOLD] = ItemPrefabInfo {
		type        = .WEAPON,
		name        = "Gold Sword",
		description = "A sword made of gold.",
		tile_id     = SWORD_GOLD,
		swing_speed = 200 * time.Millisecond,
	}
	itemPrefab[.WORN_PICKAXE] = ItemPrefabInfo {
		type        = .WEAPON,
		name        = "Worn Pickaxe",
		description = "A worn pickaxe, not very effective but better than nothing.",
		tile_id     = WORN_PICKAXE,
		swing_speed = 400 * time.Millisecond,
	}
}

NPCPrefab :: enum {
	NONE,
	DWARF_MINER,
	MUMMY,
	SPAWNER,
}

NPCPrefabInfo :: struct {
	name:         string,
	description:  string,
	health:       int,
	damage:       int,
	disposition:  Disposition,
	specials:     bit_set[SpecialFlags],
	tile_id:      i32,
	spawn_rate:   f32,
	spawn_prefab: NPCPrefab,
	move_speed:   f32,
}

npcsPrefab: [NPCPrefab]NPCPrefabInfo

init_npc_prefabs :: proc() {
	npcsPrefab[.DWARF_MINER] = NPCPrefabInfo {
		name        = "Dwarf Miner",
		description = "A stout dwarf with a bushy beard and a pickaxe. He looks like he's been working in the mines for decades.",
		health      = 100,
		damage      = 10,
		disposition = .Friendly,
		tile_id     = DWARF_MINER,
		move_speed  = 100.0,
	}
	npcsPrefab[.MUMMY] = NPCPrefabInfo {
		name        = "Mummy",
		description = "An ancient mummy wrapped in bandages. It moves slowly but relentlessly.",
		health      = 150,
		damage      = 20,
		disposition = .Hostile,
		tile_id     = MUMMY,
		move_speed  = 25.0,
	}
	npcsPrefab[.SPAWNER] = NPCPrefabInfo {
		name         = "Spawner",
		description  = "A mysterious spawner that continuously generates hostile creatures.",
		health       = 9999,
		damage       = 0,
		disposition  = .Hostile,
		specials     = bit_set[SpecialFlags]{.SPAWNER, .IMMORTAL},
		tile_id      = SPAWNER,
		spawn_rate   = 15.0,
		spawn_prefab = .MUMMY,
		move_speed   = 0.0,
	}
}
