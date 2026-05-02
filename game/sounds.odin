package karl2d_game

import k2 "../../karl2d"
import rfx "../rfxgen"
import "core:slice"

SoundsEnum :: enum {
	None,
	PlayerWalk,
	// PlayerJump,
	// PlayerLand,
	// PlayerAttack,
	// EnemyHit,
	// EnemyDeath,
	// ItemPickup,
	// BackgroundMusic,
}

sounds: [SoundsEnum]k2.Sound

rfxgen :: proc(s: SoundsEnum) {
	params := rfx.GenBlipSelect()
	returned_count: u32 = 0
	data := rfx.GenerateWave(&params, &returned_count)
	bytes := slice.bytes_from_ptr(data, auto_cast returned_count)
	buf := k2.load_audio_buffer_from_bytes_raw(bytes, .Float, 44100, .Mono)
	sounds[s] = k2.create_sound_from_audio_buffer(buf)
}

play_sound :: proc(s: SoundsEnum) {
	k2.play_sound(sounds[s])
}

sounds_init :: proc() {
	rfxgen(.PlayerWalk)
	// rfxgen(.PlayerJump)
	// rfxgen(.PlayerLand)
	// rfxgen(.PlayerAttack)
	// rfxgen(.EnemyHit)
	// rfxgen(.EnemyDeath)
	// rfxgen(.ItemPickup)
	// rfxgen(.BackgroundMusic)
}
