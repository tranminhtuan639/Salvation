extends Node2D
## DEBUG TẠM cho test_arena (gắn vào node gốc TestArena). HUD thật đã có, file này chỉ để test.
## Phím: T = player ăn 30 dmg, Y = player ăn 500 dmg (thử chết), R = reset dummy, G = spawn Grunt, H = spawn Archer, B = spawn Brute, N = spawn Boss Brute.

const GRUNT := preload("res://entities/enemies/grunt/grunt.tscn")
const ARCHER := preload("res://entities/enemies/archer/archer.tscn")
const BRUTE := preload("res://entities/enemies/brute/brute.tscn")
const BRUTE_BOSS := preload("res://entities/bosses/brute_boss/brute_boss.tscn")

@onready var player: Player = $Player
@onready var dummy = $Dummy
var _label: Label

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(900, 12)   # góc phải, tránh đè HUD ở góc trái
	layer.add_child(_label)

func _process(_delta: float) -> void:
	var p := player
	_label.text = "State: %s\nMiễn sát thương: %s\nBuff x%.1f (%.1fs)\nQuái đang sống: %d\n\n[T] ăn 30 dmg  [Y] chết\n[R] reset dummy\n[G] Grunt  [H] Archer  [B] Brute  [N] Boss" % [
		p.machine.current.name, p.hurtbox.is_invulnerable(), p.damage_mult, p.buff_time_left,
		get_tree().get_nodes_in_group(&"enemy").size()]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_T:
				if player.hurtbox.is_invulnerable():
					print("Player đang miễn sát thương -> không mất máu")
				else:
					player.health.take_damage(30.0, dummy.global_position)
			KEY_Y:
				player.health.take_damage(500.0, dummy.global_position)
			KEY_R:
				dummy.health.setup(200.0)
			KEY_G:
				_spawn(GRUNT)
			KEY_H:
				_spawn(ARCHER)
			KEY_B:
				_spawn(BRUTE)
			KEY_N:
				_spawn(BRUTE_BOSS)

## Spawn ở phía xa hơn so với player, trong khung hình (camera đứng yên, rộng 1280).
func _spawn(scene: PackedScene) -> void:
	var e := scene.instantiate()
	e.position = Vector2(1150.0 if player.position.x < 640.0 else 130.0, 618.0)
	add_child(e)
