class_name Hurtbox
extends Area2D

signal hurt(hitbox: Hitbox)

@export var health: HealthComponent
var _invuln: Dictionary = {}   # nhiều nguồn miễn sát thương (dash, skill Đất...) không đè lên nhau

func set_invulnerable(source: StringName, on: bool) -> void:
	if on:
		_invuln[source] = true
	else:
		_invuln.erase(source)

func is_invulnerable() -> bool:
	return not _invuln.is_empty()

## Hỏi riêng một nguồn (vd &"hurt" để nhấp nháy khi bị đánh).
func has_invuln(source: StringName) -> bool:
	return _invuln.has(source)

## Trả true nếu đòn thực sự gây sát thương.
func receive_hit(hitbox: Hitbox) -> bool:
	if is_invulnerable() or health == null:
		return false
	health.take_damage(hitbox.damage, hitbox.global_position)
	hurt.emit(hitbox)
	return true
