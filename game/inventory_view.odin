package karl2d_game

import k2 "../../karl2d"
import "core:fmt"
import "core:math"

INVENTORY_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

INVENTORY_COLUMNS :: 2

@(private = "file")
InventoryViewFile: struct {
	isOpen:   bool,
	selected: int,
} = {}

open_inventory_view :: proc() {
	if InventoryViewFile.isOpen do return
	push_view(&INVENTORY_VIEW)
}

@(private = "file")
open_view :: proc() {
	InventoryViewFile.isOpen = true
	InventoryViewFile.selected = 0
}

@(private = "file")
close_view :: proc() {
	InventoryViewFile.isOpen = false
}

@(private = "file")
control_view :: proc() -> bool {
	items := get_inventory_items(player.inventory)
	item_count := len(items)

	if item_count == 0 {
		if is_input_active(.INPUT_UI_CANCEL) || is_input_active(.INPUT_UI_TOGGLE_INVENTORY) {
			pop_view()
			return false
		}
		return false
	}

	InventoryViewFile.selected = clamp(InventoryViewFile.selected, 0, item_count - 1)

	if is_input_active(.INPUT_UI_CANCEL) || is_input_active(.INPUT_UI_TOGGLE_INVENTORY) {
		pop_view()
		return false
	}

	if is_input_active(.INPUT_UI_LEFT) {
		if InventoryViewFile.selected % INVENTORY_COLUMNS > 0 {
			InventoryViewFile.selected -= 1
		}
		return false
	}

	if is_input_active(.INPUT_UI_RIGHT) {
		if (InventoryViewFile.selected % INVENTORY_COLUMNS) < INVENTORY_COLUMNS - 1 &&
		   InventoryViewFile.selected + 1 < item_count {
			InventoryViewFile.selected += 1
		}
		return false
	}

	if is_input_active(.INPUT_UI_UP) {
		if InventoryViewFile.selected - INVENTORY_COLUMNS >= 0 {
			InventoryViewFile.selected -= INVENTORY_COLUMNS
		}
		return false
	}

	if is_input_active(.INPUT_UI_DOWN) {
		if InventoryViewFile.selected + INVENTORY_COLUMNS < item_count {
			InventoryViewFile.selected += INVENTORY_COLUMNS
		}
		return false
	}

	if is_input_active(.INPUT_UI_SUBMIT) {
		selected_prefab := items[InventoryViewFile.selected]
		if itemPrefab[selected_prefab].type == .WEAPON {
			player.weapon_prefab = selected_prefab
			player.attack_swing_duration = itemPrefab[selected_prefab].swing_speed
		}
		return false
	}

	return false
}

@(private = "file")
render_view :: proc() {
	k2.set_camera(nil)
	items := get_inventory_items(player.inventory)
	item_count := len(items)

	frame_w := UI_MODAL_FRAME_WIDTH
	frame_padding := UI_FRAME_PADDING
	title_size := UI_TITLE_SIZE
	cell_h := UI_BUTTON_HEIGHT
	row_gap := f32(14)
	col_gap := f32(18)
	rows := math.max((item_count + INVENTORY_COLUMNS - 1) / INVENTORY_COLUMNS, 1)
	grid_h := f32(rows) * cell_h + f32(rows - 1) * row_gap
	desc_h := f32(74)
	frame_h :=
		frame_padding + title_size + UI_TITLE_TO_TEXT_GAP + grid_h + 16 + desc_h + frame_padding

	frame_x, frame_y := ui_draw_modal_frame(frame_w, frame_h)

	title_x := frame_x + frame_padding
	title_y := frame_y + frame_padding
	k2.draw_text("Inventory", {title_x, title_y}, title_size, TITLE_COLOR)

	grid_x := frame_x + frame_padding
	grid_y := title_y + title_size + UI_TITLE_TO_TEXT_GAP
	grid_w := frame_w - frame_padding * 2
	cell_w := (grid_w - col_gap) / INVENTORY_COLUMNS

	for i := 0; i < item_count; i += 1 {
		col := i % INVENTORY_COLUMNS
		row := i / INVENTORY_COLUMNS
		x := grid_x + f32(col) * (cell_w + col_gap)
		y := grid_y + f32(row) * (cell_h + row_gap)

		is_selected := i == InventoryViewFile.selected
		fg := ITEM_COLOR
		if is_selected {
			k2.draw_rect({x, y, cell_w, cell_h}, ITEM_SELECTED_BG)
			fg = ITEM_SELECTED_FG
		}

		prefab := items[i]
		name := itemPrefab[prefab].name
		equipped := prefab == player.weapon_prefab
		if equipped {
			name = fmt.tprintf("%s (Equipped)", name)
		}

		k2.draw_text(name, {x + 12, y + UI_BUTTON_LABEL_INSET_Y}, UI_TEXT_SIZE, fg)
	}

	desc_y := grid_y + grid_h + 16
	k2.draw_rect({grid_x, desc_y, grid_w, desc_h}, FRAME_BORDER_COLOR)
	k2.draw_rect({grid_x + 2, desc_y + 2, grid_w - 4, desc_h - 4}, FRAME_COLOR)

	if item_count == 0 {
		k2.draw_text("No items in inventory", {grid_x + 12, desc_y + 14}, UI_TEXT_SIZE, ITEM_COLOR)
		k2.draw_text(
			"Press Esc/Tab to close",
			{grid_x + 12, desc_y + 36},
			UI_TEXT_SIZE,
			ITEM_COLOR,
		)
		return
	}

	selected_prefab := items[InventoryViewFile.selected]
	selected_info := itemPrefab[selected_prefab]
	type_text := "Type: Weapon" if selected_info.type == .WEAPON else "Type: Item"

	k2.draw_text(selected_info.name, {grid_x + 12, desc_y + 10}, UI_TEXT_SIZE + 1, TITLE_COLOR)
	k2.draw_text(type_text, {grid_x + 12, desc_y + 30}, UI_TEXT_SIZE, ITEM_COLOR)
	k2.draw_text(
		selected_info.description,
		{grid_x + 12, desc_y + 48},
		UI_TEXT_SIZE - 1,
		ITEM_COLOR,
	)
}
