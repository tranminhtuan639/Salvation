class_name Enemy
extends CharacterBody2D
## Khung chung cho mọi quái thường. Chỉ số đọc từ Config theo `config_prefix`:
## "enemy.grunt" -> enemy.grunt.hp, enemy.grunt.damage, ...  (xem cfg())

signal died(enemy: Enemy)

@export var config_prefix := "enemy.grunt"
@export var body_height := 100.0   # px, để đặt thanh máu / dấu "!" phía trên đầu

@onready var pivot: Node2D = $Pivot
@onready var sprite: AnimatedSprite2D = $Pivot/Sprite
@onready var hitbox: Hitbox = $Pivot/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $Health
@onready var machine: StateMachine = $StateMachine

var facing := 1
var move_speed := 0.0
var gravity := 0.0
var target: Player

## Telegraph bật cờ này để vẽ dấu "!" báo hiệu đòn sắp tới.
var alert := false:
	set(value):
		alert = value
		queue_redraw()


func _ready() -> void:
	add_to_group(&"enemy")
	move_speed = cfg("move_speed", 3.0) * Config.PX_PER_UNIT
	gravity = Config.get_value("enemy.gravity", 35.0) * Config.PX_PER_UNIT
	health.setup(cfg("hp", 50.0))
	hurtbox.health = health
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health.changed.connect(func(_c: float, _m: float) -> void: queue_redraw())
	machine.setup(self)


## Đọc chỉ số của riêng quái này: cfg("hp") -> Config["<prefix>.hp"]
func cfg(stat: String, fallback := 0.0) -> float:
	return Config.get_value(config_prefix + "." + stat, fallback)


func get_target() -> Player:
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player") as Player
	return target


func target_alive() -> bool:
	var t := get_target()
	return t != null and t.health.current > 0.0


func dx_to_target() -> float:
	return get_target().global_position.x - global_position.x


func dy_to_target() -> float:
	return get_target().global_position.y - global_position.y


func face(dir: float) -> void:
	if dir == 0.0:
		return
	facing = 1 if dir > 0.0 else -1
	pivot.scale.x = facing


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _on_damaged(_amount: float, from_position: Vector2) -> void:
	if health.current <= 0.0:
		return   # chết rồi thì _on_died lo
	machine.change_to(&"Hurt", {"from_x": from_position.x})


func _on_died() -> void:
	machine.change_to(&"Dead")
	died.emit(self)


func _draw() -> void:
	if health == null or health.current <= 0.0:
		return
	var top := -body_height - 18.0
	if health.current < health.max_hp:   # thanh máu chỉ hiện khi đã bị đánh
		var w := 60.0
		draw_rect(Rect2(-w / 2.0, top, w, 6.0), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-w / 2.0, top, w * health.current / health.max_hp, 6.0), Color(0.85, 0.2, 0.25))
	if alert:
		draw_string(ThemeDB.fallback_font, Vector2(-7.0, top - 6.0), "!",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1.0, 0.9, 0.2))
