package karl2d_game

import k2 "../../karl2d"
import "core:fmt"

Gamepad_Deadzone: f32 : 0.2

InputKeyState :: enum {
	NONE,
	PRESSED,
	DOWN,
	DOWN_PULSE,
	RELEASED,
}

Input :: enum {
	INPUT_GAME_FLOOR_PICK_UP,
	INPUT_GAME_WALK_NORTH,
	INPUT_GAME_WALK_EAST,
	INPUT_GAME_WALK_SOUTH,
	INPUT_GAME_WALK_WEST,
	INPUT_GAME_JUMP,
	INPUT_GAME_ATTACK,
	INPUT_GAME_ACTION,
	// INPUT_GAME_NEXT_WEAPON,
	// INPUT_GAME_PREV_WEAPON,
	INPUT_UI_UP,
	INPUT_UI_RIGHT,
	INPUT_UI_DOWN,
	INPUT_UI_LEFT,
	INPUT_UI_SUBMIT,
	INPUT_UI_CANCEL,
	INPUT_UI_TOGGLE_INVENTORY,
	INPUT_QUIT,
	INPUT_TOGGLE_FULLSCREEN,
}

InputStruct :: struct {
	bindInfo:        struct {
		primaryKey:   k2.Keyboard_Key,
		secondaryKey: k2.Keyboard_Key,
		state:        InputKeyState,
		holdAlt:      bool,
		holdControl:  bool,
		holdShift:    bool,
	},
	gamepadBindInfo: struct {
		axis:     k2.Gamepad_Axis,
		positive: bool,
		state:    InputKeyState,
		button:   k2.Gamepad_Button,
	},
	stateInfo:       struct {
		state:      InputKeyState,
		downTime:   f64,
		pulseTimer: f64,
		active:     bool,
	},
}

inputPulseMinDownTime: f64
inputPulseCooldown: f64

inputInfo: [Input]InputStruct

init_input :: proc() {
	load_default_input_config()
}

is_input_active :: proc(input: Input) -> bool {
	return inputInfo[input].stateInfo.active
}

// for axis-bound inputs, returns a value between 0 and 1 representing how strongly the input is being activated. For button-bound inputs, returns 1 if active, otherwise 0.
input_strength :: proc(input: Input) -> f32 {
	if !inputInfo[input].stateInfo.active do return 0

	if inputInfo[input].gamepadBindInfo.axis != nil {
		stick := k2.get_gamepad_axis(0, inputInfo[input].gamepadBindInfo.axis)
		if inputInfo[input].gamepadBindInfo.positive {
			if stick >= Gamepad_Deadzone do return stick
		} else {
			if stick <= -Gamepad_Deadzone do return -stick
		}

		if inputInfo[input].stateInfo.state == .DOWN ||
		   inputInfo[input].stateInfo.state == .PRESSED {
			if k2.key_is_held(inputInfo[input].bindInfo.primaryKey) ||
			   k2.key_is_held(inputInfo[input].bindInfo.secondaryKey) {
				return 1
			}
			if k2.key_went_down(inputInfo[input].bindInfo.primaryKey) ||
			   k2.key_went_down(inputInfo[input].bindInfo.secondaryKey) {
				return 1
			}
		}

		return 0
	}

	return 1
}

