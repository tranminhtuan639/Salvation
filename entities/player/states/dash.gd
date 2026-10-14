extends PlayerState

var _t := 0.0
var _dur := 0.25
var _iframes := 0.25

func enter(_msg: Dictionary = {}) -> void:
	var p := player
	_t = 0.0
	_dur = Config.get_value("player.dash.duration", 0.25)
	_iframes = Config.get_value("player.dash.iframes", 0.25)
	var dist := Config.get_value("player.dash.distance", 4.0) * Config.PX_PER_UNIT

	p.face(p.get_move_input())   # đang giữ hướng nào thì dash hướng đó, không thì giữ hướng cũ
	p.cooldowns.start(&"dash", Config.get_value("player.dash.cooldown", 0.8))
	p.hurtbox.set_invulnerable(&"dash", true)
	p.velocity = Vector2(p.facing * dist / _dur, 0.0)   # không trọng lực khi dash
	p.sprite.play(&"dash")

func physics_update(delta: float) -> void:
	var p := player
	_t += delta
	if _t >= _iframes:
		p.hurtbox.set_invulnerable(&"dash", false)
	p.move_and_slide()
	if _t >= _dur:
		p.velocity.x = 0.0
		machine.change_to(&"Idle")

func exit() -> void:
	player.hurtbox.set_invulnerable(&"dash", false)
