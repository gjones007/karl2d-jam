package karl2d_game

new_game :: proc(new_map: GameMaps) {
	selected_map = new_map
	set_view(&GAME_VIEW)
	if new_map == .Cave {
		push_view(&AUDIO_VIEW)
	}
	if new_map == .Arena {
		push_view(&ARENA_VIEW)
	}
}

exit_menu :: proc() {}

options_menu :: proc() {
	options_menu := []string{"Sounds", "Exit Menu"}

	options_menu_prompt_callback :: proc(index: int) {
		switch index {
		case 0:
			exit_menu()
		case 1:
			exit_menu()
		}
	}

	open_menu_prompt("Main Menu", options_menu, options_menu_prompt_callback, nil)
}

// TODO: fix this
temp_callback_map: GameMaps
new_game_bool_prompt_callback :: proc(new_map: GameMaps) {
	temp_callback_map = new_map
	if is_view_open(&GAME_VIEW) {
		init_bool_prompt(proc() {
				new_game(temp_callback_map)
			}, proc() {
				pop_view()
			}, "Start New Game", "Are you sure you want to start a new game? Your current progress will be lost.", "Yes", "No")
		return
	} else {
		new_game(temp_callback_map)
	}
}

init_main_menu :: proc() {
	main_menu := []string{"The Cave", "Arena", "Options", "Exit Menu"}

	main_menu_prompt_callback :: proc(index: int) {
		switch index {
		case 0:
			new_game_bool_prompt_callback(.Cave)
		case 1:
			new_game_bool_prompt_callback(.Arena)
		case 2:
			options_menu()
		case 3:
			exit_menu()
		}
	}

	open_menu_prompt(
		"Main Menu",
		!is_view_open(&TITLE_GRAPHIC_VIEW) ? main_menu : main_menu[:len(main_menu) - 1],
		main_menu_prompt_callback,
		nil,
	)
}
