package karl2d_game

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
}

itemPrefab: [ItemPrefab]ItemPrefabInfo

init_items_prefabs :: proc() {
	itemPrefab[.SWORD_GOLD] = ItemPrefabInfo {
		type        = .WEAPON,
		name        = "Gold Sword",
		description = "A sword made of gold.",
		tile_id     = SWORD_GOLD,
	}
	itemPrefab[.WORN_PICKAXE] = ItemPrefabInfo {
		type        = .WEAPON,
		name        = "Worn Pickaxe",
		description = "A worn pickaxe, not very effective but better than nothing.",
		tile_id     = WORN_PICKAXE,
	}
}

NPCPrefab :: enum {
	NONE,
	DWARF_MINER,
}

NPCPrefabInfo :: struct {
	name:        string,
	description: string,
	health:      int,
	disposition: Disposition,
	tile_id:     i32,
}

npcsPrefab: [NPCPrefab]NPCPrefabInfo

init_npc_prefabs :: proc() {
	npcsPrefab[.DWARF_MINER] = NPCPrefabInfo {
		name        = "Dwarf Miner",
		description = "A stout dwarf with a bushy beard and a pickaxe. He looks like he's been working in the mines for decades.",
		health      = 100,
		disposition = .Friendly,
		tile_id     = DWARF_MINER,
	}
}
