extends EnemyState
## Archer giữ khoảng cách: quá xa thì tiến lại, quá gần thì lùi, nằm trong [min_range, shoot_range] thì đứng ngắm.
## (Node này đặt tên "Chase" trong scene để Idle/Hurt/Recover dùng chung chuyển state với Grunt.)
## Bị dồn vào tường thì không lùi được nữa, lúc đó cứ đứng bắn.

func enter(_msg: Dictionary = {}) -> void:
	enemy.sprite.play(&"run")


func physics_update(delta: float) -> void:
	var e := enemy
	if not e.target_alive():
		machine.change_to(&"Idle")
		return

	var px := Config.PX_PER_UNIT
	var dx := e.dx_to_target()
	var dist := absf(dx)
	if not e.always_aggro and dist > e.cfg("aggro_range", 11.0) * px * 1.5:
		machine.change_to(&"Idle")
		return

	e.face(dx)   # luôn quay mặt về phía player, kể cả lúc lùi
	e.apply_gravity(delta)

	var shoot_range := e.cfg("shoot_range", 9.0) * px
	var min_range := e.cfg("min_range", 3.5) * px
	var move := 0.0
	if dist > shoot_range:
		move = e.facing
	elif dist < min_range and not e.is_on_wall():
		move = -e.facing
	e.velocity.x = move * e.move_speed
	e.move_and_slide()

	var cornered := dist < min_range and e.is_on_wall()
	var in_band := dist <= shoot_range and (dist >= min_range or cornered)
	if in_band and absf(e.dy_to_target()) <= 3.0 * px and e.is_on_floor():
		machine.change_to(&"Telegraph")
