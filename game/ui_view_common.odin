package karl2d_game

import k2 "../../karl2d"
import "core:strings"

// Draw a centered modal frame with shared theme colors and return its top-left position.
ui_draw_modal_frame :: proc(frame_w, frame_h: f32) -> (frame_x, frame_y: f32) {
	screen := k2.get_screen_size()
	frame_x = (screen.x - frame_w) * 0.5
	frame_y = (screen.y - frame_h) * 0.5

	k2.draw_rect({0, 0, screen.x, screen.y}, OVERLAY_COLOR)
	k2.draw_rect({frame_x - 2, frame_y - 2, frame_w + 4, frame_h + 4}, FRAME_BORDER_COLOR)
	k2.draw_rect({frame_x, frame_y, frame_w, frame_h}, FRAME_COLOR)
	return
}

ui_split_message_lines :: proc(msg: string, chars_per_line: int) -> [dynamic]string {
	lines := make([dynamic]string, context.temp_allocator)

	for start := 0; start < len(msg); start += chars_per_line {
		end := start + chars_per_line
		if end > len(msg) {
			end = len(msg)
		}
		append(&lines, strings.trim_space(msg[start:end]))
	}

	if len(lines) == 0 {
		append(&lines, "")
	}

	return lines
}
