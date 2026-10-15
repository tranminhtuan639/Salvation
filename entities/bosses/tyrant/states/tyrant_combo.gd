extends EnemyState
## Đánh thường: chém 2 nhịp, nhịp 2 kết thúc bằng lao tới ngắn `combo_lunge` u.
## Hitbox `combo_width` x `combo_height` u (nhân buff tầm ở phase 2). Thời gian chia cho attack_speed_mult.
## Lưu ý: player có i-frame 0.8s sau khi bị trúng (player.hurt.iframes), nên nếu nhịp 1 trúng thì nhịp 2
## thường trượt. Muốn cả 2 nhịp đều ăn thì giảm iframes hoặc kéo giãn combo_gap.

var _t := 0.0
var _a1 := 0.12
var _gap := 0.2
var _a2 := 0.14
var _d1 := 12.0
var _d2 := 14.0
var _stage := 0   # 0 = nhịp 1 đang ra, 1 = nghỉ giữa 2 nhịp, 2 = nhịp 2 đang ra


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy as TyrantBoss
	var m := b.attack_speed_mult
	_t = 0.0
	_stage = 0
	_a1 = b.cfg("combo_active_1", 0.12) / m
	_gap = b.cfg("combo_gap", 0.2) / m
	_a2 = b.cfg("combo_active_2", 0.14) / m
	_d1 = b.pcfg("combo_damage_1", 12.0)
	_d2 = b.pcfg("combo_damage_2", 14.0)
	_box(b)
	b.sprite.play(&"attack")
	b.set_sword_pose(TyrantBoss.POSE_SLASH, 0.05)
	b.hitbox.arm(_d1)
	b.velocity.x = b.facing * 0.5 * Config.PX_PER_UNIT / maxf(_a1, 0.01)   # bước nhẹ khi chém


func _box(b: TyrantBoss) -> void:
	var px := Config.PX_PER_UNIT
	var w := b.cfg("combo_width", 2.5) * b.range_mult
	var h := b.cfg("combo_height", 1.5)
	b.hitbox.set_box(Vector2(w, h) * px, Vector2(w * 0.5, -0.9) * px)   # bắt đầu từ giữa người, vươn ra trước


func physics_update(delta: float) -> void:
	var b := enemy as TyrantBoss
	_t += delta
	b.apply_gravity(delta)
	b.move_and_slide()
	if _stage == 0 and _t >= _a1:
		_stage = 1
		b.hitbox.disarm()
		b.velocity.x = 0.0
		b.set_sword_pose(TyrantBoss.POSE_RAISED, _gap)
	elif _stage == 1 and _t >= _a1 + _gap:
		_stage = 2
		b.sprite.play(&"attack")
		b.set_sword_pose(TyrantBoss.POSE_SLASH, 0.04)
		b.hitbox.arm(_d2)
		# Lao tới ngắn: quãng đường combo_lunge u trong thời gian nhịp 2
		b.velocity.x = b.facing * b.cfg("combo_lunge", 2.0) * b.range_mult * Config.PX_PER_UNIT / maxf(_a2, 0.01)
	elif _stage == 2 and _t >= _a1 + _gap + _a2:
		machine.change_to(&"Recover")


func exit() -> void:
	var b := enemy as TyrantBoss
	b.hitbox.disarm()
	b.velocity.x = 0.0
	b.set_sword_pose(TyrantBoss.POSE_REST, 0.2)
