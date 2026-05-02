package rfxgen
/*******************************************************************************************
 *
 *   rfxgen - A simple and easy-to-use sounds generator (based on Tomas Petterson sfxr)
 *
 *   DEVELOPERS:
 *       Ramon Santamaria (@raysan5): Developer, supervisor, updater and maintainer.
 *       Rob Loach (@RobLoach): Port generator to single-file header-only library (Oct.2022)
 *
 *
 *   LICENSE: zlib/libpng
 *
 *   Copyright (c) 2014-2022 raylib technologies (@raylibtech) / Ramon Santamaria (@raysan5)
 *
 *   This software is provided "as-is", without any express or implied warranty. In no event
 *   will the authors be held liable for any damages arising from the use of this software.
 *
 *   Permission is granted to anyone to use this software for any purpose, including commercial
 *   applications, and to alter it and redistribute it freely, subject to the following restrictions:
 *
 *     1. The origin of this software must not be misrepresented; you must not claim that you
 *     wrote the original software. If you use this software in a product, an acknowledgment
 *     in the product documentation would be appreciated but is not required.
 *
 *     2. Altered source versions must be plainly marked as such, and must not be misrepresented
 *     as being the original software.
 *
 *     3. This notice may not be removed or altered from any source distribution.
 *
 **********************************************************************************************/

import "base:runtime"
import "core:math"
import "core:math/rand"
// import "core:os"

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
_DEFAULT_RFXGEN_GEN_SAMPLE_RATE :: #config(RFXGEN_GEN_SAMPLE_RATE, 44100) // Generation sample rate
_DEFAULT_RFXGEN_GEN_SAMPLE_SIZE :: #config(RFXGEN_GEN_SAMPLE_SIZE, 32)    // Bit size of generated waves (32 bit -> f32)
_DEFAULT_RFXGEN_GEN_CHANNELS    :: #config(RFXGEN_GEN_CHANNELS, 1)        // Channels for generated waves (only 1 - MONO)

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
// Wave type enum
WaveType :: enum i32 {
    Square,
    Sawtooth,
    Sine,
    Noise,
}

// Wave parameters type (96 bytes)
WaveParams :: struct #packed {
    // Random seed used to generate the wave
    randSeed:            i32,

    // Wave type (square, sawtooth, sine, noise)
    waveTypeValue:       WaveType,

    // Wave envelope parameters
    attackTimeValue:     f32,
    sustainTimeValue:    f32,
    sustainPunchValue:   f32,
    decayTimeValue:      f32,

    // Frequency parameters
    startFrequencyValue: f32,
    minFrequencyValue:   f32,
    slideValue:          f32,
    deltaSlideValue:     f32,
    vibratoDepthValue:   f32,
    vibratoSpeedValue:   f32,
    // f32 vibratoPhaseDelayValue

    // Tone change parameters
    changeAmountValue:   f32,
    changeSpeedValue:    f32,

    // Square wave parameters
    squareDutyValue:     f32,
    dutySweepValue:      f32,

    // Repeat parameters
    repeatSpeedValue:    f32,

    // Phaser parameters
    phaserOffsetValue:   f32,
    phaserSweepValue:    f32,

    // Filter parameters
    lpfCutoffValue:      f32,
    lpfCutoffSweepValue: f32,
    lpfResonanceValue:   f32,
    hpfCutoffValue:      f32,
    hpfCutoffSweepValue: f32,
}

/***********************************************************************************
 *
 *   RFXGEN IMPLEMENTATION
 *
 ************************************************************************************/

rfxgen_srand :: proc(seed: i32) {
    rand.reset(auto_cast seed)
}

rfxgen_rand :: proc(min, max: i32) -> i32 {
    return (rand.int31_max(max) % (max - min) + 1) + min
}

rfxgen_rand01 :: proc() -> bool {
    return rand.float32_range(0, 100) > 50
}

rfxgen_randf :: proc(range: f32) -> f32 {
    return rand.float32_range(0, range)
}

