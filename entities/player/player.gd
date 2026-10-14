class_name Player
extends CharacterBody2D

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


func _ready() -> void:
	var px := Config.PX_PER_UNIT
	move_speed = Config.get_value("player.move_speed", 6.0) * px
	gravity = Config.get_value("player.gravity", 35.0) * px
	max_fall_speed = 20.0 * px
	# v = sqrt(2 * g * h)
	jump_velocity = -sqrt(2.0 * gravity * Config.get_value("player.jump_height", 3.0) * px)
	health.setup(Config.get_value("player.hp", 100.0))
	hurtbox.health = health
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


func add_damage_buff(mult: float, duration: float) -> void:
	damage_mult = mult
	await get_tree().create_timer(duration).timeout
	damage_mult = 1.0
