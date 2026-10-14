extends AttackState

var _healed := false

func enter(msg: Dictionary = {}) -> void:
	_healed = false
	super.enter(msg)

func _on_hit(hurtbox: Hurtbox) -> void:
	super._on_hit(hurtbox)
	if not _healed:   # chỉ hồi 1 lần mỗi lần dùng
		_healed = true
		player.health.heal(Config.get_value("skill.water.heal", 15.0))