//--------------------------------------------------------------------------------------------
// Load/Save/Export functions
//--------------------------------------------------------------------------------------------

// Reset wave parameters
ResetWaveParams :: proc(params: ^WaveParams) {
    // NOTE: Random seed is set to a random value
    params.randSeed = auto_cast rand.int31()
    rfxgen_srand(params.randSeed)

    // Wave type
    params.waveTypeValue = .Square

    // Wave envelope params
    params.attackTimeValue = 0.0
    params.sustainTimeValue = 0.3
    params.sustainPunchValue = 0.0
    params.decayTimeValue = 0.4

    // Frequency params
    params.startFrequencyValue = 0.3
    params.minFrequencyValue = 0.0
    params.slideValue = 0.0
    params.deltaSlideValue = 0.0
    params.vibratoDepthValue = 0.0
    params.vibratoSpeedValue = 0.0
    // params.vibratoPhaseDelay = 0.0

    // Tone change params
    params.changeAmountValue = 0.0
    params.changeSpeedValue = 0.0

    // Square wave params
    params.squareDutyValue = 0.0
    params.dutySweepValue = 0.0

    // Repeat params
    params.repeatSpeedValue = 0.0

    // Phaser params
    params.phaserOffsetValue = 0.0
    params.phaserSweepValue = 0.0

    // Filter params
    params.lpfCutoffValue = 1.0
    params.lpfCutoffSweepValue = 0.0
    params.lpfResonanceValue = 0.0
    params.hpfCutoffValue = 0.0
    params.hpfCutoffSweepValue = 0.0
}

