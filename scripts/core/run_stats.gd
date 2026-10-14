class_name RunStats
extends RefCounted
## Thống kê của MỘT lượt chơi stage, gửi lên runs/finish. Khớp các cột bảng stage_runs.

const SKILL_BY_STATE := {
	&"SkillWind": "wind",
	&"SkillWater": "water",
	&"SkillEarth": "earth",
	&"SkillFire": "fire",
}

var start_msec := 0
var damage_dealt := 0.0
var damage_taken := 0.0
var dash_count := 0
var skill_usage := {"wind": 0, "water": 0, "earth": 0, "fire": 0}
var phase_reached := 0   # 0 = stage thường (gửi null). Stage boss cuối đặt 1 hoặc 2.

var _hp_prev := 0.0


func elapsed_ms() -> int:
	return maxi(1, Time.get_ticks_msec() - start_msec)   # bảng stage_runs bắt buộc > 0


func add_damage_dealt(actual: float) -> void:
	damage_dealt += actual


## Đếm số lần dash, dùng skill và máu mất của player.
func attach_player(player: Player) -> void:
	_hp_prev = player.health.current
	player.health.changed.connect(_on_player_hp)
	player.machine.state_changed.connect(_on_player_state)


func _on_player_hp(current: float, _maximum: float) -> void:
	if current < _hp_prev:
		damage_taken += _hp_prev - current
	_hp_prev = current   # hồi máu chỉ nâng mốc, không tính là "đã nhận sát thương"


func _on_player_state(_from: StringName, to: StringName) -> void:
	if to == &"Dash":
		dash_count += 1
	elif SKILL_BY_STATE.has(to):
		skill_usage[SKILL_BY_STATE[to]] += 1


## Body của POST /game-api/runs/finish (chưa có signature, Runs.submit ký sau).
func to_payload(session_id: String, result: String) -> Dictionary:
	return {
		"session_id": session_id,
		"result": result,
		"clear_time_ms": elapsed_ms(),
		"damage_dealt": roundi(damage_dealt),
		"damage_taken": roundi(damage_taken),
		"dash_count": dash_count,
		"skill_usage": skill_usage.duplicate(),
		"phase_reached": null if phase_reached == 0 else phase_reached,
	}
