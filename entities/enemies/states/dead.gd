extends EnemyState
## Chết: tắt hurtbox (khỏi bị đánh xác), mờ dần rồi xóa khỏi cây.

func enter(_msg: Dictionary = {}) -> void:
	var e := enemy
	e.velocity.x = 0.0
	e.sprite.modulate = Color.WHITE
	e.sprite.play(&"dead")
	e.hurtbox.set_deferred("monitorable", false)
	e.hitbox.disarm()
	var tw := e.create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(e.sprite, "modulate:a", 0.0, 0.4)
	tw.tween_callback(e.queue_free)


func physics_update(delta: float) -> void:
	var e := enemy
	e.apply_gravity(delta)
	e.velocity.x = move_toward(e.velocity.x, 0.0, e.move_speed * 8.0 * delta)
	e.move_and_slide()
