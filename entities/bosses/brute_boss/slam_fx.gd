class_name SlamFx
extends Node2D
## Hiệu ứng vòng tròn trên mặt đất của đòn Đập đất (nửa vòng phía trên mặt đất, tâm ở chân boss).
## WARN: vòng cảnh báo, phần tô đỏ lớn dần tới hết bán kính đúng lúc telegraph kết thúc.
## BURST: sóng xung kích lan ra rồi mờ dần.

enum Kind { WARN, BURST }

var kind := Kind.BURST
var radius := 192.0
var duration := 0.35
var _t := 0.0


static func spawn(boss: Node2D, k: Kind, r: float, dur: float) -> SlamFx:
	var fx := SlamFx.new()
	fx.kind = k
	fx.radius = r
	fx.duration = dur
	boss.get_parent().add_child(fx)
	fx.global_position = boss.global_position
	return fx


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= duration:
		queue_free()


func _half_disc(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 33:
		var a := PI + PI * i / 32.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _draw() -> void:
	var p := clampf(_t / duration, 0.0, 1.0)
	match kind:
		Kind.WARN:
			draw_colored_polygon(_half_disc(maxf(radius * p, 1.0)), Color(1.0, 0.2, 0.15, 0.30))
			draw_arc(Vector2.ZERO, radius, PI, TAU, 48, Color(1.0, 0.3, 0.2, 0.85), 3.0)
		Kind.BURST:
			var r := radius * (0.35 + 0.65 * p)
			draw_colored_polygon(_half_disc(r), Color(1.0, 0.6, 0.3, 0.25 * (1.0 - p)))
			draw_arc(Vector2.ZERO, r, PI, TAU, 48, Color(1.0, 0.85, 0.5, 1.0 - p), 8.0 * (1.0 - p) + 2.0)
