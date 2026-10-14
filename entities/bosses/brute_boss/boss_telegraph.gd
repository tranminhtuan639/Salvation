extends EnemyState
## Báo hiệu của boss: thời gian tùy đòn (charge_telegraph 0.6 / slam_telegraph 0.7), chia cho attack_speed_mult.
## Slam có thêm vòng cảnh báo đỏ trên mặt đất, lấp đầy dần đúng bằng thời gian telegraph.
## Xong thì chuyển sang state trùng tên đòn (Charge / Slam). Hướng bị khóa lúc vào state.

var _t := 0.0
var _dur := 0.6
var _next := &"Charge"


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy as BruteBoss
	_t = 0.0
	_next = b.next_attack
	var key := "slam_telegraph" if _next == &"Slam" else "charge_telegraph"
	_dur = b.cfg(key, 0.6) / b.attack_speed_mult
	b.velocity.x = 0.0
	b.face(b.dx_to_target())
	b.alert = true
	b.sprite.play(&"telegraph")
	if _next == &"Slam":
		SlamFx.spawn(b, SlamFx.Kind.WARN, b.cfg("slam_radius", 3.0) * Config.PX_PER_UNIT, _dur)


func physics_update(delta: float) -> void:
	var e := enemy
	_t += delta
	e.apply_gravity(delta)
	e.move_and_slide()
	e.sprite.modulate = Color(1.0, 0.5, 0.5) if int(_t * 14.0) % 2 == 0 else Color.WHITE
	if _t >= _dur:
		machine.change_to(_next)


func exit() -> void:
	enemy.alert = false
	enemy.sprite.modulate = Color.WHITE
