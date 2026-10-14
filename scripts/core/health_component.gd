class_name HealthComponent
extends Node

signal changed(current: float, maximum: float)
signal damaged(amount: float, from_position: Vector2)
signal died

var max_hp := 100.0
var current := 100.0

func setup(hp: float) -> void:
	max_hp = hp
	current = hp
	changed.emit(current, max_hp)

func take_damage(amount: float, from_position := Vector2.ZERO) -> void:
	if current <= 0.0:
		return
	current = maxf(0.0, current - amount)
	damaged.emit(amount, from_position)
	changed.emit(current, max_hp)
	if current == 0.0:
		died.emit()

func heal(amount: float) -> void:
	current = minf(max_hp, current + amount)
	changed.emit(current, max_hp)
