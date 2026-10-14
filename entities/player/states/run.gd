extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.sprite.play(&"run")

func physics_update(delta: float) -> void:
	var p := player
	var dir := p.get_move_input()
	p.apply_gravity(delta)
	p.velocity.x = dir * p.move_speed
	p.face(dir)
	p.move_and_slide()

	var next := p.poll_actions()
	if next != &"":
		machine.change_to(next)
		return
	if not p.is_on_floor():
		machine.change_to(&"Air")
	elif p.input_buffer.consume(&"jump"):
		machine.change_to(&"Air", {"jump": true})
	elif dir == 0.0:
		machine.change_to(&"Idle")
