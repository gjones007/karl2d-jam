package karl2d_game

import k2 "../../karl2d"
import "core:mem"
import "core:fmt"

// fake view to control audio
AUDIO_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

game_music: k2.Audio_Stream

MUSIC_FILE :: "../assets/ab.ogg"
HAS_MUSIC :: #exists(MUSIC_FILE)

@(private = "file")
open_view :: proc() {
		when ODIN_OS == .JS {
			// You could do this on non-JS (web) as well, I just try both so we get test coverage of
			// these different modes of operation.
			game_music = k2.load_audio_stream_from_bytes(#load(MUSIC_FILE))
		} else {
			game_music = k2.load_audio_stream_from_file(MUSIC_FILE)
		}
		k2.set_audio_stream_loop(game_music, true)
		k2.play_audio_stream(game_music)
		// assert(game_music != nil)
}

@(private = "file")
control_view :: proc() -> bool {
	if k2.key_went_down(.Home) {
		k2.play_audio_stream(game_music)
	}

	if k2.key_went_down(.End) {
		k2.stop_audio_stream(game_music)
	}
	return true
}

@(private = "file")
render_view :: proc() {
	k2.update_audio_stream(game_music)
	// k2.set_camera(nil)
	// k2.draw_text(
	// 	"muic is playing! (home to play, end to stop)",
	// 	{20, 20},
	// 	40,
	// 	k2.RED,
	// )
}

@(private = "file")
close_view :: proc() {
	k2.destroy_audio_stream(game_music)
}

