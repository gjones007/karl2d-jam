package karl2d_game

import k2 "../../karl2d"
import "core:strings"

message_callback :: proc()

MESSAGE_DEFAULT_DISMISS :: "Ok"

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

	return true
}

@(private = "file")
render_view :: proc() {
	k2.set_camera(nil)

	screen := k2.get_screen_size()

	frame_w := f32(760)
	frame_padding := f32(24)
	title_size: f32 = 14
	text_size: f32 = 13
	button_size: f32 = 18

	message_chars_per_line := 44
	message_lines := make([dynamic]string, context.temp_allocator)
	defer delete(message_lines)

	msg := MessagePrompt.promptMessageText
	for start := 0; start < len(msg); start += message_chars_per_line {
		end := start + message_chars_per_line
		if end > len(msg) {
			end = len(msg)
		}
		append(&message_lines, strings.trim_space(msg[start:end]))
	}
	if len(message_lines) == 0 {
		append(&message_lines, "")
	}

	line_height := text_size + 10
	message_block_h := f32(len(message_lines)) * line_height + 8
	button_h := f32(56)
	frame_h := frame_padding + title_size + 18 + message_block_h + 26 + button_h + frame_padding

	frame_x := (screen.x - frame_w) * 0.5
	frame_y := (screen.y - frame_h) * 0.5

	// Dim background behind modal.
	k2.draw_rect({0, 0, screen.x, screen.y}, OVERLAY_COLOR)

	// Frame + border.
	k2.draw_rect({frame_x - 2, frame_y - 2, frame_w + 4, frame_h + 4}, FRAME_BORDER_COLOR)
	k2.draw_rect({frame_x, frame_y, frame_w, frame_h}, FRAME_COLOR)

	title_x := frame_x + frame_padding
	title_y := frame_y + frame_padding
	k2.draw_text(MessagePrompt.promptTitleText, {title_x, title_y}, title_size, TITLE_COLOR)

	msg_x := frame_x + frame_padding
	msg_y := title_y + title_size + 18
	for i := 0; i < len(message_lines); i += 1 {
		y := msg_y + f32(i) * line_height
		k2.draw_text(message_lines[i], {msg_x, y}, text_size, TEXT_COLOR)
	}

	button_y := frame_y + frame_h - frame_padding - button_h
	button_w := f32(180)
	button_x := frame_x + (frame_w - button_w) * 0.5

	k2.draw_rect({button_x, button_y, button_w, button_h}, ITEM_SELECTED_FG)

	label_inset := f32(16)
	k2.draw_text(
		MessagePrompt.promptDismissText,
		{button_x + label_inset, button_y + 14},
		button_size,
		ITEM_SELECTED_BG,
	)
}
