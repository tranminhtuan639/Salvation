class_name Arrow
extends Node2D
## Mũi tên bay ngang theo một hướng cố định. Trúng player thì biến mất; nếu player đang miễn sát thương
## (dash, skill Đất, i-frame) thì mũi tên xuyên qua, và vì mỗi mục tiêu chỉ ăn 1 lần/đòn nên không quay lại trúng nữa.
## Bay hết `max_range` thì tự xóa.

@onready var hitbox: Hitbox = $Hitbox

var _damage := 15.0
var _dir := 1
var _speed := 576.0
var _range := 900.0
var _travelled := 0.0


## Gọi TRƯỚC khi add_child.
func setup(damage: float, dir: int, speed_px: float, max_range_px: float) -> void:
	_damage = damage
	_dir = dir
	_speed = speed_px
	_range = max_range_px


func _ready() -> void:
	scale.x = _dir   # lật hình lẫn hitbox theo hướng bay
	hitbox.hit_landed.connect(func(_hurtbox: Hurtbox) -> void: queue_free())
	hitbox.arm(_damage)


func _physics_process(delta: float) -> void:
	var step := _dir * _speed * delta
	position.x += step
	_travelled += absf(step)
	if _travelled >= _range:
		queue_free()
