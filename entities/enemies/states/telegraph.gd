extends EnemyState
## Báo hiệu đòn: đứng yên `telegraph` giây, nhấp nháy đỏ + dấu "!". Hướng bị KHÓA ngay lúc vào state,
## nên player né sang bên kia hoặc dash xuyên qua là trượt. Bị đánh trúng thì bị ngắt (qua Hurt).

var _t := 0.0
var _dur := 0.5


func enter(_msg: Dictionary = {}) -> void:
	var e := enemy
	_t = 0.0
	_dur = e.cfg("telegraph", 0.5)
	e.velocity.x = 0.0
	e.face(e.dx_to_target())
	e.alert = true
	e.sprite.play(&"telegraph")


func physics_update(delta: float) -> void:
	var e := enemy
	_t += delta
	e.apply_gravity(delta)
	e.move_and_slide()
	e.sprite.modulate = Color(1.0, 0.35, 0.35) if int(_t * 14.0) % 2 == 0 else Color.WHITE
	if _t >= _dur:
		machine.change_to(&"Attack")


func exit() -> void:
	enemy.alert = false
	enemy.sprite.modulate = Color.WHITE
