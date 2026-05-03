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

// Shared UI layout tokens used by modal-like views.
UI_FRAME_PADDING: f32 : 24
UI_MODAL_FRAME_WIDTH: f32 : 760
UI_MENU_FRAME_WIDTH: f32 : 520
UI_TITLE_SIZE: f32 : 30
UI_TEXT_SIZE: f32 : 20
UI_BUTTON_TEXT_SIZE: f32 : 20
UI_BUTTON_HEIGHT: f32 : 48
UI_BUTTON_WIDTH: f32 : 100
UI_BUTTON_GAP: f32 : 24
UI_MESSAGE_CHARS_PER_LINE: int : 44
UI_LINE_GAP: f32 : 10
UI_TITLE_TO_TEXT_GAP: f32 : 18
UI_TEXT_TO_BUTTON_GAP: f32 : 24
UI_BUTTON_LABEL_INSET_X: f32 : 16
UI_BUTTON_LABEL_INSET_Y: f32 : 12

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

TINY_OGRE: i32 = 8941
HAT_OGRE: i32 = 8942
BANDIT_OGRE: i32 = 8943
ROUND_OGRE: i32 = 8946
TWO_HEADED_OGRE: i32 = 8947

RED_POTION: i32 = 7458
PINK_POTION: i32 = 7458
ORANGE_POTION: i32 = 7459
YELLOW_POTION: i32 = 7460
LIGHTGREEN_POTION: i32 = 7461
GREEN_POTION: i32 = 7462
LIGHTBLUE_POTION: i32 = 7463
BLUE_POTION: i32 = 7464

RUBY_RING: i32 = 8864

SWORD: i32 = 8063
SILVER_SWORD: i32 = 9999
BLACK_SWORD: i32 = 10000
GOLD_SWORD: i32 = 10001
PURPLE_SWORD: i32 = 10002
CUTLASS: i32 = 10003
CUTLASS2: i32 = 10004
AXE: i32 = 10101
BATTLEAXE: i32 = 10101

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
	SILVER_SWORD,
	BLACK_SWORD,
	GOLD_SWORD,
	PURPLE_SWORD,
	CUTLASS,
	CUTLASS2,
	// AXE,
	BATTLEAXE,
	RUBY_RING,
	WORN_PICKAXE,
	CHEST,
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
	type:            ItemType,
	name:            string,
	description:     string,
	tile_id:         i32,
	swing_speed:     time.Duration,
	damage:          int,
	flip_horizontal: bool, // is the sprite left-facing (bottom left to right) and should be flipped horizontally when drawn?
}

itemPrefab: [ItemPrefab]ItemPrefabInfo

