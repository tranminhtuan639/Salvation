class_name Player
extends CharacterBody2D

signal died   # HUD nghe để hiện màn hình thua

## action input -> tên node state
const SKILL_ACTIONS := {
	&"skill_wind": &"SkillWind",
	&"skill_water": &"SkillWater",
	&"skill_earth": &"SkillEarth",
	&"skill_fire": &"SkillFire",
}

@onready var pivot: Node2D = $Pivot
@onready var sprite: AnimatedSprite2D = $Pivot/Sprite
@onready var hitbox: Hitbox = $Pivot/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $Health
@onready var cooldowns: Cooldowns = $Cooldowns
@onready var input_buffer: InputBuffer = $InputBuffer
@onready var machine: StateMachine = $StateMachine

var facing := 1
var damage_mult := 1.0
var move_speed := 0.0
var gravity := 0.0
var jump_velocity := 0.0
var max_fall_speed := 0.0
var buff_time_left := 0.0   # giây còn lại của buff sát thương (Lửa)


func _ready() -> void:
	add_to_group(&"player")   # HUD tìm player qua group này
	var px := Config.PX_PER_UNIT
	move_speed = Config.get_value("player.move_speed", 6.0) * px
	gravity = Config.get_value("player.gravity", 35.0) * px
	max_fall_speed = 20.0 * px
	# v = sqrt(2 * g * h)
	jump_velocity = -sqrt(2.0 * gravity * Config.get_value("player.jump_height", 3.0) * px)
	health.setup(Config.get_value("player.hp", 100.0))
	hurtbox.health = health
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	machine.setup(self)


func get_move_input() -> float:
	return Input.get_axis(&"move_left", &"move_right")


func face(dir: float) -> void:
	if dir == 0.0:
		return
	facing = 1 if dir > 0.0 else -1
	pivot.scale.x = facing


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


## Skill nào có lệnh trong buffer và đã hết cooldown thì trả về tên state của nó.
func poll_skill() -> StringName:
	for action in SKILL_ACTIONS:
		if cooldowns.is_ready(action) and input_buffer.consume(action):
			return SKILL_ACTIONS[action]
	return &""


## Dùng ở trạng thái tự do (Idle/Run/Air): trả về state kế tiếp nếu có lệnh.
func poll_actions() -> StringName:
	if cooldowns.is_ready(&"dash") and input_buffer.consume(&"dash"):
		return &"Dash"
	var skill := poll_skill()
	if skill != &"":
		return skill
	if input_buffer.consume(&"attack"):
		return &"Attack1"
	return &""


## Gọi lại khi đang buff thì làm mới thời gian, không cộng dồn.
func add_damage_buff(mult: float, duration: float) -> void:
	damage_mult = mult
	buff_time_left = duration


func clear_buff() -> void:
	damage_mult = 1.0
	buff_time_left = 0.0


## Miễn sát thương tạm thời theo nguồn (hurt, ...), tự tắt sau `duration` giây.
func grant_iframes(source: StringName, duration: float) -> void:
	hurtbox.set_invulnerable(source, true)
	await get_tree().create_timer(duration).timeout
	hurtbox.set_invulnerable(source, false)


func _physics_process(delta: float) -> void:
	if buff_time_left > 0.0:
		buff_time_left -= delta
		if buff_time_left <= 0.0:
			clear_buff()


## Nhấp nháy khi đang i-frame sau bị đánh, ám cam khi có buff Lửa.
func _process(_delta: float) -> void:
	var tint := Color(1.0, 0.8, 0.6) if buff_time_left > 0.0 else Color.WHITE
	if hurtbox.has_invuln(&"hurt") and int(Time.get_ticks_msec() / 80.0) % 2 == 0:
		tint.a = 0.35
	sprite.modulate = tint


func _on_damaged(_amount: float, from_position: Vector2) -> void:
	if health.current <= 0.0:
		return   # chết rồi thì _on_died lo
	var msg := {}
	if from_position != Vector2.ZERO:
		msg["from_x"] = from_position.x
	machine.change_to(&"Hurt", msg)


func _on_died() -> void:
	machine.change_to(&"Dead")
	died.emit()
