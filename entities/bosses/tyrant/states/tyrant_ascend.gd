extends EnemyState
## Chuyển phase: Tyrant Ascendant. TyrantBoss bật bất tử (nguồn &"phase") rồi vào state này, tổng `ascend_time` (3.2s):
##  1) 0 -> 0.55s : hạ người tích lực, nhấp nháy.
##  2) bật nhảy CAO + XOAY 360 độ kèm đòn QUÉT KIẾM (spin slash):
##       - hitbox tròn `ascend_radius` u, damage `ascend_damage`
##       - đẩy lùi player khi trúng
##  3) tiếp đất: rung màn hình mạnh, sóng xung kích, thân + kiếm chuyển VÀNG SÁNG; đứng khoe sức tới hết thời gian.
## Hết giờ: gỡ bất tử, sang Chase (cường hóa vĩnh viễn đã áp dụng trong TyrantBoss._check_phase).
## Cutscene này không gây sát thương nào ngoài đòn quét kiếm lúc xoay.

const CROUCH := 0.55
const SPIN := 0.70          # xoay lâu hơn một chút để đòn quét rõ
const PUSH_SPEED := 1400.0  # px/s

var _t := 0.0
var _total := 3.2
var _jumped := false
var _landed := false
var _spin_start := 0.0
var _spin_armed := false
var _push_dir := 0.0
var _push_left := 0.0
var _shake_t := 0.0
var _spin_tw: Tween


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy as TyrantBoss
	_t = 0.0
	_total = b.cfg("ascend_time", 3.2)
	_jumped = false
	_landed = false
	_spin_armed = false
	_push_left = 0.0
	_shake_t = 0.0
	b.velocity = Vector2.ZERO
	b.alert = false
	b.sprite.play(&"telegraph")
	b.set_sword_pose(TyrantBoss.POSE_RAISED, CROUCH)
	CamShake.shake(b, 5.0, 0.55)

	# Hitbox quét kiếm (hình tròn quanh người)
	var r := b.cfg("ascend_radius", 4.0) * Config.PX_PER_UNIT
	(b.spin_hitbox.get_node("CollisionShape2D").shape as CircleShape2D).radius = r
	b.spin_hitbox.position = Vector2(0.0, -b.body_height * 0.45)
	if not b.spin_hitbox.hit_landed.is_connected(_on_spin_hit):
		b.spin_hitbox.hit_landed.connect(_on_spin_hit)


func _on_spin_hit(_hurtbox: Hurtbox) -> void:
	var b := enemy as TyrantBoss
	var p := b.get_target()
	if p == null:
		return
	_push_dir = 1.0 if p.global_position.x >= b.global_position.x else -1.0
	_push_left = b.cfg("ascend_push", 5.5) * Config.PX_PER_UNIT


func physics_update(delta: float) -> void:
	var b := enemy as TyrantBoss
	_t += delta
	b.apply_gravity(delta)

	if not _jumped:
		# Giai đoạn tích lực
		b.velocity.x = 0.0
		b.sprite.modulate = Color(1.0, 0.95, 0.4) if int(_t * 14.0) % 2 == 0 else Color.WHITE
		if _t >= CROUCH:
			_start_spin(b)

	elif not _landed:
		# Đang trên không + xoay + quét kiếm
		if _spin_armed and _t >= _spin_start + SPIN:
			_end_spin(b)
		if b.is_on_floor() and _t > _spin_start + 0.18:
			_land(b)

	else:
		# Sau khi tiếp đất – khoe sức
		_shake_t -= delta
		if _shake_t <= 0.0:
			_shake_t = 0.45
			CamShake.shake(b, 3.5, 0.28)
		b.sprite.modulate = Color(1.0, 1.0, 0.7).lerp(Color.WHITE, 0.5 + 0.5 * sin(_t * 18.0))

	b.move_and_slide()
	_push(delta)

	if _t >= _total:
		machine.change_to(&"Chase")


func _start_spin(b: TyrantBoss) -> void:
	_jumped = true
	_spin_start = _t
	b.sprite.modulate = Color.WHITE
	b.sprite.play(&"attack")

	# Nhảy cao hơn rõ rệt (mặc định 3.8u thay vì 1.5u)
	var jump_h := b.cfg("ascend_jump_height", 3.8)
	b.velocity.y = -sqrt(2.0 * b.gravity * jump_h * Config.PX_PER_UNIT)

	# Bật hitbox quét kiếm
	b.spin_hitbox.arm(b.cfg("ascend_damage", 14.0))
	_spin_armed = true

	# Xoay sprite + kiếm 360° (kiếm quay nhanh hơn để tạo cảm giác quét mạnh)
	_spin_tw = b.create_tween().set_parallel(true)
	_spin_tw.tween_property(b.sprite, "rotation", TAU * b.facing, SPIN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spin_tw.tween_property(b.sword, "rotation_degrees", TyrantBoss.POSE_SLASH + 720.0 * b.facing, SPIN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	CamShake.shake(b, 7.0, 0.35)


func _end_spin(b: TyrantBoss) -> void:
	_spin_armed = false
	b.spin_hitbox.disarm()
	b.sprite.rotation = 0.0
	b.set_sword_pose(TyrantBoss.POSE_SLASH)


func _land(b: TyrantBoss) -> void:
	_landed = true
	if _spin_armed:
		_end_spin(b)
	if _spin_tw != null and _spin_tw.is_valid():
		_spin_tw.kill()
	b.sprite.rotation = 0.0
	b.sprite.play(&"telegraph")
	b.enter_mad_look()
	b.set_sword_pose(TyrantBoss.POSE_RAISED, 0.3)
	CamShake.shake(b, 14.0, 0.55)
	SlamFx.spawn(b, SlamFx.Kind.BURST, 5.5 * Config.PX_PER_UNIT, 0.5)   # sóng xung kích (chỉ hình ảnh)


func _push(delta: float) -> void:
	if _push_left <= 0.0:
		return
	var p := (enemy as TyrantBoss).get_target()
	if p == null:
		_push_left = 0.0
		return
	var step := minf(_push_left, PUSH_SPEED * delta)
	p.move_and_collide(Vector2(_push_dir * step, 0.0))
	_push_left -= step


func exit() -> void:
	var b := enemy as TyrantBoss
	b.hurtbox.set_invulnerable(&"phase", false)
	b.spin_hitbox.disarm()
	if b.spin_hitbox.hit_landed.is_connected(_on_spin_hit):
		b.spin_hitbox.hit_landed.disconnect(_on_spin_hit)
	if _spin_tw != null and _spin_tw.is_valid():
		_spin_tw.kill()
	b.sprite.rotation = 0.0
	b.sprite.modulate = Color.WHITE
	b.enter_mad_look()
	b.set_sword_pose(TyrantBoss.POSE_REST, 0.2)
