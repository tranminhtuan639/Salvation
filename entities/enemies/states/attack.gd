extends EnemyState
## Cú đánh: hitbox bật trong `attack_active` giây, lao nhẹ về phía trước. Sau đó sang Recover.

@export var hitbox_size := Vector2(1.4, 1.0)      # đơn vị u
@export var hitbox_offset := Vector2(0.9, -0.8)   # đơn vị u, x dương = phía trước mặt
@export var lunge := 0.6                          # u, lao tới trong lúc đánh

var _t := 0.0
var _active := 0.15


func enter(_msg: Dictionary = {}) -> void:
	var e := enemy
	var px := Config.PX_PER_UNIT
	_t = 0.0
	_active = e.cfg("attack_active", 0.15)
	e.sprite.play(&"attack")
	e.hitbox.set_box(hitbox_size * px, hitbox_offset * px)
	e.hitbox.arm(e.cfg("damage", 5.0))
	e.velocity.x = e.facing * lunge * px / maxf(_active, 0.01)


func physics_update(delta: float) -> void:
	var e := enemy
	_t += delta
	e.apply_gravity(delta)
	e.move_and_slide()
	if _t >= _active:
		machine.change_to(&"Recover")


func exit() -> void:
	enemy.hitbox.disarm()
	enemy.velocity.x = 0.0
