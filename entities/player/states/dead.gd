extends PlayerState
## STUB: chưa nối vào cây scene. Thêm node Dead + connect Health.died khi cần.

func enter(_msg: Dictionary = {}) -> void:
	player.velocity = Vector2.ZERO
	player.hurtbox.set_invulnerable(&"dead", true)

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_and_slide()
