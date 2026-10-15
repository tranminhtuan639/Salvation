extends EnemyState
## Đứng yên cho tới khi player lọt vào tầm phát hiện (aggro_range).

func enter(_msg: Dictionary = {}) -> void:
	enemy.sprite.play(&"idle")


func physics_update(delta: float) -> void:
	var e := enemy
	e.apply_gravity(delta)
	e.velocity.x = move_toward(e.velocity.x, 0.0, e.move_speed * 10.0 * delta)
	e.move_and_slide()
	if e.target_alive() and (e.always_aggro or absf(e.dx_to_target()) <= e.cfg("aggro_range", 8.0) * Config.PX_PER_UNIT):
		machine.change_to(&"Chase")