// Generates new wave from wave parameters
// NOTE: By default wave is generated as 44100Hz, 32bit f32, mono
GenerateWave :: proc(params: ^WaveParams, frameCount: ^u32) -> [^]f32 {
    // Max length for generation buffer: 10 seconds
    RFXGEN_MAX_GEN_BUFFER_LENGTH :: 10

    // Initialize seed if required
    if (params.randSeed != 0) do rfxgen_srand(params.randSeed)

    // Configuration parameters for generation
    // NOTE: Those parameters are calculated from selected values
    phase: i32 = 0
    fperiod: f64 = 0.0
    fmaxperiod: f64 = 0.0
    fslide: f64 = 0.0
    fdslide: f64 = 0.0
    period: i32 = 0
    squareDuty: f32 = 0.0
    squareSlide: f32 = 0.0
    envelopeStage: i32 = 0
    envelopeTime: i32 = 0
    envelopeLength := [3]i32{}
    envelopeVolume: f32 = 0.0
    fphase: f32 = 0.0
    fdphase: f32 = 0.0
    iphase: i32 = 0
    phaserBuffer := [1024]f32{}
    ipp: i32 = 0
    noiseBuffer := [32]f32{} // Required for noise wave, depends on random seed!
    fltp: f32 = 0.0
    fltdp: f32 = 0.0
    fltw: f32 = 0.0
    fltwd: f32 = 0.0
    fltdmp: f32 = 0.0
    fltphp: f32 = 0.0
    flthp: f32 = 0.0
    flthpd: f32 = 0.0
    vibratoPhase: f32 = 0.0
    vibratoSpeed: f32 = 0.0
    vibratoAmplitude: f32 = 0.0
    repeatTime: i32 = 0
    repeatLimit: i32 = 0
    arpeggioTime: i32 = 0
    arpeggioLimit: i32 = 0
    arpeggioModulation: f64 = 0.0

    // HACK: Security check to avoid crash (why?)
    if params.minFrequencyValue > params.startFrequencyValue do params.minFrequencyValue = params.startFrequencyValue
    if params.slideValue < params.deltaSlideValue do params.slideValue = params.deltaSlideValue
    // Reset sample parameters
    //----------------------------------------------------------------------------------------
    fperiod = 100.0 / f64(params.startFrequencyValue * params.startFrequencyValue + 0.001)
    period = i32(fperiod)
    // TODO: Check this, it should be 100000.000000 but is 99999.9952502551
    fmaxperiod = 100.0 / f64(f32(params.minFrequencyValue) * f32(params.minFrequencyValue) + f32(0.001))
    fslide = 1.0 - math.pow(f64(params.slideValue), 3.0) * 0.01
    fdslide = -math.pow(f64(params.deltaSlideValue), 3.0) * 0.000001
    squareDuty = 0.5 - params.squareDutyValue * 0.5
    squareSlide = -params.dutySweepValue * 0.00005

    if params.changeAmountValue >= 0.0 {
        arpeggioModulation = 1.0 - math.pow(f64(params.changeAmountValue), 2.0) * 0.9
    } else {
        arpeggioModulation = 1.0 + math.pow(f64(params.changeAmountValue), 2.0) * 10.0
    }

    arpeggioLimit = i32(math.pow(1.0 - params.changeSpeedValue, 2.0) * 20000 + 32)

    // WATCH OUT: f32 comparison
    if params.changeSpeedValue == 1.0 do arpeggioLimit = 0

    // Reset filter parameters
    fltw = math.pow(params.lpfCutoffValue, 3.0) * 0.1
    fltwd = 1.0 + params.lpfCutoffSweepValue * 0.0001
    fltdmp = 5.0 / (1.0 + math.pow(params.lpfResonanceValue, 2.0) * 20.0) * (0.01 + fltw)
    if fltdmp > 0.8 do fltdmp = 0.8
    flthp = math.pow(params.hpfCutoffValue, 2.0) * 0.1
    flthpd = 1.0 + params.hpfCutoffSweepValue * 0.0003

    // Reset vibrato
    vibratoSpeed = math.pow(params.vibratoSpeedValue, 2.0) * 0.01
    vibratoAmplitude = params.vibratoDepthValue * 0.5

    // Reset envelope
    envelopeLength[0] = i32(params.attackTimeValue * params.attackTimeValue * 100000.0)
    envelopeLength[1] = i32(params.sustainTimeValue * params.sustainTimeValue * 100000.0)
    envelopeLength[2] = i32(params.decayTimeValue * params.decayTimeValue * 100000.0)

    fphase = math.pow(params.phaserOffsetValue, 2.0) * 1020.0
    if params.phaserOffsetValue < 0.0 do fphase = -fphase

    // fmt.printfln("fphase: %f\n", fphase);

    fdphase = math.pow(params.phaserSweepValue, 2.0) * 1.0
    if params.phaserSweepValue < 0.0 do fdphase = -fdphase

    iphase = abs(i32(fphase))

    for i: i32 = 0; i < 32; i += 1 { noiseBuffer[i] = rfxgen_randf(2.0) - 1.0 }

    repeatLimit = i32(math.pow(1.0 - params.repeatSpeedValue, 2.0) * 20000 + 32)
    // fmt.println("repeatLimit: ", repeatLimit)

    if params.repeatSpeedValue == 0.0 do repeatLimit = 0
    //----------------------------------------------------------------------------------------

    // NOTE: We reserve enough space for up to 10 seconds of wave audio at given sample rate
    // By default we use f32 size samples, they are converted to desired sample size at the end
    // f32 *buffer = (f32 *)RFXGEN_CALLOC(RFXGEN_MAX_GEN_BUFFER_LENGTH * RFXGEN_GEN_SAMPLE_RATE, sizeof(f32))
    buffer: [^]f32 = make([^]f32, RFXGEN_MAX_GEN_BUFFER_LENGTH * _DEFAULT_RFXGEN_GEN_SAMPLE_RATE)
    generatingSample := true
    sampleCount: i32 = 0

    for i: i32 = 0; i < RFXGEN_MAX_GEN_BUFFER_LENGTH * _DEFAULT_RFXGEN_GEN_SAMPLE_RATE; i += 1 {
        if !generatingSample {
            sampleCount = i
            break
        }

        // Generate sample using selected parameters
        //------------------------------------------------------------------------------------
        repeatTime += 1

        if repeatLimit != 0 && (repeatTime >= repeatLimit) {
            // Reset sample parameters (only some of them)
            repeatTime = 0

            fperiod = 100.0 / f64(params.startFrequencyValue * params.startFrequencyValue + 0.001)
            period = i32(fperiod)
            fmaxperiod = 100.0 / f64(params.minFrequencyValue * params.minFrequencyValue + 0.001)
            fslide = 1.0 - math.pow(f64(params.slideValue), 3.0) * 0.01
            fdslide = -math.pow(f64(params.deltaSlideValue), 3.0) * 0.000001
            squareDuty = 0.5 - params.squareDutyValue * 0.5
            squareSlide = -params.dutySweepValue * 0.00005

            if params.changeAmountValue >= 0.0 {
                arpeggioModulation = 1.0 - math.pow(f64(params.changeAmountValue), 2.0) * 0.9
            } else {
                arpeggioModulation = 1.0 + math.pow(f64(params.changeAmountValue), 2.0) * 10.0
            }

            arpeggioTime = 0
            arpeggioLimit = i32(math.pow(1.0 - params.changeSpeedValue, 2.0) * 20000 + 32)

            // WATCH OUT: f32 comparison
            if (params.changeSpeedValue == 1.0) do arpeggioLimit = 0
        }

        // Frequency envelopes/arpeggios
        arpeggioTime += 1

        if arpeggioLimit != 0 && (arpeggioTime >= arpeggioLimit) {
            arpeggioLimit = 0
            fperiod *= arpeggioModulation
        }

        fslide += fdslide
        fperiod *= fslide

        if fperiod > fmaxperiod {
            fperiod = fmaxperiod

            if params.minFrequencyValue > 0.0 do generatingSample = false
        }

        rfperiod := f32(fperiod)

        if vibratoAmplitude > 0.0 {
            vibratoPhase += vibratoSpeed
            rfperiod = f32(fperiod * f64(1.0 + math.sin(vibratoPhase) * vibratoAmplitude))
        }

        period = i32(rfperiod)

        if period < 8 do period = 8

        squareDuty += squareSlide

        if squareDuty < 0.0 do squareDuty = 0.0
        if squareDuty > 0.5 do squareDuty = 0.5

        // Volume envelope
        envelopeTime += 1

        if envelopeTime > envelopeLength[envelopeStage] {
            envelopeTime = 0
            envelopeStage += 1

            if envelopeStage == 3 do generatingSample = false
        }

        if envelopeStage == 0 do envelopeVolume = f32(envelopeTime) / f32(envelopeLength[0])
        if envelopeStage == 1 do envelopeVolume = 1.0 + math.pow_f32(1.0 - f32(envelopeTime) / f32(envelopeLength[1]), 1.0) * 2.0 * params.sustainPunchValue
        if envelopeStage == 2 do envelopeVolume = 1.0 - f32(envelopeTime) / f32(envelopeLength[2])

        // Phaser step
        fphase += fdphase
        iphase = abs(i32(fphase))

        if iphase > 1023 do iphase = 1023

        // WATCH OUT!
        if flthpd != 0.0 {
            flthp *= flthpd
            if flthp < 0.00001 do flthp = 0.00001
            if flthp > 0.1 do flthp = 0.1
        }

        ssample: f32 = 0.0

        MAX_SUPERSAMPLING :: 8

        // Supersampling x8
        for si: i32 = 0; si < MAX_SUPERSAMPLING; si += 1 {
            sample: f32 = 0.0
            phase += 1

            if (phase >= period) {
                // phase = 0
                phase %= period

                if params.waveTypeValue == .Noise {
                    for j: i32 = 0; j < 32; j += 1 do noiseBuffer[j] = rfxgen_randf(2.0) - 1.0
                }
            }

            // base waveform
            fp := f32(phase) / f32(period)

            switch (params.waveTypeValue) {
            case .Square:
                {
                    if fp < squareDuty {
                        sample = 0.5
                    } else {
                        sample = -0.5
                    }
                }
            case .Sawtooth:
                sample = 1.0 - fp * 2
            case .Sine:
                sample = math.sin(fp * 2 * math.PI)
            case .Noise:
                sample = noiseBuffer[phase * 32 / period]
            }

            // LP filter
            pp: f32 = fltp
            fltw *= fltwd

            if fltw < 0.0 do fltw = 0.0
            if fltw > 0.1 do fltw = 0.1

            // WATCH OUT!
            if params.lpfCutoffValue != 1.0 {
                fltdp += (sample - fltp) * fltw
                fltdp -= fltdp * fltdmp
            } else {
                fltp = sample
                fltdp = 0.0
            }

            fltp += fltdp

            // HP filter
            fltphp += fltp - pp
            fltphp -= fltphp * flthp
            sample = fltphp

            // Phaser
            phaserBuffer[ipp & 1023] = sample
            sample += phaserBuffer[(ipp - iphase + 1024) & 1023]
            ipp = (ipp + 1) & 1023

            // Final accumulation and envelope application
            ssample += sample * envelopeVolume
        }

        SAMPLE_SCALE_COEFICIENT :: 0.2 // NOTE: Used to scale sample value to [-1..1]

        ssample = (ssample / MAX_SUPERSAMPLING) * SAMPLE_SCALE_COEFICIENT
        //------------------------------------------------------------------------------------

        // Accumulate samples in the buffer
        if ssample > 1.0 do ssample = 1.0
        if ssample < -1.0 do ssample = -1.0

        buffer[i] = ssample
    }

    // NOTE: Wave data is generated by default as 32bit f32 data and 1 channel (mono)

    // TODO: check this
    // f32 *genWaveData = (f32 *)RFXGEN_CALLOC(sampleCount, sizeof(f32))
    // RFXGEN_MEMCPY(genWaveData, buffer, sampleCount * sizeof(f32))
    // RFXGEN_FREE(buffer)
    genWaveData:= make([^]f32, sampleCount)
    // runtime.mem_copy(genWaveData, buffer, int(sampleCount)*size_of(f32))
    runtime.mem_copy(genWaveData, buffer, int(sampleCount)*size_of(f32))
    free(buffer)

    // NOTE: Wave can be converted to desired format after generation

    frameCount^ = auto_cast sampleCount // By default generated wave only has 1 channel
    return genWaveData
}

