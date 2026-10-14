extends PlayerState
## Chết: nằm yên, miễn sát thương vĩnh viễn (khỏi bị đánh xác). HUD hiện màn hình thua nhờ signal Player.died.


func enter(_msg: Dictionary = {}) -> void:
	var p := player
	p.velocity.x = 0.0
	p.clear_buff()
	p.hurtbox.set_invulnerable(&"dead", true)
	p.sprite.play(&"dead")


func physics_update(delta: float) -> void:
	var p := player
	p.apply_gravity(delta)
	p.velocity.x = move_toward(p.velocity.x, 0.0, p.move_speed * 8.0 * delta)
	p.move_and_slide()