load_default_input_config :: proc() {
	inputPulseMinDownTime = 0.33 //L
	inputPulseCooldown = 0.065 //L

	inputInfo[.INPUT_GAME_FLOOR_PICK_UP].bindInfo.primaryKey = .Space
	inputInfo[.INPUT_GAME_FLOOR_PICK_UP].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_GAME_FLOOR_PICK_UP].bindInfo.state = .PRESSED
	inputInfo[.INPUT_GAME_FLOOR_PICK_UP].bindInfo.holdAlt = false
	inputInfo[.INPUT_GAME_FLOOR_PICK_UP].bindInfo.holdControl = false
	inputInfo[.INPUT_GAME_FLOOR_PICK_UP].bindInfo.holdShift = false
	inputInfo[.INPUT_GAME_FLOOR_PICK_UP].gamepadBindInfo.button = .Right_Face_Right

	inputInfo[.INPUT_GAME_WALK_NORTH].bindInfo.primaryKey = .W
	inputInfo[.INPUT_GAME_WALK_NORTH].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_GAME_WALK_NORTH].bindInfo.state = .DOWN
	inputInfo[.INPUT_GAME_WALK_NORTH].bindInfo.holdAlt = false
	inputInfo[.INPUT_GAME_WALK_NORTH].bindInfo.holdControl = false
	inputInfo[.INPUT_GAME_WALK_NORTH].bindInfo.holdShift = false
	inputInfo[.INPUT_GAME_WALK_NORTH].gamepadBindInfo.axis = .Left_Stick_Y
	inputInfo[.INPUT_GAME_WALK_NORTH].gamepadBindInfo.positive = false
	inputInfo[.INPUT_GAME_WALK_NORTH].gamepadBindInfo.button = .Left_Face_Up

	inputInfo[.INPUT_GAME_WALK_EAST].bindInfo.primaryKey = .D
	inputInfo[.INPUT_GAME_WALK_EAST].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_GAME_WALK_EAST].bindInfo.state = .DOWN
	inputInfo[.INPUT_GAME_WALK_EAST].bindInfo.holdAlt = false
	inputInfo[.INPUT_GAME_WALK_EAST].bindInfo.holdControl = false
	inputInfo[.INPUT_GAME_WALK_EAST].bindInfo.holdShift = false
	inputInfo[.INPUT_GAME_WALK_EAST].gamepadBindInfo.axis = .Left_Stick_X
	inputInfo[.INPUT_GAME_WALK_EAST].gamepadBindInfo.positive = true
	inputInfo[.INPUT_GAME_WALK_EAST].gamepadBindInfo.button = .Left_Face_Right

	inputInfo[.INPUT_GAME_WALK_SOUTH].bindInfo.primaryKey = .S
	inputInfo[.INPUT_GAME_WALK_SOUTH].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_GAME_WALK_SOUTH].bindInfo.state = .DOWN
	inputInfo[.INPUT_GAME_WALK_SOUTH].bindInfo.holdAlt = false
	inputInfo[.INPUT_GAME_WALK_SOUTH].bindInfo.holdControl = false
	inputInfo[.INPUT_GAME_WALK_SOUTH].bindInfo.holdShift = false
	inputInfo[.INPUT_GAME_WALK_SOUTH].gamepadBindInfo.axis = .Left_Stick_Y
	inputInfo[.INPUT_GAME_WALK_SOUTH].gamepadBindInfo.positive = true
	inputInfo[.INPUT_GAME_WALK_SOUTH].gamepadBindInfo.button = .Left_Face_Down

	inputInfo[.INPUT_GAME_WALK_WEST].bindInfo.primaryKey = .A
	inputInfo[.INPUT_GAME_WALK_WEST].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_GAME_WALK_WEST].bindInfo.state = .DOWN
	inputInfo[.INPUT_GAME_WALK_WEST].bindInfo.holdAlt = false
	inputInfo[.INPUT_GAME_WALK_WEST].bindInfo.holdControl = false
	inputInfo[.INPUT_GAME_WALK_WEST].bindInfo.holdShift = false
	inputInfo[.INPUT_GAME_WALK_WEST].gamepadBindInfo.axis = .Left_Stick_X
	inputInfo[.INPUT_GAME_WALK_WEST].gamepadBindInfo.positive = false
	inputInfo[.INPUT_GAME_WALK_WEST].gamepadBindInfo.button = .Left_Face_Left

	inputInfo[.INPUT_GAME_ATTACK].bindInfo.primaryKey = .M
	inputInfo[.INPUT_GAME_ATTACK].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_GAME_ATTACK].bindInfo.state = .DOWN
	inputInfo[.INPUT_GAME_ATTACK].bindInfo.holdAlt = false
	inputInfo[.INPUT_GAME_ATTACK].bindInfo.holdControl = false
	inputInfo[.INPUT_GAME_ATTACK].bindInfo.holdShift = false
	inputInfo[.INPUT_GAME_ATTACK].gamepadBindInfo.button = .Right_Face_Down

	inputInfo[.INPUT_GAME_ACTION].bindInfo.primaryKey = .N
	inputInfo[.INPUT_GAME_ACTION].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_GAME_ACTION].bindInfo.state = .DOWN
	inputInfo[.INPUT_GAME_ACTION].bindInfo.holdAlt = false
	inputInfo[.INPUT_GAME_ACTION].bindInfo.holdControl = false
	inputInfo[.INPUT_GAME_ACTION].bindInfo.holdShift = false
	inputInfo[.INPUT_GAME_ACTION].gamepadBindInfo.button = .Right_Face_Left

	// inputInfo[.INPUT_GAME_NEXT_WEAPON].bindInfo.primaryKey = .Left_Bracket
	// inputInfo[.INPUT_GAME_NEXT_WEAPON].bindInfo.secondaryKey = nil
	// inputInfo[.INPUT_GAME_NEXT_WEAPON].bindInfo.state = .DOWN
	// inputInfo[.INPUT_GAME_NEXT_WEAPON].bindInfo.holdAlt = false
	// inputInfo[.INPUT_GAME_NEXT_WEAPON].bindInfo.holdControl = false
	// inputInfo[.INPUT_GAME_NEXT_WEAPON].bindInfo.holdShift = false
	// inputInfo[.INPUT_GAME_NEXT_WEAPON].gamepadBindInfo.axis = .Left_Trigger

	// inputInfo[.INPUT_GAME_PREV_WEAPON].bindInfo.primaryKey = .Right_Bracket
	// inputInfo[.INPUT_GAME_PREV_WEAPON].bindInfo.secondaryKey = nil
	// inputInfo[.INPUT_GAME_PREV_WEAPON].bindInfo.state = .DOWN
	// inputInfo[.INPUT_GAME_PREV_WEAPON].bindInfo.holdAlt = false
	// inputInfo[.INPUT_GAME_PREV_WEAPON].bindInfo.holdControl = false
	// inputInfo[.INPUT_GAME_PREV_WEAPON].bindInfo.holdShift = false
	// inputInfo[.INPUT_GAME_PREV_WEAPON].gamepadBindInfo.axis = .Right_Trigger

	inputInfo[.INPUT_UI_UP].bindInfo.primaryKey = .Up
	inputInfo[.INPUT_UI_UP].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_UI_UP].bindInfo.state = .DOWN_PULSE
	inputInfo[.INPUT_UI_UP].bindInfo.holdAlt = false
	inputInfo[.INPUT_UI_UP].bindInfo.holdControl = false
	inputInfo[.INPUT_UI_UP].bindInfo.holdShift = false
	inputInfo[.INPUT_UI_UP].gamepadBindInfo.button = .Left_Face_Up

	inputInfo[.INPUT_UI_RIGHT].bindInfo.primaryKey = .Right
	inputInfo[.INPUT_UI_RIGHT].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_UI_RIGHT].bindInfo.state = .DOWN_PULSE
	inputInfo[.INPUT_UI_RIGHT].bindInfo.holdAlt = false
	inputInfo[.INPUT_UI_RIGHT].bindInfo.holdControl = false
	inputInfo[.INPUT_UI_RIGHT].bindInfo.holdShift = false
	inputInfo[.INPUT_UI_RIGHT].gamepadBindInfo.button = .Left_Face_Right

	inputInfo[.INPUT_UI_DOWN].bindInfo.primaryKey = .Down
	inputInfo[.INPUT_UI_DOWN].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_UI_DOWN].bindInfo.state = .DOWN_PULSE
	inputInfo[.INPUT_UI_DOWN].bindInfo.holdAlt = false
	inputInfo[.INPUT_UI_DOWN].bindInfo.holdControl = false
	inputInfo[.INPUT_UI_DOWN].bindInfo.holdShift = false
	inputInfo[.INPUT_UI_DOWN].gamepadBindInfo.button = .Left_Face_Down

	inputInfo[.INPUT_UI_LEFT].bindInfo.primaryKey = .Left
	inputInfo[.INPUT_UI_LEFT].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_UI_LEFT].bindInfo.state = .DOWN_PULSE
	inputInfo[.INPUT_UI_LEFT].bindInfo.holdAlt = false
	inputInfo[.INPUT_UI_LEFT].bindInfo.holdControl = false
	inputInfo[.INPUT_UI_LEFT].bindInfo.holdShift = false
	inputInfo[.INPUT_UI_LEFT].gamepadBindInfo.button = .Left_Face_Left

	inputInfo[.INPUT_UI_SUBMIT].bindInfo.primaryKey = .Enter
	inputInfo[.INPUT_UI_SUBMIT].bindInfo.secondaryKey = .E
	inputInfo[.INPUT_UI_SUBMIT].bindInfo.state = .PRESSED
	inputInfo[.INPUT_UI_SUBMIT].bindInfo.holdAlt = false
	inputInfo[.INPUT_UI_SUBMIT].bindInfo.holdControl = false
	inputInfo[.INPUT_UI_SUBMIT].bindInfo.holdShift = false
	inputInfo[.INPUT_UI_SUBMIT].gamepadBindInfo.button = .Right_Face_Down

	inputInfo[.INPUT_UI_CANCEL].bindInfo.primaryKey = .Escape
	inputInfo[.INPUT_UI_CANCEL].bindInfo.secondaryKey = .Tab
	inputInfo[.INPUT_UI_CANCEL].bindInfo.state = .PRESSED
	inputInfo[.INPUT_UI_CANCEL].bindInfo.holdAlt = false
	inputInfo[.INPUT_UI_CANCEL].bindInfo.holdControl = false
	inputInfo[.INPUT_UI_CANCEL].bindInfo.holdShift = false
	inputInfo[.INPUT_UI_CANCEL].gamepadBindInfo.button = .Right_Face_Left

	inputInfo[.INPUT_UI_TOGGLE_INVENTORY].bindInfo.primaryKey = .Tab
	inputInfo[.INPUT_UI_TOGGLE_INVENTORY].bindInfo.secondaryKey = .I
	inputInfo[.INPUT_UI_TOGGLE_INVENTORY].bindInfo.state = .PRESSED
	inputInfo[.INPUT_UI_TOGGLE_INVENTORY].bindInfo.holdAlt = false
	inputInfo[.INPUT_UI_TOGGLE_INVENTORY].bindInfo.holdControl = false
	inputInfo[.INPUT_UI_TOGGLE_INVENTORY].bindInfo.holdShift = false
	inputInfo[.INPUT_UI_TOGGLE_INVENTORY].gamepadBindInfo.button = .Middle_Face_Right
	inputInfo[.INPUT_UI_TOGGLE_INVENTORY].gamepadBindInfo.positive = false

	inputInfo[.INPUT_QUIT].bindInfo.primaryKey = .Q
	inputInfo[.INPUT_QUIT].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_QUIT].bindInfo.state = .PRESSED
	inputInfo[.INPUT_QUIT].bindInfo.holdAlt = false
	inputInfo[.INPUT_QUIT].bindInfo.holdControl = true
	inputInfo[.INPUT_QUIT].bindInfo.holdShift = false

	inputInfo[.INPUT_TOGGLE_FULLSCREEN].bindInfo.primaryKey = .Enter
	inputInfo[.INPUT_TOGGLE_FULLSCREEN].bindInfo.secondaryKey = nil
	inputInfo[.INPUT_TOGGLE_FULLSCREEN].bindInfo.state = .PRESSED
	inputInfo[.INPUT_TOGGLE_FULLSCREEN].bindInfo.holdAlt = true
	inputInfo[.INPUT_TOGGLE_FULLSCREEN].bindInfo.holdControl = false
	inputInfo[.INPUT_TOGGLE_FULLSCREEN].bindInfo.holdShift = false
}

