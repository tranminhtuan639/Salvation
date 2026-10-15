class_name CamShake
extends RefCounted
## Rung camera dùng chung (FollowCamera chỉ set global_position nên tween `offset` không bị đè).
## Gọi: CamShake.shake(self, 8.0, 0.3)


static func shake(from: Node, strength: float, duration: float) -> void:
	if from == null or not from.is_inside_tree():
		return
	var cam := from.get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := cam.create_tween()
	for i in 5:
		tw.tween_property(cam, "offset", Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * (1.0 - i / 5.0), duration / 6.0)
	tw.tween_property(cam, "offset", Vector2.ZERO, duration / 6.0)
