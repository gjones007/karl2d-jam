package karl2d_game

import k2 "../../karl2d"

menu_prompt_select_callback :: proc(index: int)
menu_prompt_cancel_callback :: proc()

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
	if is_input_active(.INPUT_UI_CANCEL) || is_input_active(.INPUT_UI_TOGGLE_MAINMENU) {
		pop_view()
		if menu_prompt_file.onCancel != nil {
			menu_prompt_file.onCancel()
		}
	}

	if is_input_active(.INPUT_UI_UP) && menu_prompt_file.selected > 0 {
		menu_prompt_file.selected -= 1
	}

	if is_input_active(.INPUT_UI_DOWN) &&
	   menu_prompt_file.selected < len(menu_prompt_file.options) - 1 {
		menu_prompt_file.selected += 1
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

	frame_w := UI_MENU_FRAME_WIDTH
	frame_padding := UI_FRAME_PADDING
	title_size := UI_TITLE_SIZE
	item_size := UI_TEXT_SIZE
	row_h := item_size + 16
	frame_h :=
		frame_padding +
		title_size +
		UI_TITLE_TO_TEXT_GAP +
		f32(len(menu_prompt_file.options)) * row_h +
		frame_padding

	frame_x, frame_y := ui_draw_modal_frame(frame_w, frame_h)

	title_x := frame_x + frame_padding
	title_y := frame_y + frame_padding
	k2.draw_text(menu_prompt_file.title, {title_x, title_y}, title_size, TITLE_COLOR)

	row_x := frame_x + frame_padding
	row_y := title_y + title_size + UI_TITLE_TO_TEXT_GAP
	row_w := frame_w - frame_padding * 2

	for i := 0; i < len(menu_prompt_file.options); i += 1 {
		y := row_y + f32(i) * row_h
		is_selected := i == menu_prompt_file.selected

		if is_selected {
			k2.draw_rect({row_x, y - 6, row_w, row_h}, ITEM_SELECTED_BG)
			k2.draw_text(menu_prompt_file.options[i], {row_x + 14, y}, item_size, ITEM_SELECTED_FG)
		} else {
			k2.draw_text(menu_prompt_file.options[i], {row_x + 14, y}, item_size, ITEM_COLOR)
		}
	}
}
