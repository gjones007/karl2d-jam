package karl2d_game

import k2 "../../karl2d"

bool_prompt_callback :: proc()

BoolPromptCursor :: enum {
	UNSELECTED,
	ACCEPT,
	DECLINE,
}

DEFAULT_ACCEPT :: "Accept"
DEFAULT_DECLINE :: "Decline"

BOOL_PROMPT_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

@(private = "file")
BoolPromptFile: struct {
	promptIsOpen:      bool,
	promptOnAccept:    bool_prompt_callback,
	promptOnDecline:   bool_prompt_callback,
	promptTitleText:   string,
	promptMessageText: string,
	promptAcceptText:  string,
	promptDeclineText: string,
	promptSelection:   BoolPromptCursor,
} = {}

init_bool_prompt :: proc(
	onAccept: bool_prompt_callback,
	onDecline: bool_prompt_callback,
	titleText: string,
	messageText: string,
	acceptText: string,
	declineText: string,
) {
	if (BoolPromptFile.promptIsOpen) {
		error("PROMPT: BoolPrompt is already open")
		return
	}

	BoolPromptFile.promptIsOpen = true
	BoolPromptFile.promptOnAccept = onAccept
	BoolPromptFile.promptOnDecline = onDecline
	BoolPromptFile.promptTitleText = titleText
	BoolPromptFile.promptMessageText = messageText
	BoolPromptFile.promptAcceptText = len(acceptText) > 0 ? acceptText : DEFAULT_ACCEPT
	BoolPromptFile.promptDeclineText = len(declineText) > 0 ? declineText : DEFAULT_DECLINE

	push_view(&BOOL_PROMPT_VIEW)
}

@(private = "file")
open_view :: proc() {
	BoolPromptFile.promptSelection = .UNSELECTED
}

@(private = "file")
close_view :: proc() {
	BoolPromptFile.promptIsOpen = false
}

@(private = "file")
control_view :: proc() -> bool {
	if (is_input_active(.INPUT_UI_CANCEL)) {
		pop_view()

		if BoolPromptFile.promptOnDecline != nil {
			BoolPromptFile.promptOnDecline()
		}
	} else if (is_input_active(.INPUT_UI_SUBMIT)) {
		if (BoolPromptFile.promptSelection == .ACCEPT) {
			pop_view()

			if BoolPromptFile.promptOnAccept != nil {
				BoolPromptFile.promptOnAccept()
			}
		} else if (BoolPromptFile.promptSelection == .DECLINE) {
			pop_view()

			if BoolPromptFile.promptOnDecline != nil {
				BoolPromptFile.promptOnDecline()
			}
		}
	} else if (is_input_active(.INPUT_UI_LEFT)) {
		if len(BoolPromptFile.promptAcceptText) > 0 {
			BoolPromptFile.promptSelection = .ACCEPT
		}
	} else if (is_input_active(.INPUT_UI_RIGHT)) {
		if len(BoolPromptFile.promptDeclineText) > 0 {
			BoolPromptFile.promptSelection = .DECLINE
		}
	} else if (is_input_active(.INPUT_UI_UP)) {
		BoolPromptFile.promptSelection = .UNSELECTED
	}
	return true
}

@(private = "file")
render_view :: proc() {
	k2.set_camera(nil)

	frame_w := UI_MODAL_FRAME_WIDTH
	frame_padding := UI_FRAME_PADDING
	title_size := UI_TITLE_SIZE
	text_size := UI_TEXT_SIZE
	button_size := UI_BUTTON_TEXT_SIZE

	message_lines := ui_split_message_lines(
		BoolPromptFile.promptMessageText,
		UI_MESSAGE_CHARS_PER_LINE,
	)
	defer delete(message_lines)

	line_height := text_size + UI_LINE_GAP
	message_block_h := f32(len(message_lines)) * line_height + 8
	button_h := UI_BUTTON_HEIGHT
	frame_h :=
		frame_padding +
		title_size +
		UI_TITLE_TO_TEXT_GAP +
		message_block_h +
		UI_TEXT_TO_BUTTON_GAP +
		button_h +
		frame_padding

	frame_x, frame_y := ui_draw_modal_frame(frame_w, frame_h)

	title_x := frame_x + frame_padding
	title_y := frame_y + frame_padding
	k2.draw_text(BoolPromptFile.promptTitleText, {title_x, title_y}, title_size, TITLE_COLOR)

	msg_x := frame_x + frame_padding
	msg_y := title_y + title_size + UI_TITLE_TO_TEXT_GAP
	for i := 0; i < len(message_lines); i += 1 {
		y := msg_y + f32(i) * line_height
		k2.draw_text(message_lines[i], {msg_x, y}, text_size, TEXT_COLOR)
	}

	button_y := frame_y + frame_h - frame_padding - button_h
	button_w := UI_BUTTON_WIDTH
	button_gap := UI_BUTTON_GAP
	total_buttons_w := button_w * 2 + button_gap
	button_start_x := frame_x + (frame_w - total_buttons_w) * 0.5

	accept_selected := BoolPromptFile.promptSelection == .ACCEPT
	decline_selected := BoolPromptFile.promptSelection == .DECLINE

	accept_bg := accept_selected ? ITEM_SELECTED_FG : ITEM_SELECTED_BG
	accept_fg := accept_selected ? ITEM_SELECTED_BG : ITEM_SELECTED_FG
	decline_bg := decline_selected ? ITEM_SELECTED_FG : ITEM_SELECTED_BG
	decline_fg := decline_selected ? ITEM_SELECTED_BG : ITEM_SELECTED_FG

	accept_x := button_start_x
	decline_x := button_start_x + button_w + button_gap

	k2.draw_rect({accept_x, button_y, button_w, button_h}, accept_bg)
	k2.draw_rect({decline_x, button_y, button_w, button_h}, decline_bg)

	label_inset := UI_BUTTON_LABEL_INSET_X
	k2.draw_text(
		BoolPromptFile.promptAcceptText,
		{accept_x + label_inset, button_y + UI_BUTTON_LABEL_INSET_Y},
		button_size,
		accept_fg,
	)
	k2.draw_text(
		BoolPromptFile.promptDeclineText,
		{decline_x + label_inset, button_y + UI_BUTTON_LABEL_INSET_Y},
		button_size,
		decline_fg,
	)
}
