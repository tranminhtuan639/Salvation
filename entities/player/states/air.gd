extends PlayerState

func enter(msg: Dictionary = {}) -> void:
	if msg.get("jump", false):
		player.velocity.y = player.jump_velocity
	player.sprite.play(&"jump")

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
	if p.is_on_floor() and p.velocity.y >= 0.0:
		machine.change_to(&"Idle")
