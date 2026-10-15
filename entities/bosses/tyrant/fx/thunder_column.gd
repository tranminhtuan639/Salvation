class_name ThunderColumn
extends Node2D
## Một cột sét của Thunderquake. Chân cột nằm đúng ở vị trí node.
## Vòng đời: chờ `delay` -> CẢNH BÁO `warn` giây (vệt sáng mờ dưới đất, chưa gây sát thương)
## -> NỔ `active` giây (hitbox bật, cột sét sáng chói) -> mờ dần rồi tự xóa.
## Hitbox dựng bằng code nên không cần file .tscn.

var width := 64.0
var height := 192.0
var damage := 20.0
var delay := 0.0
var warn := 0.25
var active := 0.15
var color := Color(1.0, 0.9, 0.3)

var _t := 0.0
var _hb: Hitbox
var _armed := false
var _zig: PackedFloat32Array = PackedFloat32Array()


static func spawn(parent: Node, pos: Vector2, w: float, h: float, dmg: float,
		dly: float, wrn: float, act: float, col: Color) -> ThunderColumn:
	var c := ThunderColumn.new()
	c.width = w
	c.height = h
	c.damage = dmg
	c.delay = dly
	c.warn = wrn
	c.active = act
	c.color = col
	parent.add_child(c)
	c.global_position = pos
	return c


func _ready() -> void:
	add_to_group(&"boss_hazard")   # boss chết thì dọn hết
	z_index = 5
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"   # Hitbox tìm đúng tên này trong _ready
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape.shape = rect
	shape.position = Vector2(0.0, -height * 0.5)
	_hb = Hitbox.new()
	_hb.collision_layer = 64   # layer 7 = enemy_hitbox (giống Arrow)
	_hb.collision_mask = 8     # quét hurtbox của player
	_hb.add_child(shape)
	add_child(_hb)
	for i in 9:
		_zig.append(randf_range(-0.35, 0.35) * width)


func _physics_process(delta: float) -> void:
	_t += delta
	var strike_at := delay + warn
	if not _armed and _t >= strike_at:
		_armed = true
		_hb.arm(damage)
		CamShake.shake(self, 3.0, 0.15)
	if _armed and _t >= strike_at + active:
		_hb.disarm()
	if _t >= strike_at + active + 0.25:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var strike_at := delay + warn
	var hw := width * 0.5
	if _t < delay:
		return
	if _t < strike_at:
		# Cảnh báo: khung mờ + vạch sáng dưới chân, đậm dần tới lúc nổ
		var p := clampf((_t - delay) / maxf(warn, 0.01), 0.0, 1.0)
		draw_rect(Rect2(-hw, -height, width, height), Color(color.r, color.g, color.b, 0.06 + 0.10 * p))
		draw_rect(Rect2(-hw, -8.0, width, 8.0), Color(color.r, color.g, color.b, 0.35 + 0.5 * p))
		return
	var a := 1.0
	if _t > strike_at + active:
		a = 1.0 - clampf((_t - strike_at - active) / 0.25, 0.0, 1.0)
	# Cột sét: nền vàng, lõi trắng, đường zigzag
	draw_rect(Rect2(-hw, -height, width, height), Color(color.r, color.g, color.b, 0.55 * a))
	draw_rect(Rect2(-hw * 0.45, -height, width * 0.45, height), Color(1, 1, 0.9, 0.9 * a))
	var pts := PackedVector2Array()
	var n := _zig.size()
	for i in n:
		pts.append(Vector2(_zig[i], -height * float(i) / float(n - 1)))
	draw_polyline(pts, Color(1, 1, 1, a), 4.0)
	draw_rect(Rect2(-hw * 1.4, -10.0, width * 1.4, 10.0), Color(1, 0.95, 0.6, 0.8 * a))   # tia nổ chân cột
