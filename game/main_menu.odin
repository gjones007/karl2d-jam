package karl2d_game


//TODO: add selectors for different game modes (arena, mine, etc)
new_game :: proc(new_map: GameMaps) {
	selected_map = new_map
	trace("Starting new game")
	pop_all_views()
	player_init()
	push_view(&GAME_VIEW)
}

options_menu :: proc() {
	options_menu := []string{"Sounds", "Exit Menu"}

	options_menu_prompt_select_callback :: proc(index: int) {
		switch index {
		case 0:
			exit_menu()
		case 1:
			exit_menu()
		}
	}

	options_menu_callbacks := options_menu_prompt_select_callback

	open_menu_prompt("Main Menu", options_menu, options_menu_callbacks, nil)
}

exit_menu :: proc() {
	// pop_view()
}

init_main_menu :: proc() {
	main_menu := []string{"Arena", "The Cave", "Options", "Exit Menu"}

	main_menu_prompt_select_callback :: proc(index: int) {
		switch index {
		case 0:
			new_game(.Arena)
		case 1:
			new_game(.Cave)
		case 2:
			options_menu()
		case 3:
			exit_menu()
		}
	}

	main_menu_callbacks := main_menu_prompt_select_callback

	open_menu_prompt("Main Menu", main_menu, main_menu_callbacks, nil)
}
