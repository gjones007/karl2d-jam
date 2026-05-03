package karl2d_game

import k2 "../../karl2d"

TITLE_GRAPHIC_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

@(private = "file")
camera: k2.Camera
@(private = "file")
current_item_index: int

@(private = "file")
open_view :: proc() {

}

@(private = "file")
control_view :: proc() -> bool {
	// should never get here, if menu pops
	init_main_menu()
	return false
}

@(private = "file")
close_view :: proc() {
	camera = k2.Camera {
		// offset = k2.get_screen_size() / 2,
		// zoom   = 3,
	}
}

@(private = "file")
render_view :: proc() {
	k2.clear(k2.ORANGE)
	k2.set_camera(camera)
	screen := k2.get_screen_size()
	k2.draw_text("TITLE SCREEN", {screen.x / 2, 20}, 40, k2.WHITE)
}
