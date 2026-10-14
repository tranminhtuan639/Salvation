extends AttackState

func enter(msg: Dictionary = {}) -> void:
	# Tổng thời gian cast = skill.earth.invuln (0.7s) nên miễn sát thương đúng bằng cả đòn
	recovery = maxf(0.0, Config.get_value("skill.earth.invuln", 0.7) - startup - active)
	super.enter(msg)
	player.hurtbox.set_invulnerable(&"earth", true)

func exit() -> void:
	super.exit()
	player.hurtbox.set_invulnerable(&"earth", false)
