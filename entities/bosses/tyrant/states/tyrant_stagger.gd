extends EnemyState
## Hở sườn dài: Wrath lao hụt (1.2s) hoặc đâm tường (2.0s, choáng). Không bị ngắt bởi Hurt nên player đánh thoải mái.
## msg: {"duration": giây, "wall": true nếu đâm tường}

var _t := 0.0
var _dur := 1.2
var _wall := false


func enter(msg: Dictionary = {}) -> void:
	var b := enemy as TyrantBoss
	_t = 0.0
	_dur = float(msg.get("duration", 1.2))
	_wall = bool(msg.get("wall", false))
	b.velocity.x = 0.0
	b.sprite.play(&"hurt" if _wall else &"idle")
	b.set_sword_pose(95.0 if _wall else 60.0, 0.15)   # kiếm cắm / buông thõng


func physics_update(delta: float) -> void:
	var b := enemy as TyrantBoss
	_t += delta
	b.apply_gravity(delta)
	b.velocity.x = move_toward(b.velocity.x, 0.0, b.move_speed * 10.0 * delta)
	b.move_and_slide()
	if _wall:   # choáng: nhấp nháy xanh nhạt
		b.sprite.modulate = Color(0.65, 0.7, 1.0) if int(_t * 8.0) % 2 == 0 else Color.WHITE
	if _t >= _dur:
		machine.change_to(&"Chase")


func exit() -> void:
	var b := enemy as TyrantBoss
	b.sprite.modulate = Color.WHITE
	b.set_sword_pose(TyrantBoss.POSE_REST, 0.2)
