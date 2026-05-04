package karl2d_game

import k2 "../../karl2d"

TITLE_GRAPHIC_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

TITLE :: "First Quest"

@(private = "file")
text_measured: k2.Vec2

@(private = "file")
open_view :: proc() {
	text_measured = k2.measure_text(TITLE, 40) / 2
	if !is_view_open(&MENU_PROMPT_VIEW) do init_main_menu()
}

@(private = "file")
control_view :: proc() -> bool {
	if !is_view_open(&MENU_PROMPT_VIEW) do init_main_menu()
	return false
}

@(private = "file")
close_view :: proc() {
}

@(private = "file")
render_view :: proc() {
	k2.clear(k2.ORANGE)
	k2.set_camera(nil)
	screen := k2.get_screen_size()
	k2.draw_text(
		TITLE,
		{screen.x / 2 - text_measured.x, screen.y / 4 - text_measured.y},
		40,
		k2.GREEN,
	)
}
