package karl2d_game

import k2 "../../karl2d"

main :: proc() {
	init()
	for step() {}
	shutdown()
}

init :: proc() {
	k2.init(1000, 636, "First Quest")

	load_default_input_config()
	sounds_init()
	set_view(&TITLE_GRAPHIC_VIEW)
}

step :: proc() -> bool {
	if !k2.update() {
		return false
	}

	update_inputs()

	if activeViews.len == 0 {
		init_main_menu()
	}
	control_views()

	k2.clear(k2.BLACK)
	render_views()
	k2.present()
	free_all(context.temp_allocator)
	return true
}

shutdown :: proc() {
	pop_all_views()
	sounds_shutdown()
	k2.shutdown()
}
