#+build !js
package karl2d_game

import k2 "../../karl2d"
import "core:fmt"
import "core:math/rand"
import "core:strings"

@(private = "file")
sb: strings.Builder

// another fake view to control game mechanics
GAME_CONTROL_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

@(private = "file")
open_view :: proc() {
	// we are controlling the game view, so it must be available
	if !is_view_open(&GAME_VIEW) do pop_view()
	sb = strings.builder_make()
}

@(private = "file")
control_view :: proc() -> bool {
	frame_dt := k2.get_frame_time()

	if k2.key_went_down(.Page_Up) {
		player.max_speed += 10
	}
	if k2.key_went_down(.Page_Down) {
		player.max_speed -= 10
	}
	if k2.key_went_down(.F2) {
		player.specials ~= {.IMMORTAL}
	}
	if k2.key_went_down(.F3) {
		add_npc_from_prefabs(player.x, player.y, rand.choice_enum(NPCPrefab))
	}

	return true
}

@(private = "file")
render_view :: proc() {
	k2.set_camera(ui_camera)
	k2.update_audio_stream(game_music)

	ui_width := k2.get_screen_size().x / 2

	fmt.sbprintf(&sb, "Player Speed: %.1fs %v\n", player.max_speed, player.specials)

	k2.draw_text(strings.to_string(sb), {ui_width / 2, 48}, UI_TEXT_SIZE, TEXT_COLOR)

	strings.builder_reset(&sb)
}

@(private = "file")
close_view :: proc() {
	strings.builder_destroy(&sb)
}
