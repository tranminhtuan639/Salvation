extends PlayerState
## Bị đánh: khựng `player.hurt.stun` giây, bị đẩy lùi, rồi có i-frame `player.hurt.iframes` giây (nhấp nháy)
## để không bị đánh liên hoàn. Mọi trạng thái (trừ Dash/Đất đang miễn sát thương) đều bị ngắt khi trúng đòn.

var _t := 0.0
var _stun := 0.25


func enter(msg: Dictionary = {}) -> void:
	var p := player
	_t = 0.0
	_stun = Config.get_value("player.hurt.stun", 0.25)
	p.sprite.play(&"hurt")
	p.grant_iframes(&"hurt", Config.get_value("player.hurt.iframes", 0.8))
	if msg.has("from_x"):
		var dir := 1.0 if p.global_position.x >= float(msg["from_x"]) else -1.0
		p.velocity.x = dir * Config.get_value("player.hurt.knockback", 4.0) * Config.PX_PER_UNIT
	else:
		p.velocity.x = 0.0


func physics_update(delta: float) -> void:
	var p := player
	_t += delta
	p.apply_gravity(delta)
	p.velocity.x = move_toward(p.velocity.x, 0.0, p.move_speed * 8.0 * delta)
	p.move_and_slide()
	if _t >= _stun:
		machine.change_to(&"Idle")
