extends EnemyState
## Thunderquake: giáng kiếm xuống đất, các cột sét bằng nhau (P1: 4 cột) hoặc cao dần kiểu biểu đồ cột (P2: 7 cột, 1.5u -> 4.5u)
## nổ LẦN LƯỢT về phía trước. Mỗi cột có `quake_warn` giây cảnh báo sáng dưới đất rồi mới gây sát thương
## (Hitbox mỗi cột: 1.0 x chiều cao u). Cột bị bỏ nếu rơi ra ngoài arena.
## Boss chỉ đứng `quake_hold` giây rồi sang Recover, cột vẫn tiếp tục nổ độc lập.

var _t := 0.0


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy as TyrantBoss
	var px := Config.PX_PER_UNIT
	_t = 0.0
	b.velocity.x = 0.0
	b.sprite.play(&"attack")
	b.set_sword_pose(TyrantBoss.POSE_SLAM, 0.06)
	CamShake.shake(b, 7.0, 0.3)

	var count := int(b.pcfg("quake_count", 4))
	var spacing := b.pcfg("quake_spacing", 2.0) * px
	var start := b.cfg("quake_start", 1.8) * px
	var interval := b.pcfg("quake_interval", 0.18)
	var h_min := b.pcfg("quake_height_min", 3.0) * px
	var h_max := b.pcfg("quake_height_max", 3.0) * px
	var width := b.cfg("quake_width", 1.0) * px
	var xr := b.arena_x_range()
	var parent := b.get_parent()
	for i in count:
		var x := b.global_position.x + b.facing * (start + spacing * i)
		if x < xr.x or x > xr.y:
			break
		var h := h_min if count <= 1 else lerpf(h_min, h_max, float(i) / float(count - 1))
		ThunderColumn.spawn(parent, Vector2(x, b.global_position.y), width, h,
				b.pcfg("quake_damage", 20.0), interval * i, b.pcfg("quake_warn", 0.25),
				b.cfg("quake_active", 0.15), b.bolt_color())


func physics_update(delta: float) -> void:
	var b := enemy as TyrantBoss
	_t += delta
	b.apply_gravity(delta)
	b.velocity.x = 0.0
	b.move_and_slide()
	if _t >= enemy.cfg("quake_hold", 0.3) / b.attack_speed_mult:
		machine.change_to(&"Recover")


func exit() -> void:
	(enemy as TyrantBoss).set_sword_pose(TyrantBoss.POSE_REST, 0.25)
