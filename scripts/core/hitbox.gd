class_name Hitbox
extends Area2D

signal hit_landed(hurtbox: Hurtbox)

var damage := 0.0
var _already_hit: Dictionary = {}   # mỗi mục tiêu chỉ ăn 1 lần/đòn
@onready var _shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)

## size/offset tính bằng pixel; offset.x dương = phía trước mặt nhân vật.
func set_box(size_px: Vector2, offset_px: Vector2) -> void:
	(_shape.shape as RectangleShape2D).size = size_px
	_shape.position = offset_px

func arm(dmg: float) -> void:
	damage = dmg
	_already_hit.clear()
	set_deferred("monitoring", true)

func disarm() -> void:
	set_deferred("monitoring", false)

func _on_area_entered(area: Area2D) -> void:
	var hb := area as Hurtbox
	if hb == null or _already_hit.has(hb):
		return
	_already_hit[hb] = true
	if hb.receive_hit(self):
		hit_landed.emit(hb)
