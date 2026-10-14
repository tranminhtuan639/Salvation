extends AttackState
## Lửa: chém liên tiếp `skill.fire.hits` nhát (mặc định 4). Chém đủ cả loạt thì được buff sát thương.
## Mỗi nhát: bật hitbox ngắn rồi TẮT, để nhát sau bật lại thì mục tiêu đang đứng sát vẫn ăn đòn tiếp.
## Bị đánh trúng giữa chừng (Hurt) thì loạt chém bị ngắt và KHÔNG có buff.

@export var pulse_len := 0.12                          # thời gian mỗi nhát (giây)
@export_range(0.1, 1.0) var pulse_on_ratio := 0.5      # phần đầu mỗi nhát mà hitbox bật

var _hits := 4
var _pulse := 0            # số nhát đã bắn
var _buff_given := false


func enter(msg: Dictionary = {}) -> void:
	_hits = maxi(1, int(Config.get_value("skill.fire.hits", 4.0)))
	_pulse = 0
	_buff_given = false
	active = _hits * pulse_len    # tổng pha active = số nhát x thời gian mỗi nhát
	super.enter(msg)


func physics_update(delta: float) -> void:
	var p := player
	_t += delta
	p.apply_gravity(delta)

	var in_active := _t >= startup and _t < startup + active
	if in_active:
		var elapsed := _t - startup
		var idx := mini(int(elapsed / pulse_len), _hits - 1)
		if idx >= _pulse:
			_pulse = idx + 1
			p.hitbox.arm(Config.get_value(config_prefix + ".damage", 14.0) * p.damage_mult)
		elif elapsed - idx * pulse_len >= pulse_len * pulse_on_ratio:
			p.hitbox.disarm()
		p.velocity.x = p.facing * lunge * Config.PX_PER_UNIT / maxf(active, 0.01)
	else:
		p.hitbox.disarm()
		p.velocity.x = 0.0

	# Chém xong đủ loạt thì mới buff (buff không ảnh hưởng chính loạt này)
	if not _buff_given and _t >= startup + active:
		_buff_given = true
		p.add_damage_buff(Config.get_value("skill.fire.buff_mult", 1.3),
				Config.get_value("skill.fire.buff_duration", 8.0))

	p.move_and_slide()

	if _t >= _total:
		machine.change_to(&"Idle")
		return
	_try_cancel()


func _on_hit(_hurtbox: Hurtbox) -> void:
	Fx.hit_stop(0.03)   # nhẹ hơn đánh thường vì có 4 nhát liên tiếp
