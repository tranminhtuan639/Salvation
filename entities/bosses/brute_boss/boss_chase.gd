extends EnemyState
## Boss đi bộ chậm về phía player. Vào tầm thì chọn đòn:
##  - trong `slam_trigger_range`: Đập đất (Slam) hoặc Húc, không lặp lại đòn vừa dùng 2 lần liên tiếp
##  - trong `charge_trigger_range`: Húc
## (Node này đặt tên "Chase" trong scene để Idle/Hurt/Recover dùng chung chuyển state.)


func enter(_msg: Dictionary = {}) -> void:
	enemy.sprite.play(&"run")


func physics_update(delta: float) -> void:
	var b := enemy as BruteBoss
	if not b.target_alive():
		machine.change_to(&"Idle")
		return

	var px := Config.PX_PER_UNIT
	var dx := b.dx_to_target()
	var dist := absf(dx)
	if dist > b.cfg("aggro_range", 12.0) * px * 1.5:
		machine.change_to(&"Idle")
		return

	b.face(dx)
	b.apply_gravity(delta)
	var charge_range := b.cfg("charge_trigger_range", 6.0) * px
	var in_reach := dist <= charge_range and absf(b.dy_to_target()) <= 3.0 * px
	b.velocity.x = 0.0 if in_reach else b.facing * b.move_speed
	b.move_and_slide()

	if in_reach and b.is_on_floor():
		_pick_attack(b, dist)
		machine.change_to(&"Telegraph")


func _pick_attack(b: BruteBoss, dist: float) -> void:
	var pick := &"Charge"
	if dist <= b.cfg("slam_trigger_range", 2.5) * Config.PX_PER_UNIT:
		pick = &"Slam" if randf() < 0.6 else &"Charge"
		if pick == b.last_attack and b.last_attack == &"Slam":
			pick = &"Charge"
	b.next_attack = pick
	b.last_attack = pick
