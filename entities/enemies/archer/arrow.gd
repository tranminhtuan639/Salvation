class_name Arrow
extends Node2D
## Quả cầu lửa bay theo quỹ đạo Parabol, trúng player hoặc chạm sàn thì nổ tung.

@onready var hitbox: Hitbox = $Hitbox
@onready var visual: AnimatedSprite2D = $Visual  
@onready var ground_detector: Area2D = $GroundDetector # Node Area2D vừa thêm để bắt sàn

var _damage := 15.0
var _dir := 1
var _speed := 576.0
var _range := 900.0
var _travelled := 0.0
var _is_exploded := false

var _velocity_y := -350.0  
var _gravity := 1200.0     
var _spawn_timer := 0.0  # Chặn tự nổ vào người con Worm lúc mới bắn


func setup(damage: float, dir: int, speed_px: float, max_range_px: float) -> void:
	_damage = damage
	_dir = dir
	_speed = speed_px
	_range = max_range_px
	_velocity_y = -absf(speed_px) * 0.6


func _ready() -> void:
	scale.x = _dir   
	visual.play("default") 
	
	# 1. Trúng player (Hurtbox) -> Nổ
	hitbox.hit_landed.connect(func(_hurtbox: Hurtbox) -> void:
		if _spawn_timer > 0.08:
			_explode()
	)
	hitbox.arm(_damage)

	# 2. Chạm sàn (TileMap / Body hoặc Area của môi trường) -> Nổ
	if ground_detector:
		ground_detector.body_entered.connect(func(_body: Node2D) -> void:
			if _spawn_timer > 0.08:
				_explode()
		)
		ground_detector.area_entered.connect(func(_area: Area2D) -> void:
			if _spawn_timer > 0.08:
				_explode()
		)


func _physics_process(delta: float) -> void:
	if _is_exploded:
		return

	_spawn_timer += delta

	# Tính toán Parabol vật lý
	_velocity_y += _gravity * delta             
	
	var step_x := _dir * _speed * delta
	var step_y := _velocity_y * delta
	
	position.x += step_x
	position.y += step_y                        
	
	# Xoay đầu quả cầu lửa theo góc bay
	var current_velocity := Vector2(_dir * _speed, _velocity_y)
	rotation = current_velocity.angle() if _dir > 0 else current_velocity.angle() - PI

	# Giới hạn tầm bay xa nhất nếu bay mãi không chạm gì
	_travelled += absf(step_x)
	if _travelled >= _range:
		queue_free()


func _explode() -> void:
	if _is_exploded:
		return
	_is_exploded = true
	
	rotation = 0
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	
	if ground_detector:
		ground_detector.set_deferred("monitoring", false)
	
	visual.play("explosion")
	await visual.animation_finished
	queue_free()