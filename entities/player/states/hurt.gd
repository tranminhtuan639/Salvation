extends PlayerState
## STUB: chưa nối vào cây scene. Muốn dùng thì thêm node Hurt vào StateMachine
## và connect Health.damaged -> machine.change_to(&"Hurt") trong player.gd.

var _t := 0.0

func enter(_msg: Dictionary = {}) -> void:
	_t = 0.0
	player.velocity.x = 0.0

func physics_update(delta: float) -> void:
	_t += delta
	player.apply_gravity(delta)
	player.move_and_slide()
	if _t >= 0.25:
		machine.change_to(&"Idle")
