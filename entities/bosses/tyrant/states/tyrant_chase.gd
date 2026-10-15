extends EnemyState
## Tiến sát khi player ở xa; lùi nhẹ khi quá gần; không đứng chờ quá 0.5s.
## Mỗi frame hỏi TyrantBoss.choose_attack, có đòn thì sang Telegraph.
## (Node này đặt tên "Chase" để Idle/Hurt/Recover/Stagger dùng chung chuyển state.)

var _backoff := 0.0
var _quiet := 0.0


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy as TyrantBoss
	b.sprite.play(&"run")
	_quiet = 0.0
	_backoff = 0.0
	if b.target_alive() and absf(b.dx_to_target()) < 1.3 * Config.PX_PER_UNIT \
			and randf() < b.cfg("backoff_chance", 0.35):
		_backoff = b.cfg("backoff_time", 0.25)


func physics_update(delta: float) -> void:
	var b := enemy as TyrantBoss
	if not b.target_alive():
		machine.change_to(&"Idle")
		return
	var px := Config.PX_PER_UNIT
	var dx := b.dx_to_target()
	var dist := absf(dx)
	if dist > b.cfg("aggro_range", 16.0) * px * 1.5:
		machine.change_to(&"Idle")
		return

	b.face(dx)
	b.apply_gravity(delta)
	if _backoff > 0.0:
		_backoff -= delta
		b.velocity.x = -b.facing * b.move_speed * 0.8   # lùi nhưng vẫn quay mặt về player
		if b.is_on_wall():
			_backoff = 0.0
	elif dist > b.melee_range() * 0.85:
		b.velocity.x = b.facing * b.move_speed
	else:
		b.velocity.x = 0.0
	b.move_and_slide()
	if not b.is_on_floor():
		return

	var pick := b.choose_attack(dist, absf(b.dy_to_target()))
	if pick == &"" and _quiet >= 0.5:
		pick = b.choose_attack(dist, absf(b.dy_to_target()), true)
		if pick == &"":
			_backoff = 0.3   # không có gì để tung: lùi/strafe một nhịp rồi tính lại
			_quiet = 0.0
	if pick != &"":
		b.commit_attack(pick)
		machine.change_to(&"Telegraph")
		return
	_quiet = _quiet + delta if absf(b.velocity.x) < 1.0 else 0.0
