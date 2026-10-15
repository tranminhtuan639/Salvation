extends EnemyState
## Báo hiệu: đứng yên `<đòn>_telegraph` giây (đọc từ Config theo phase), nhấp nháy + dấu "!" + giơ kiếm.
## Hướng bị khóa lúc vào state (player đổi bên / dash xuyên là trượt). Xong thì sang state trùng tên đòn.

var _t := 0.0
var _dur := 0.4
var _next := &"Combo"


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy as TyrantBoss
	_t = 0.0
	_next = b.next_attack
	_dur = b.telegraph_time(_next)
	b.velocity.x = 0.0
	b.face(b.dx_to_target())
	b.alert = true
	b.sprite.play(&"telegraph")
	b.set_sword_pose(TyrantBoss.POSE_RAISED, _dur * 0.9)
	if _next == &"Wrath":
		b.sprite.scale = Vector2(b.sprite.scale.x * 1.1, b.sprite.scale.y * 0.88)   # hạ trọng tâm


func physics_update(delta: float) -> void:
	var b := enemy as TyrantBoss
	_t += delta
	b.apply_gravity(delta)
	b.move_and_slide()
	var flash := Color(1.0, 0.45, 0.45) if b.phase == 1 else Color(1.0, 0.95, 0.35)
	b.sprite.modulate = flash if int(_t * 16.0) % 2 == 0 else Color.WHITE
	if _t >= _dur:
		machine.change_to(_next)


func exit() -> void:
	var b := enemy as TyrantBoss
	b.alert = false
	b.sprite.modulate = Color.WHITE
	b.reset_sprite_scale()