WaveParamsOnDisk :: struct #packed {
    signature:        [4]byte,
    version:          u16,
    length:           u16,
    using parameters: WaveParams,
}

// LoadWaveParams :: proc(fileName: string) -> (WaveParams, bool) {
//     p := WaveParamsOnDisk{}
//     file, err := os.open(fileName, os.O_RDONLY)
//     if err != nil {
//         return p.parameters, false
//     }
//     read, read_err := os.read_ptr(file, &p, size_of(WaveParamsOnDisk))

//     if read_err != nil {
//         return p.parameters, false
//     }

//     if !((p.signature[0] == 'r') && (p.signature[1] == 'F') && (p.signature[2] == 'X') && (p.signature[3] == ' ')) {
//         return p.parameters, false
//     }

//     if read > 0 && p.length == size_of(p.parameters) {
//         return p.parameters, true
//     }
//     return p.parameters, false
// }

// SaveWaveParams :: proc(fileName: string, params: WaveParams) -> bool {
//     p := WaveParamsOnDisk{
//         parameters= params,
//     }
//     p.signature = { 'r', 'F', 'X',' ' }
//     p.version = 200
//     p.length = size_of(p.parameters)

//     file, err := os.open(fileName, os.O_WRONLY | os.O_CREATE)
//     if err != nil {
//         return false
//     }

