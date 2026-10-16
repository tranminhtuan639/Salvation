class_name ExitGate
extends Node2D
## Cổng cuối bản đồ. Đóng cho tới khi Level gọi open() (hạ hết quái). Mở rồi thì player chạy vào
## là phát signal `entered` để Level chuyển stage. Vẽ bằng code (placeholder): khung đá, hai cánh cửa
## trượt ra hai bên, ánh sáng lộ ra phía sau. Gốc của node nằm ở GIỮA CHÂN cổng, y = mặt sàn.

signal entered

const DOOR_W := 140.0       # px, bề rộng ô cửa
const DOOR_H := 280.0       # px, chiều cao ô cửa
const PILLAR_W := 26.0
const LINTEL_H := 30.0
const HINT_RANGE := 350.0   # px, lại gần cỡ này khi cổng còn đóng thì hiện gợi ý

var is_open := false
var _open := 0.0            # 0 = đóng, 1 = mở hẳn
var _hint := 0.0            # độ đậm của dòng gợi ý
var _triggered := false
var _area: Area2D


func _ready() -> void:
	z_index = -1   # nằm sau player và quái
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2   # layer 2 = player_body
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(DOOR_W, DOOR_H)
	shape.shape = rect
	shape.position = Vector2(0.0, -DOOR_H / 2.0)
	_area.add_child(shape)
	add_child(_area)


func open() -> void:
	if is_open:
		return
	is_open = true
	var tw := create_tween()
	tw.tween_method(_set_open, 0.0, 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_open(v: float) -> void:
	_open = v
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not is_open or _triggered:
		return
	# Kiểm tra mỗi frame (không dùng body_entered) để player đang đứng sẵn trong ô cửa lúc cổng mở cũng tính.
	for b in _area.get_overlapping_bodies():
		if b is Player:
			_triggered = true
			entered.emit()
			return


func _process(delta: float) -> void:
	var want := 0.0
	if not is_open:
		var p := get_tree().get_first_node_in_group(&"player") as Node2D
		if p != null and absf(p.global_position.x - global_position.x) < HINT_RANGE:
			want = 1.0
	if absf(want - _hint) > 0.01:
		_hint = move_toward(_hint, want, delta * 3.0)
		queue_redraw()


func _draw() -> void:
	var hw := DOOR_W / 2.0
	var top := -DOOR_H

	# Ánh sáng phía sau cánh cửa, lộ ra khi mở
	if _open > 0.0:
		draw_rect(Rect2(-hw, top, DOOR_W, DOOR_H), Color(1.0, 0.86, 0.55, 0.9 * _open))
		for i in 3:
			var spread := 10.0 + i * 16.0
			draw_rect(Rect2(-hw - spread, top - spread * 0.5, DOOR_W + spread * 2.0, DOOR_H + spread * 0.5),
					Color(1.0, 0.8, 0.45, 0.10 * _open))

	# Hai cánh cửa co dần vào hai bên trụ khi mở (không trượt ra ngoài khung)
	var leaf_w := hw * (1.0 - _open)
	var leaf := Color(0.07, 0.07, 0.09)
	draw_rect(Rect2(-hw, top, leaf_w, DOOR_H), leaf)
	draw_rect(Rect2(hw - leaf_w, top, leaf_w, DOOR_H), leaf)
	var rune := 1.0 - _open
	if rune > 0.0:
		var c := Vector2(0.0, top + DOOR_H * 0.45)
		draw_line(Vector2(0.0, top), Vector2(0.0, 0.0), Color(0.25, 0.08, 0.08, rune), 3.0)
		draw_arc(c, 22.0, 0.0, TAU, 32, Color(0.9, 0.2, 0.15, 0.55 * rune), 3.0)
		draw_circle(c, 7.0, Color(0.9, 0.2, 0.15, 0.4 * rune))

	# Khung đá: hai trụ + mái
	var stone := Color(0.11, 0.11, 0.14)
	var edge := Color(0.22, 0.22, 0.27)
	draw_rect(Rect2(-hw - PILLAR_W, top - LINTEL_H, PILLAR_W, DOOR_H + LINTEL_H), stone)
	draw_rect(Rect2(hw, top - LINTEL_H, PILLAR_W, DOOR_H + LINTEL_H), stone)
	draw_rect(Rect2(-hw - PILLAR_W, top - LINTEL_H, DOOR_W + PILLAR_W * 2.0, LINTEL_H), stone)
	draw_rect(Rect2(-hw - PILLAR_W - 6.0, top - LINTEL_H - 8.0, DOOR_W + PILLAR_W * 2.0 + 12.0, 8.0), edge)

	# Gợi ý khi cổng còn đóng
	if _hint > 0.01 and not is_open:
		var font := ThemeDB.fallback_font
		var text := "Hạ hết quái để mở cổng"
		var pos := Vector2(-130.0, top - LINTEL_H - 24.0)
		draw_string(font, pos + Vector2(1.5, 1.5), text, HORIZONTAL_ALIGNMENT_CENTER, 260.0, 18, Color(0, 0, 0, _hint))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 260.0, 18, Color(1, 1, 1, _hint))
