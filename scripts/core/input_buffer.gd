class_name InputBuffer
extends Node

@export var window := 0.15
const ACTIONS: Array[StringName] = [&"jump", &"dash", &"attack",
		&"skill_wind", &"skill_water", &"skill_earth", &"skill_fire"]

var _pressed_at: Dictionary = {}   # action -> msec

func _unhandled_input(event: InputEvent) -> void:
	for a in ACTIONS:
		if event.is_action_pressed(a):
			_pressed_at[a] = Time.get_ticks_msec()

## Có lệnh trong cửa sổ buffer thì trả true và xóa lệnh đó.
func consume(action: StringName) -> bool:
	var t: int = _pressed_at.get(action, -100000)
	if Time.get_ticks_msec() - t <= int(window * 1000.0):
		_pressed_at.erase(action)
		return true
	return false

func clear() -> void:
	_pressed_at.clear()