//     written, write_err := os.write_ptr(file, &p, size_of(WaveParamsOnDisk))
//     if write_err != nil {
//         return false
//     }

//     if written > 0 {
//         return true
//     }

//     return false
// }

//--------------------------------------------------------------------------------------------
// Sound generation functions
//--------------------------------------------------------------------------------------------

// Generate sound: Pickup/Coin
GenPickupCoin :: proc() -> WaveParams {
    params := WaveParams{}
    ResetWaveParams(&params)

    params.startFrequencyValue = 0.4 + rfxgen_randf(0.5)
    params.attackTimeValue = 0.0
    params.sustainTimeValue = rfxgen_randf(0.1)
    params.decayTimeValue = 0.1 + rfxgen_randf(0.4)
    params.sustainPunchValue = 0.3 + rfxgen_randf(0.3)

    if rfxgen_rand01() {
        params.changeSpeedValue = 0.5 + rfxgen_randf(0.2)
        params.changeAmountValue = 0.2 + rfxgen_randf(0.4)
    }

    return params
}

// Generate sound: Laser shoot
GenLaserShoot :: proc() -> WaveParams {
    params := WaveParams{}
    ResetWaveParams(&params)

    value := rfxgen_rand(0, 2)
    params.waveTypeValue = WaveType(value)

    if i32(params.waveTypeValue) == 2 do params.waveTypeValue = WaveType(rfxgen_rand01())

    params.startFrequencyValue = 0.5 + rfxgen_randf(0.5)
    params.minFrequencyValue = params.startFrequencyValue - 0.2 - rfxgen_randf(0.6)

    if params.minFrequencyValue < 0.2 do params.minFrequencyValue = 0.2

    params.slideValue = -0.15 - rfxgen_randf(0.2)

    if (rfxgen_rand(0, 2) == 0) {
        params.startFrequencyValue = 0.3 + rfxgen_randf(0.6)
        params.minFrequencyValue = rfxgen_randf(0.1)
        params.slideValue = -0.35 - rfxgen_randf(0.3)
    }

    if rfxgen_rand01() {
        params.squareDutyValue = rfxgen_randf(0.5)
        params.dutySweepValue = rfxgen_randf(0.2)
    } else {
        params.squareDutyValue = 0.4 + rfxgen_randf(0.5)
        params.dutySweepValue = -rfxgen_randf(0.7)
    }

    params.attackTimeValue = 0.0
    params.sustainTimeValue = 0.1 + rfxgen_randf(0.2)
    params.decayTimeValue = rfxgen_randf(0.4)

    if rfxgen_rand01() do params.sustainPunchValue = rfxgen_randf(0.3)

    if (rfxgen_rand(0, 2) == 0) {
        params.phaserOffsetValue = rfxgen_randf(0.2)
        params.phaserSweepValue = -rfxgen_randf(0.2)
    }

    if rfxgen_rand01() do params.hpfCutoffValue = rfxgen_randf(0.3)

    return params
}

