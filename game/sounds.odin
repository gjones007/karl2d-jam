package karl2d_game

import k2 "../../karl2d"
import rfx "../rfxgen"
import "core:slice"

SoundsEnum :: enum {
	None,
	PlayerHurt,
	PlayerAttack,
	EnemyHit,
	EnemyDeath,
	ItemPickup,
	EnemySpawn,
}

sounds: [SoundsEnum]k2.Sound

rfxgen :: proc(s: SoundsEnum) {
	params: rfx.WaveParams
	if s == .EnemySpawn {
		params = rfx.GenExplosion()
	} else if s == .ItemPickup {
		params = rfx.GenPickupCoin()
	} else if s == .EnemyHit || s == .EnemyDeath || s == .PlayerHurt {
		params = rfx.GenHitHurt()
	} else {
		params = rfx.GenBlipSelect()
	}
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
	rfxgen(.PlayerAttack)
	rfxgen(.PlayerHurt)
	rfxgen(.EnemyHit)
	rfxgen(.EnemyDeath)
	rfxgen(.ItemPickup)
	rfxgen(.EnemySpawn)
}

sounds_shutdown :: proc() {
	for s in SoundsEnum {
		k2.destroy_sound(sounds[s])
	}
}
