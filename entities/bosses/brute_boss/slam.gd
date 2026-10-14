extends EnemyState
## Đập đất: dùng animation "attack" (chém xuống). Hitbox hình tròn bán kính `slam_radius` u quanh chân boss
## bật trong `slam_active` giây. Player nhảy cao hơn bán kính thì né được.
## Kèm hiệu ứng: vòng sóng xung kích lan ra + rung camera nhẹ.

var _t := 0.0
var _active := 0.15


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy
	var r: float = b.cfg("slam_radius", 3.0) * Config.PX_PER_UNIT
	_t = 0.0
	_active = b.cfg("slam_active", 0.15)
	b.velocity.x = 0.0
	b.sprite.play(&"attack")

	var hb := b.get_node("Pivot/SlamHitbox") as Hitbox
	(hb.get_node("CollisionShape2D").shape as CircleShape2D).radius = r
	hb.arm(b.cfg("slam_damage", 16.0))

	SlamFx.spawn(b, SlamFx.Kind.BURST, r, 0.35)
	_shake_camera(7.0, 0.25)


func physics_update(delta: float) -> void:
	var b := enemy
	_t += delta
	b.apply_gravity(delta)
	b.velocity.x = 0.0
	b.move_and_slide()
	if _t >= _active:
		machine.change_to(&"Recover")


func exit() -> void:
	(enemy.get_node("Pivot/SlamHitbox") as Hitbox).disarm()


## FollowCamera chỉ set global_position nên tween `offset` không bị đè.
func _shake_camera(strength: float, duration: float) -> void:
	var cam := enemy.get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := cam.create_tween()
	for i in 5:
		tw.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * (1.0 - i / 5.0), duration / 6.0)
	tw.tween_property(cam, "offset", Vector2.ZERO, duration / 6.0)