// Generate sound: Explosion
GenExplosion :: proc() -> WaveParams {
    params := WaveParams{}
    ResetWaveParams(&params)

    params.waveTypeValue = WaveType(3)

    if rfxgen_rand01() {
        params.startFrequencyValue = 0.1 + rfxgen_randf(0.4)
        params.slideValue = -0.1 + rfxgen_randf(0.4)
    } else {
        params.startFrequencyValue = 0.2 + rfxgen_randf(0.7)
        params.slideValue = -0.2 - rfxgen_randf(0.2)
    }

    params.startFrequencyValue *= params.startFrequencyValue

    if (rfxgen_rand(0, 4) == 0) do params.slideValue = 0.0
    if (rfxgen_rand(0, 2) == 0) do params.repeatSpeedValue = 0.3 + rfxgen_randf(0.5)

    params.attackTimeValue = 0.0
    params.sustainTimeValue = 0.1 + rfxgen_randf(0.3)
    params.decayTimeValue = rfxgen_randf(0.5)

    if rfxgen_rand01() {
        params.phaserOffsetValue = -0.3 + rfxgen_randf(0.9)
        params.phaserSweepValue = -rfxgen_randf(0.3)
    }

    params.sustainPunchValue = 0.2 + rfxgen_randf(0.6)

    if rfxgen_rand01() {
        params.vibratoDepthValue = rfxgen_randf(0.7)
        params.vibratoSpeedValue = rfxgen_randf(0.6)
    }

    if (rfxgen_rand(0, 2) == 0) {
        params.changeSpeedValue = 0.6 + rfxgen_randf(0.3)
        params.changeAmountValue = 0.8 - rfxgen_randf(1.6)
    }

    return params
}

