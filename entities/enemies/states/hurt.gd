extends EnemyState
## Bị đánh: khựng `hurt_stun` giây và bị đẩy lùi khỏi nguồn đòn. Không có i-frame, nên combo liên tục sẽ khóa quái.

var _t := 0.0


func enter(msg: Dictionary = {}) -> void:
	var e := enemy
	_t = 0.0
	e.sprite.play(&"hurt")
	if msg.has("from_x"):
		var dir := 1.0 if e.global_position.x >= float(msg["from_x"]) else -1.0
		e.velocity.x = dir * e.cfg("knockback", 2.5) * Config.PX_PER_UNIT
	else:
		e.velocity.x = 0.0


func physics_update(delta: float) -> void:
	var e := enemy
	_t += delta
	e.apply_gravity(delta)
	e.velocity.x = move_toward(e.velocity.x, 0.0, e.move_speed * 8.0 * delta)
	e.move_and_slide()
	if _t >= e.cfg("hurt_stun", 0.3):
		machine.change_to(&"Chase")
