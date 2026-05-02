package karl2d_game

// import "core:log"
import k2 "../../karl2d"

main :: proc() {
	init()
	for step() {}
	shutdown()
}

init :: proc() {
	when ODIN_OS != .JS {
		context.logger = init_logger()
	}

	k2.init(1000, 636, "Karl2D Game Demo")

	load_default_input_config()
	init_npc_prefabs()
	sounds_init()
	push_view(&GAME_VIEW)
	init_main_menu()
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
	k2.shutdown()
	when ODIN_OS != .JS {
		delete_logger(context.logger)
	}
}
