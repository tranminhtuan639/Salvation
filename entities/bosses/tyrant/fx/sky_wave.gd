class_name SkyWave
extends Node2D
## Luồng năng lượng hình lưỡi kiếm của Sky Rend. Bay ngang theo hướng cố định (hướng boss lúc vung),
## trúng player thì biến mất. Player đang miễn sát thương (dash, Đất, i-frame) thì lưỡi xuyên qua
## (mỗi mục tiêu chỉ ăn 1 lần/đòn nên không quay lại trúng nữa). Né bằng cách NHẢY qua hoặc DASH xuyên.

var _damage := 18.0
var _dir := 1
var _speed := 768.0
var _range := 2000.0
var _w := 51.0
var _h := 102.0
var _color := Color(0.75, 0.55, 1.0)
var _travelled := 0.0
var _hb: Hitbox


## `pos` là TÂM của lưỡi.
static func spawn(parent: Node, pos: Vector2, dir: int, dmg: float, speed_px: float,
		range_px: float, w_px: float, h_px: float, col: Color) -> SkyWave:
	var s := SkyWave.new()
	s._damage = dmg
	s._dir = dir
	s._speed = speed_px
	s._range = range_px
	s._w = w_px
	s._h = h_px
	s._color = col
	parent.add_child(s)
	s.global_position = pos
	return s


func _ready() -> void:
	add_to_group(&"boss_hazard")
	z_index = 4
	scale.x = _dir   # lật cả hình lẫn hitbox theo hướng bay
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_w, _h)
	shape.shape = rect
	_hb = Hitbox.new()
	_hb.collision_layer = 64
	_hb.collision_mask = 8
	_hb.add_child(shape)
	add_child(_hb)
	_hb.hit_landed.connect(func(_hurtbox: Hurtbox) -> void: queue_free())
	_hb.arm(_damage)


func _physics_process(delta: float) -> void:
	var step := _dir * _speed * delta
	position.x += step
	_travelled += absf(step)
	if _travelled >= _range:
		queue_free()


func _draw() -> void:
	var hw := _w * 0.5
	var hh := _h * 0.5
	# Lưỡi hình chevron cong: mũi nhọn phía trước (x dương)
	var outer := PackedVector2Array([
		Vector2(hw, 0.0), Vector2(hw * 0.2, -hh * 0.75), Vector2(-hw, -hh),
		Vector2(-hw * 0.35, 0.0), Vector2(-hw, hh), Vector2(hw * 0.2, hh * 0.75)])
	draw_colored_polygon(outer, Color(_color.r, _color.g, _color.b, 0.9))
	var inner := PackedVector2Array([
		Vector2(hw * 0.7, 0.0), Vector2(hw * 0.15, -hh * 0.45), Vector2(-hw * 0.45, -hh * 0.62),
		Vector2(-hw * 0.1, 0.0), Vector2(-hw * 0.45, hh * 0.62), Vector2(hw * 0.15, hh * 0.45)])
	draw_colored_polygon(inner, Color(1, 1, 0.95, 0.95))
