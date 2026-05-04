package karl2d_game

import k2 "../../karl2d"

// fake view to control audio
AUDIO_VIEW := View {
	Open    = open_view,
	Close   = close_view,
	Control = control_view,
	Render  = render_view,
}

game_music: k2.Audio_Stream

MUSIC_FILE :: "../assets/ab.ogg"
MUSIC_FILE2 :: "./assets/ab.ogg"

@(private = "file")
open_view :: proc() {
	when ODIN_OS == .JS {
		// You could do this on non-JS (web) as well, I just try both so we get test coverage of
		// these different modes of operation.
		game_music = k2.load_audio_stream_from_bytes(#load(MUSIC_FILE))
	} else {
		game_music = k2.load_audio_stream_from_file(MUSIC_FILE2)
	}
	k2.set_audio_stream_loop(game_music, true)
	k2.play_audio_stream(game_music)
	// assert(game_music != nil)
}

@(private = "file")
control_view :: proc() -> bool {
	// TODO: mute music control
	// if k2.key_went_down(.Home) {
	// 	k2.play_audio_stream(game_music)
	// }

	// if k2.key_went_down(.End) {
	// 	k2.stop_audio_stream(game_music)
	// }
	return true
}

@(private = "file")
render_view :: proc() {
	k2.update_audio_stream(game_music)
}

@(private = "file")
close_view :: proc() {
	k2.destroy_audio_stream(game_music)
}
