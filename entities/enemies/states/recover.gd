extends EnemyState
## Hở sườn sau đòn đánh: `recover` giây đứng im. Đây là cửa sổ để player phản công.

var _t := 0.0


func enter(_msg: Dictionary = {}) -> void:
	_t = 0.0
	enemy.sprite.play(&"idle")


func physics_update(delta: float) -> void:
	var e := enemy
	_t += delta
	e.apply_gravity(delta)
	e.velocity.x = move_toward(e.velocity.x, 0.0, e.move_speed * 10.0 * delta)
	e.move_and_slide()
	if _t >= e.cfg("recover", 0.7):
		machine.change_to(&"Chase")
