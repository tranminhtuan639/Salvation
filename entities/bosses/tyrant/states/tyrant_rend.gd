extends EnemyState
## Sky Rend: vung ngang, phóng luồng năng lượng hình lưỡi kiếm bay ngang (SkyWave).
## P1: 1 luồng 12 u/s. P2: 2 luồng cách nhau 0.25s, 16 u/s. Hướng khóa từ Telegraph.
## Lưỡi cao 1.6u sát đất: nhảy qua hoặc dash xuyên là né được.

var _t := 0.0
var _shots_left := 1
var _next_shot := 0.08
var _gap := 0.25
var _last_shot := 0.0


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy as TyrantBoss
	_t = 0.0
	_shots_left = int(b.pcfg("rend_count", 1))
	_gap = b.pcfg("rend_gap", 0.25)
	_next_shot = b.cfg("rend_windup", 0.08)
	_last_shot = _next_shot
	b.velocity.x = 0.0
	b.sprite.play(&"attack")
	b.set_sword_pose(TyrantBoss.POSE_SLASH, 0.06)


func physics_update(delta: float) -> void:
	var b := enemy as TyrantBoss
	_t += delta
	b.apply_gravity(delta)
	b.velocity.x = 0.0
	b.move_and_slide()
	if _shots_left > 0 and _t >= _next_shot:
		_fire(b)
		_shots_left -= 1
		_last_shot = _next_shot
		_next_shot += _gap
		if _shots_left > 0:
			b.set_sword_pose(TyrantBoss.POSE_RAISED, 0.05)   # vung lại cho luồng thứ 2
	if _shots_left == 0 and _t >= _last_shot + 0.12:
		machine.change_to(&"Recover")


func _fire(b: TyrantBoss) -> void:
	var px := Config.PX_PER_UNIT
	b.set_sword_pose(TyrantBoss.POSE_SLASH, 0.04)
	SkyWave.spawn(b.get_parent(),
			Vector2(b.global_position.x + b.facing * 0.8 * px, b.global_position.y - 0.85 * px),
			b.facing, b.pcfg("rend_damage", 18.0), b.pcfg("rend_speed", 12.0) * px,
			b.cfg("rend_range", 32.0) * px, b.cfg("rend_width", 0.8) * px, b.cfg("rend_height", 1.6) * px,
			b.bolt_color())


func exit() -> void:
	(enemy as TyrantBoss).set_sword_pose(TyrantBoss.POSE_REST, 0.25)
