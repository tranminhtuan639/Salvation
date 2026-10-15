extends EnemyState
## Chạy về phía player. Vào tầm đánh (attack_range) thì chuyển sang Telegraph.
## Bỏ cuộc (về Idle) khi player ra xa quá 1.5 lần tầm phát hiện hoặc đã chết.

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
	if not e.always_aggro and dist > e.cfg("aggro_range", 8.0) * px * 1.5:
		machine.change_to(&"Idle")
		return

	e.face(dx)
	e.apply_gravity(delta)
	var in_reach := dist <= e.cfg("attack_range", 1.6) * px and absf(e.dy_to_target()) <= 1.5 * px
	e.velocity.x = 0.0 if in_reach else e.facing * e.move_speed
	e.move_and_slide()

	if in_reach and e.is_on_floor():
		machine.change_to(&"Telegraph")
