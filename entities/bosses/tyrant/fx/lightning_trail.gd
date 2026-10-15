class_name LightningTrail
extends Node2D
## Vệt sét ĐỂ LẠI SAU LƯNG boss khi Tyrant's Wrath lao tới. CHỈ LÀ HÌNH ẢNH: không có hitbox, không gây sát thương.
## Mỗi đoạn là một tia zigzag ngắn, mờ dần trong `life` giây rồi tự xóa.

var life := 0.35
var _t := 0.0
var _pts := PackedVector2Array()
var _color := Color(1.0, 0.9, 0.3)


static func spawn(parent: Node, pos: Vector2, dir: int, col: Color) -> LightningTrail:
	var f := LightningTrail.new()
	f._color = col
	parent.add_child(f)
	f.global_position = pos
	f.scale.x = dir
	return f


func _ready() -> void:
	add_to_group(&"boss_hazard")   # nhóm dọn dẹp khi boss chết (vẫn là hình ảnh thuần)
	z_index = 3
	var x := 0.0
	for i in 6:
		_pts.append(Vector2(x, randf_range(-34.0, 34.0)))
		x -= 22.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - _t / life
	draw_polyline(_pts, Color(_color.r, _color.g, _color.b, 0.8 * a), 6.0 * a + 1.0)
	draw_polyline(_pts, Color(1, 1, 1, a), 2.0)