// Generate sound: Powerup
GenPowerup :: proc() -> WaveParams {
    params := WaveParams{}
    ResetWaveParams(&params)

    if rfxgen_rand01() {
        params.waveTypeValue = WaveType(1)
    } else {
        params.squareDutyValue = rfxgen_randf(0.6)
    }

    if rfxgen_rand01() {
        params.startFrequencyValue = 0.2 + rfxgen_randf(0.3)
        params.slideValue = 0.1 + rfxgen_randf(0.4)
        params.repeatSpeedValue = 0.4 + rfxgen_randf(0.4)
    } else {
        params.startFrequencyValue = 0.2 + rfxgen_randf(0.3)
        params.slideValue = 0.05 + rfxgen_randf(0.2)

        if rfxgen_rand01() {
            params.vibratoDepthValue = rfxgen_randf(0.7)
            params.vibratoSpeedValue = rfxgen_randf(0.6)
        }
    }

    params.attackTimeValue = 0.0
    params.sustainTimeValue = rfxgen_randf(0.4)
    params.decayTimeValue = 0.1 + rfxgen_randf(0.4)

    return params
}

// Generate sound: Hit/Hurt
GenHitHurt :: proc() -> WaveParams {
    params := WaveParams{}
    ResetWaveParams(&params)

    params.waveTypeValue = WaveType(rfxgen_rand(0, 2))
    if params.waveTypeValue == WaveType(2) do params.waveTypeValue = WaveType(3)
    if params.waveTypeValue == WaveType(0) do params.squareDutyValue = rfxgen_randf(0.6)

    params.startFrequencyValue = 0.2 + rfxgen_randf(0.6)
    params.slideValue = -0.3 - rfxgen_randf(0.4)
    params.attackTimeValue = 0.0
    params.sustainTimeValue = rfxgen_randf(0.1)
    params.decayTimeValue = 0.1 + rfxgen_randf(0.2)

    if rfxgen_rand01() do params.hpfCutoffValue = rfxgen_randf(0.3)

    return params
}

// Generate sound: Jump
GenJump :: proc() -> WaveParams {
    params := WaveParams{}
    ResetWaveParams(&params)

    params.waveTypeValue = WaveType(0)
    params.squareDutyValue = rfxgen_randf(0.6)
    params.startFrequencyValue = 0.3 + rfxgen_randf(0.3)
    params.slideValue = 0.1 + rfxgen_randf(0.2)
    params.attackTimeValue = 0.0
    params.sustainTimeValue = 0.1 + rfxgen_randf(0.3)
    params.decayTimeValue = 0.1 + rfxgen_randf(0.2)

    if rfxgen_rand01() do params.hpfCutoffValue = rfxgen_randf(0.3)
    if rfxgen_rand01() do params.lpfCutoffValue = 1.0 - rfxgen_randf(0.6)

    return params
}

// Generate sound: Blip/Select
GenBlipSelect :: proc() -> WaveParams {
    params := WaveParams{}
    ResetWaveParams(&params)

    params.waveTypeValue = WaveType(rfxgen_rand01())

    if (params.waveTypeValue == WaveType(0)) do params.squareDutyValue = rfxgen_randf(0.6)
    params.startFrequencyValue = 0.2 + rfxgen_randf(0.4)
    params.attackTimeValue = 0.0
    params.sustainTimeValue = 0.1 + rfxgen_randf(0.1)
    params.decayTimeValue = rfxgen_randf(0.2)
    params.hpfCutoffValue = 0.1

    return params
}

