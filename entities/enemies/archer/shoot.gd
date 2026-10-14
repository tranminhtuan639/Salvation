extends EnemyState
## Bắn: thả mũi tên nhắm vào ngực player tại thời điểm thả, rồi giữ tư thế `attack_active` giây sang Recover.
## (Node này đặt tên "Attack" trong scene để dùng chung Telegraph với Grunt.)

const ARROW := preload("res://entities/enemies/archer/arrow.tscn")

@export var muzzle_forward := 0.7   # u, mũi tên xuất hiện cách người bao xa theo hướng mặt
@export var chest_height := 60.0    # px, độ cao nhắm so với chân player

var _t := 0.0


func enter(_msg: Dictionary = {}) -> void:
	var e := enemy
	var px := Config.PX_PER_UNIT
	_t = 0.0
	e.velocity.x = 0.0
	e.sprite.play(&"attack")

	var arrow := ARROW.instantiate() as Arrow
	arrow.setup(e.cfg("damage", 15.0), e.facing, e.cfg("arrow_speed", 9.0) * px, e.cfg("arrow_range", 14.0) * px)
	e.get_parent().add_child(arrow)
	var aim_y := e.get_target().global_position.y - chest_height
	arrow.global_position = Vector2(e.global_position.x + e.facing * muzzle_forward * px, aim_y)


func physics_update(delta: float) -> void:
	var e := enemy
	_t += delta
	e.apply_gravity(delta)
	e.move_and_slide()
	if _t >= e.cfg("attack_active", 0.15):
		machine.change_to(&"Recover")
