extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.sprite.play(&"idle")

func physics_update(delta: float) -> void:
	var p := player
	p.apply_gravity(delta)
	p.velocity.x = move_toward(p.velocity.x, 0.0, p.move_speed * 10.0 * delta)
	p.move_and_slide()

	var next := p.poll_actions()
	if next != &"":
		machine.change_to(next)
		return
	if not p.is_on_floor():
		machine.change_to(&"Air")
	elif p.input_buffer.consume(&"jump"):
		machine.change_to(&"Air", {"jump": true})
	elif p.get_move_input() != 0.0:
		machine.change_to(&"Run")
