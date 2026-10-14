extends EnemyState
## Húc: lao thẳng về phía trước `charge_distance` u với tốc độ `charge_speed` u/s, hitbox bật suốt cú lao.
## Dừng khi đủ quãng đường hoặc đâm vào tường, rồi sang Recover (dừng thở).
## Hướng đã bị khóa từ Telegraph nên player dash xuyên qua / né sang bên là trượt.
## (Node này đặt tên "Attack" trong scene Brute và "Charge" trong scene Boss.)
## Damage đọc từ cfg("damage").

@export var hitbox_size := Vector2(1.3, 1.2)      # u
@export var hitbox_offset := Vector2(0.8, -0.7)   # u, x dương = phía trước mặt

var _start_x := 0.0
var _distance := 5.0


func enter(_msg: Dictionary = {}) -> void:
	var e := enemy
	var px := Config.PX_PER_UNIT
	_start_x = e.global_position.x
	_distance = e.cfg("charge_distance", 5.0) * px
	e.sprite.play(&"attack")
	e.hitbox.set_box(hitbox_size * px, hitbox_offset * px)
	e.hitbox.arm(e.cfg("damage", 15.0))
	e.velocity.x = e.facing * e.cfg("charge_speed", 10.0) * px * e.attack_speed_mult


func physics_update(delta: float) -> void:
	var e := enemy
	e.apply_gravity(delta)
	e.move_and_slide()
	if absf(e.global_position.x - _start_x) >= _distance or e.is_on_wall():
		machine.change_to(&"Recover")


func exit() -> void:
	enemy.hitbox.disarm()
	enemy.velocity.x = 0.0
