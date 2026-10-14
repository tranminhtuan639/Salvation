extends Node

var _stopping := false

## Khựng hình ngắn khi trúng đòn. Timer phải bỏ qua time_scale (tham số thứ 4 = true).
func hit_stop(duration := 0.05) -> void:
	if _stopping:
		return
	_stopping = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false