update_inputs :: proc() {

	// TODO: remove
	// if k2.key_went_down(.F1) { neworigin.x += 1; fmt.printf("New origin: %v", neworigin) }
	// if k2.key_went_down(.F2) { neworigin.x -= 1; fmt.printf("New origin: %v", neworigin) }
	// if k2.key_went_down(.F3) { neworigin.y += 1; fmt.printf("New origin: %v", neworigin) }
	// if k2.key_went_down(.F4) { neworigin.y -= 1; fmt.printf("New origin: %v", neworigin) }

	alt_held: bool
	control_held: bool
	shift_held: bool

	alt_held = k2.key_is_held(.Left_Alt) || k2.key_is_held(.Right_Alt)
	control_held = k2.key_is_held(.Left_Control) || k2.key_is_held(.Right_Control)
	shift_held = k2.key_is_held(.Left_Shift) || k2.key_is_held(.Right_Shift)
	frame_time := k2.get_frame_time()

	for i in Input {
		down, pressed, released: bool
		pulsed: bool

		inputInfo[i].stateInfo.active = false
		inputInfo[i].stateInfo.state = .NONE

		// if we require a modifier key, but it is not held, skip processing
		if inputInfo[i].bindInfo.holdAlt && !alt_held do continue
		if inputInfo[i].bindInfo.holdControl && !control_held do continue
		if inputInfo[i].bindInfo.holdShift && !shift_held do continue

		// if there are modifier keys held, but we do not require them, skip processing
		if !inputInfo[i].bindInfo.holdAlt && alt_held do continue
		if !inputInfo[i].bindInfo.holdControl && control_held do continue
		if !inputInfo[i].bindInfo.holdShift && shift_held do continue

		// Keyboard state
		key_down :=
			k2.key_is_held(inputInfo[i].bindInfo.primaryKey) ||
			k2.key_is_held(inputInfo[i].bindInfo.secondaryKey)
		key_pressed :=
			k2.key_went_down(inputInfo[i].bindInfo.primaryKey) ||
			k2.key_went_down(inputInfo[i].bindInfo.secondaryKey)
		key_released :=
			k2.key_went_up(inputInfo[i].bindInfo.primaryKey) ||
			k2.key_went_up(inputInfo[i].bindInfo.secondaryKey)

		// Gamepad state
		gamepad_down, gamepad_pressed, gamepad_released: bool

		if k2.is_gamepad_active(0) {
			if inputInfo[i].gamepadBindInfo.axis != nil {
				axis_value := k2.get_gamepad_axis(0, inputInfo[i].gamepadBindInfo.axis)
				axis_active :=
					(axis_value > Gamepad_Deadzone) if inputInfo[i].gamepadBindInfo.positive else (axis_value < -Gamepad_Deadzone)

				prev_down := inputInfo[i].gamepadBindInfo.state == .DOWN
				gamepad_down = axis_active
				gamepad_pressed = axis_active && !prev_down
				gamepad_released = !axis_active && prev_down

				inputInfo[i].gamepadBindInfo.state = .DOWN if axis_active else .NONE
			} else if inputInfo[i].gamepadBindInfo.button != nil {
				gamepad_pressed = k2.gamepad_button_went_down(
					0,
					inputInfo[i].gamepadBindInfo.button,
				)
				gamepad_down = k2.gamepad_button_is_held(0, inputInfo[i].gamepadBindInfo.button)
				gamepad_released = k2.gamepad_button_went_up(
					0,
					inputInfo[i].gamepadBindInfo.button,
				)
			}
		}

		down = key_down || gamepad_down
		pressed = key_pressed || gamepad_pressed
		released = key_released || gamepad_released

		if pressed {
			inputInfo[i].stateInfo.state = .PRESSED
		} else if down {
			inputInfo[i].stateInfo.state = .DOWN
		} else if released {
			inputInfo[i].stateInfo.state = .RELEASED
		}

		pulsed = false

		if down {
			inputInfo[i].stateInfo.downTime += auto_cast frame_time
			inputInfo[i].stateInfo.pulseTimer += auto_cast frame_time

			if inputInfo[i].stateInfo.pulseTimer > inputPulseCooldown {
				if inputInfo[i].stateInfo.downTime > inputPulseMinDownTime {
					pulsed = true
				}

				inputInfo[i].stateInfo.pulseTimer = 0
			}
		}
		if released {
			inputInfo[i].stateInfo.downTime = 0
			inputInfo[i].stateInfo.pulseTimer = 0
		}

		// Update active state
		if inputInfo[i].bindInfo.state == .DOWN_PULSE {
			if pressed {
				inputInfo[i].stateInfo.active = true
			} else if pulsed && down {
				inputInfo[i].stateInfo.active = true
			}
		} else if inputInfo[i].bindInfo.state == .PRESSED {
			if pressed {
				inputInfo[i].stateInfo.active = true
			}
		} else if inputInfo[i].bindInfo.state == .DOWN {
			if down {
				inputInfo[i].stateInfo.active = true
			}
		} else if inputInfo[i].bindInfo.state == .RELEASED {
			if released {
				inputInfo[i].stateInfo.active = true
			}
		}
	}
}