init_items_prefabs :: proc() {
	itemPrefab[.SILVER_SWORD] = ItemPrefabInfo {
		type            = .WEAPON,
		name            = "Silver Sword",
		description     = "A sharp sword.",
		tile_id         = SILVER_SWORD,
		swing_speed     = 250 * time.Millisecond,
		damage          = 25,
		flip_horizontal = true,
	}
	itemPrefab[.BLACK_SWORD] = ItemPrefabInfo {
		type            = .WEAPON,
		name            = "Black Sword",
		description     = "A sharp sword made of black steel.",
		tile_id         = BLACK_SWORD,
		swing_speed     = 300 * time.Millisecond,
		damage          = 40,
		flip_horizontal = false,
	}
	itemPrefab[.GOLD_SWORD] = ItemPrefabInfo {
		type            = .WEAPON,
		name            = "Gold Sword",
		description     = "A sword made of gold.",
		tile_id         = GOLD_SWORD,
		swing_speed     = 150 * time.Millisecond,
		damage          = 35,
		flip_horizontal = true,
	}
	itemPrefab[.PURPLE_SWORD] = ItemPrefabInfo {
		type            = .WEAPON,
		name            = "Purple Sword",
		description     = "A sword made of purple steel.",
		tile_id         = PURPLE_SWORD,
		swing_speed     = 150 * time.Millisecond,
		damage          = 25,
		flip_horizontal = false,
	}
	itemPrefab[.CUTLASS] = ItemPrefabInfo {
		type            = .WEAPON,
		name            = "Cutlass",
		description     = "A cutlass.",
		tile_id         = CUTLASS,
		swing_speed     = 350 * time.Millisecond,
		damage          = 20,
		flip_horizontal = true,
	}
	itemPrefab[.CUTLASS2] = ItemPrefabInfo {
		type            = .WEAPON,
		name            = "Cutlass 2",
		description     = "A second cutlass.",
		tile_id         = CUTLASS2,
		swing_speed     = 200 * time.Millisecond,
		damage          = 25,
		flip_horizontal = true,
	}
	// itemPrefab[.AXE] = ItemPrefabInfo {
	// 	type            = .WEAPON,
	// 	name            = "Axe",
	// 	description     = "A sharp axe.",
	// 	tile_id         = AXE,
	// 	swing_speed     = 200 * time.Millisecond,
	// 	damage          = 28,
	// 	flip_horizontal = true,
	// }
	itemPrefab[.BATTLEAXE] = ItemPrefabInfo {
		type            = .WEAPON,
		name            = "Battleaxe",
		description     = "A powerful battleaxe.",
		tile_id         = BATTLEAXE,
		swing_speed     = 500 * time.Millisecond,
		damage          = 45,
		flip_horizontal = false,
	}
	itemPrefab[.WORN_PICKAXE] = ItemPrefabInfo {
		type            = .WEAPON,
		name            = "Worn Pickaxe",
		description     = "A worn pickaxe, not very effective but better than nothing.",
		tile_id         = WORN_PICKAXE,
		swing_speed     = 400 * time.Millisecond,
		damage          = 5,
		flip_horizontal = false,
	}
	itemPrefab[.RUBY_RING] = ItemPrefabInfo {
		type            = .MISC,
		name            = "Ruby Ring",
		description     = "A ring with a precious ruby.",
		tile_id         = RUBY_RING,
		swing_speed     = 0 * time.Millisecond,
		damage          = 0,
		flip_horizontal = false,
	}
	itemPrefab[.RED_POTION] = ItemPrefabInfo {
		type            = .POTION,
		name            = "Red Potion",
		description     = "A red potion that restores 100 health.",
		tile_id         = RED_POTION,
		swing_speed     = 0 * time.Millisecond,
		damage          = 100,
		flip_horizontal = false,
	}
	itemPrefab[.GREEN_POTION] = ItemPrefabInfo {
		type            = .POTION,
		name            = "Green Potion",
		description     = "A green potion that restores 100 health.",
		tile_id         = GREEN_POTION,
		swing_speed     = 0 * time.Millisecond,
		damage          = 100,
		flip_horizontal = false,
	}
}

NPCPrefab :: enum {
	NONE,
	DWARF_MINER,
	MUMMY,
	TINY_OGRE,
	HAT_OGRE,
	BANDIT_OGRE,
	ROUND_OGRE,
	TWO_HEADED_OGRE,
	// SPAWNER,
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
		health      = 75,
		damage      = 20,
		disposition = .Hostile,
		tile_id     = MUMMY,
		move_speed  = 25.0,
		spawn_rate  = 30.0,
	}
	npcsPrefab[.TINY_OGRE] = NPCPrefabInfo {
		name        = "Tiny Ogre",
		description = "A small but fierce ogre.",
		health      = 50,
		damage      = 15,
		disposition = .Hostile,
		tile_id     = TINY_OGRE,
		move_speed  = 87.0,
		spawn_rate  = 20.0,
	}
	npcsPrefab[.HAT_OGRE] = NPCPrefabInfo {
		name        = "Hat Ogre",
		description = "An ogre wearing a stylish hat.",
		health      = 60,
		damage      = 18,
		disposition = .Hostile,
		tile_id     = HAT_OGRE,
		move_speed  = 35.0,
		spawn_rate  = 25.0,
	}
	npcsPrefab[.BANDIT_OGRE] = NPCPrefabInfo {
		name        = "Bandit Ogre",
		description = "A cunning ogre bandit.",
		health      = 70,
		damage      = 20,
		disposition = .Hostile,
		tile_id     = BANDIT_OGRE,
		move_speed  = 40.0,
		spawn_rate  = 25.0,
	}
	npcsPrefab[.ROUND_OGRE] = NPCPrefabInfo {
		name        = "Round Ogre",
		description = "A round and jolly ogre.",
		health      = 80,
		damage      = 22,
		disposition = .Hostile,
		tile_id     = ROUND_OGRE,
		move_speed  = 45.0,
		spawn_rate  = 20.0,
	}
	npcsPrefab[.TWO_HEADED_OGRE] = NPCPrefabInfo {
		name        = "Two-Headed Ogre",
		description = "An ogre with two heads, twice as dangerous.",
		health      = 100,
		damage      = 50,
		disposition = .Hostile,
		tile_id     = TWO_HEADED_OGRE,
		move_speed  = 15.0,
		spawn_rate  = 70.0,
	}
}
