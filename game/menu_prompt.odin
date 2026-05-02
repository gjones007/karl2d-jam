package karl2d_game

import k2 "../../karl2d"

menu_prompt_select_callback :: proc(index: int)
menu_prompt_cancel_callback :: proc()

MENU_PROMPT_OVERLAY_COLOR :: [4]u8{0, 0, 0, 115}
MENU_PROMPT_FRAME_COLOR :: [4]u8{33, 36, 46, 250}
MENU_PROMPT_FRAME_BORDER_COLOR :: [4]u8{204, 212, 225, 255}
MENU_PROMPT_TITLE_COLOR :: [4]u8{242, 245, 250, 255}
MENU_PROMPT_ITEM_COLOR :: [4]u8{214, 222, 237, 255}
MENU_PROMPT_ITEM_SELECTED_BG :: [4]u8{232, 196, 71, 255}
MENU_PROMPT_ITEM_SELECTED_FG :: [4]u8{28, 20, 8, 255}

MENU_PROMPT_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

menu_prompt_file: struct {
	promptIsOpen: bool,
	title:        string,
	options:      [dynamic]string,
	selected:     int,
	onSelect:     menu_prompt_select_callback,
	onCancel:     menu_prompt_cancel_callback,

	// renderCtx: ^k2.Context,
} = {}

open_menu_prompt :: proc(
	title: string,
	options: []string,
	onSelect: menu_prompt_select_callback,
	onCancel: menu_prompt_cancel_callback,
) {
	if menu_prompt_file.promptIsOpen {
		error("PROMPT: MenuPrompt is already open")
		return
	}

	if len(options) == 0 {
		error("PROMPT: MenuPrompt requires at least one option")
		return
	}

	menu_prompt_file.promptIsOpen = true
	menu_prompt_file.title = title
	menu_prompt_file.onSelect = onSelect
	menu_prompt_file.onCancel = onCancel
	menu_prompt_file.selected = 0

	menu_prompt_file.options = make([dynamic]string, context.allocator)
	append(&menu_prompt_file.options, ..options)

	push_view(&MENU_PROMPT_VIEW)
}

@(private = "file")
open_view :: proc() {
	if len(menu_prompt_file.options) > 0 {
		menu_prompt_file.selected = 0
	}
}

@(private = "file")
close_view :: proc() {
	menu_prompt_file.promptIsOpen = false
	if menu_prompt_file.options != nil {
		delete(menu_prompt_file.options)
	}
	menu_prompt_file.options = nil
}

@(private = "file")
control_view :: proc() -> bool {
	if is_input_active(.INPUT_UI_CANCEL) {
		pop_view()
		if menu_prompt_file.onCancel != nil {
			menu_prompt_file.onCancel()
		}
		return true
	}

	if is_input_active(.INPUT_UI_UP) && menu_prompt_file.selected > 0 {
		menu_prompt_file.selected -= 1
		return true
	}

	if is_input_active(.INPUT_UI_DOWN) &&
	   menu_prompt_file.selected < len(menu_prompt_file.options) - 1 {
		menu_prompt_file.selected += 1
		return true
	}

	if is_input_active(.INPUT_UI_SUBMIT) {
		selected := menu_prompt_file.selected
		pop_view()
		if menu_prompt_file.onSelect != nil {
			menu_prompt_file.onSelect(selected)
		}
	}
	return false
}

@(private = "file")
render_view :: proc() {

	k2.set_camera(nil)
	screen := k2.get_screen_size()

	frame_w := f32(420)
	frame_padding := f32(14)
	title_size := f32(20)
	item_size := f32(15)
	row_h := item_size + 16
	frame_h :=
		frame_padding +
		title_size +
		20 +
		f32(len(menu_prompt_file.options)) * row_h +
		frame_padding

	frame_x := (screen.x - frame_w) * 0.5
	frame_y := (screen.y - frame_h) * 0.5

	k2.draw_rect({0, 0, screen.x, screen.y}, MENU_PROMPT_OVERLAY_COLOR)
	k2.draw_rect(
		{frame_x - 2, frame_y - 2, frame_w + 4, frame_h + 4},
		MENU_PROMPT_FRAME_BORDER_COLOR,
	)
	k2.draw_rect({frame_x, frame_y, frame_w, frame_h}, MENU_PROMPT_FRAME_COLOR)

	title_x := frame_x + frame_padding
	title_y := frame_y + frame_padding
	k2.draw_text(menu_prompt_file.title, {title_x, title_y}, title_size, MENU_PROMPT_TITLE_COLOR)

	row_x := frame_x + frame_padding
	row_y := title_y + title_size + 20
	row_w := frame_w - frame_padding * 2

	for i := 0; i < len(menu_prompt_file.options); i += 1 {
		y := row_y + f32(i) * row_h
		is_selected := i == menu_prompt_file.selected

		if is_selected {
			k2.draw_rect({row_x, y - 6, row_w, row_h}, MENU_PROMPT_ITEM_SELECTED_BG)
			k2.draw_text(
				menu_prompt_file.options[i],
				{row_x + 14, y},
				item_size,
				MENU_PROMPT_ITEM_SELECTED_FG,
			)
		} else {
			k2.draw_text(
				menu_prompt_file.options[i],
				{row_x + 14, y},
				item_size,
				MENU_PROMPT_ITEM_COLOR,
			)
		}
	}
}