// Generate random sound
GenRandomize :: proc() -> WaveParams {
    params := WaveParams{}
    ResetWaveParams(&params)

    params.randSeed = auto_cast rand.int63()

    params.startFrequencyValue = math.pow(rfxgen_randf(2.0) - 1.0, 2.0)

    if rfxgen_rand01() {
        params.startFrequencyValue = math.pow(rfxgen_randf(2.0) - 1.0, 3.0) + 0.5}

    params.minFrequencyValue = 0.0
    params.slideValue = math.pow(rfxgen_randf(2.0) - 1.0, 5.0)

    if ((params.startFrequencyValue > 0.7) && (params.slideValue > 0.2)) {
        params.slideValue = -params.slideValue}
    if ((params.startFrequencyValue < 0.2) && (params.slideValue < -0.05)) {
        params.slideValue = -params.slideValue}

    params.deltaSlideValue = math.pow(rfxgen_randf(2.0) - 1.0, 3.0)
    params.squareDutyValue = rfxgen_randf(2.0) - 1.0
    params.dutySweepValue = math.pow(rfxgen_randf(2.0) - 1.0, 3.0)
    params.vibratoDepthValue = math.pow(rfxgen_randf(2.0) - 1.0, 3.0)
    params.vibratoSpeedValue = rfxgen_randf(2.0) - 1.0
    // params.vibratoPhaseDelay = rfxgen_randf(2.0) - 1.0
    params.attackTimeValue = math.pow(rfxgen_randf(2.0) - 1.0, 3.0)
    params.sustainTimeValue = math.pow(rfxgen_randf(2.0) - 1.0, 2.0)
    params.decayTimeValue = rfxgen_randf(2.0) - 1.0
    params.sustainPunchValue = math.pow(rfxgen_randf(0.8), 2.0)

    if (params.attackTimeValue + params.sustainTimeValue + params.decayTimeValue < 0.2) {
        params.sustainTimeValue += 0.2 + rfxgen_randf(0.3)
        params.decayTimeValue += 0.2 + rfxgen_randf(0.3)
    }

    params.lpfResonanceValue = rfxgen_randf(2.0) - 1.0
    params.lpfCutoffValue = 1.0 - math.pow(rfxgen_randf(1.0), 3.0)
    params.lpfCutoffSweepValue = math.pow(rfxgen_randf(2.0) - 1.0, 3.0)

    if (params.lpfCutoffValue < 0.1 && params.lpfCutoffSweepValue < -0.05) {
        params.lpfCutoffSweepValue = -params.lpfCutoffSweepValue}

    params.hpfCutoffValue = math.pow(rfxgen_randf(1.0), 5.0)
    params.hpfCutoffSweepValue = math.pow(rfxgen_randf(2.0) - 1.0, 5.0)
    params.phaserOffsetValue = math.pow(rfxgen_randf(2.0) - 1.0, 3.0)
    params.phaserSweepValue = math.pow(rfxgen_randf(2.0) - 1.0, 3.0)
    params.repeatSpeedValue = rfxgen_randf(2.0) - 1.0
    params.changeSpeedValue = rfxgen_randf(2.0) - 1.0
    params.changeAmountValue = rfxgen_randf(2.0) - 1.0

    return params
}

// Mutate current sound
WaveMutate :: proc(params: ^WaveParams) {
    // rfxgen_srand(time(nil)); // Refresh seed to avoid converging behaviour

    if rfxgen_rand01() do params.startFrequencyValue += rfxgen_randf(0.1) - 0.05
    // if rfxgen_rand01() params.minFrequencyValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.slideValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.deltaSlideValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.squareDutyValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.dutySweepValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.vibratoDepthValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.vibratoSpeedValue += rfxgen_randf(0.1) - 0.05
    // if rfxgen_rand01() params.vibratoPhaseDelay += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.attackTimeValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.sustainTimeValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.decayTimeValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.sustainPunchValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.lpfResonanceValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.lpfCutoffValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.lpfCutoffSweepValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.hpfCutoffValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.hpfCutoffSweepValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.phaserOffsetValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.phaserSweepValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.repeatSpeedValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.changeSpeedValue += rfxgen_randf(0.1) - 0.05
    if rfxgen_rand01() do params.changeAmountValue += rfxgen_randf(0.1) - 0.05
}
