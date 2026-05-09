package karl2d_game

import k2 "../../karl2d"

message_callback :: proc()

MESSAGE_DEFAULT_DISMISS :: "Ok"
MESSAGE_DISENGAGE_RADIUS :: 25.0

MESSAGE_PROMPT_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

@(private = "file")
MessagePrompt: struct {
	promptIsOpen:      bool,
	promptOnDismiss:   message_callback,
	promptTitleText:   string,
	promptMessageText: string,
	promptDismissText: string,
	promptDidDismiss:  bool,
	disenageCenter:    k2.Vec2,
} = {}

init_message_prompt :: proc(
	onDismiss: message_callback,
	titleText: string,
	messageText: string,
	dismissText: string,
) {
	if (MessagePrompt.promptIsOpen) {
		error("PROMPT: MessagePrompt is already open")
		return
	}

	MessagePrompt.promptIsOpen = true
	MessagePrompt.promptDidDismiss = false
	MessagePrompt.promptOnDismiss = onDismiss
	MessagePrompt.promptTitleText = titleText
	MessagePrompt.promptMessageText = messageText
	MessagePrompt.promptDismissText = len(dismissText) > 0 ? dismissText : MESSAGE_DEFAULT_DISMISS
	MessagePrompt.disenageCenter = k2.Vec2{player.x, player.y}

	push_view(&MESSAGE_PROMPT_VIEW)
}

@(private = "file")
open_view :: proc() {
	MessagePrompt.promptDidDismiss = false
}

@(private = "file")
close_view :: proc() {
	MessagePrompt.promptIsOpen = false

	if !MessagePrompt.promptDidDismiss {
		MessagePrompt.promptDidDismiss = true

		if MessagePrompt.promptOnDismiss != nil {
			MessagePrompt.promptOnDismiss()
		}
	}
}

@(private = "file")
control_view :: proc() -> bool {
	if (is_input_active(.INPUT_UI_CANCEL)) {
		pop_view()
	} else if (is_input_active(.INPUT_UI_SUBMIT)) {
		pop_view()
	}

	if distance(
		   player.x,
		   player.y,
		   MessagePrompt.disenageCenter.x,
		   MessagePrompt.disenageCenter.y,
	   ) >
	   MESSAGE_DISENGAGE_RADIUS {
		pop_view()
	}

	return true
}

@(private = "file")
render_view :: proc() {
	k2.set_camera(ui_camera)

	frame_w := UI_MODAL_FRAME_WIDTH
	frame_padding := UI_FRAME_PADDING
	title_size := UI_TITLE_SIZE
	text_size := UI_TEXT_SIZE
	button_size := UI_BUTTON_TEXT_SIZE

	message_lines := ui_split_message_lines(
		MessagePrompt.promptMessageText,
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
	k2.draw_text(MessagePrompt.promptTitleText, {title_x, title_y}, title_size, TITLE_COLOR)

	msg_x := frame_x + frame_padding
	msg_y := title_y + title_size + UI_TITLE_TO_TEXT_GAP
	for i := 0; i < len(message_lines); i += 1 {
		y := msg_y + f32(i) * line_height
		k2.draw_text(message_lines[i], {msg_x, y}, text_size, TEXT_COLOR)
	}

	button_y := frame_y + frame_h - frame_padding - button_h
	button_w := UI_BUTTON_WIDTH
	button_x := frame_x + (frame_w - button_w) * 0.5

	k2.draw_rect({button_x, button_y, button_w, button_h}, ITEM_SELECTED_FG)

	label_inset := UI_BUTTON_LABEL_INSET_X
	k2.draw_text(
		MessagePrompt.promptDismissText,
		{button_x + label_inset, button_y + UI_BUTTON_LABEL_INSET_Y},
		button_size,
		ITEM_SELECTED_BG,
	)
}
