class_name Cooldowns
extends Node

var _ready_at: Dictionary = {}   # id -> msec
var _duration: Dictionary = {}   # id -> giây

func start(id: StringName, duration: float) -> void:
	_duration[id] = duration
	_ready_at[id] = Time.get_ticks_msec() + int(duration * 1000.0)

func is_ready(id: StringName) -> bool:
	return Time.get_ticks_msec() >= int(_ready_at.get(id, 0))

func remaining(id: StringName) -> float:
	return maxf(0.0, (int(_ready_at.get(id, 0)) - Time.get_ticks_msec()) / 1000.0)

## 0.0 = sẵn sàng, 1.0 = vừa bắt đầu hồi. Dùng cho vòng cooldown trên HUD.
func ratio(id: StringName) -> float:
	var d: float = _duration.get(id, 0.0)
	return 0.0 if d <= 0.0 else clampf(remaining(id) / d, 0.0, 1.0)
