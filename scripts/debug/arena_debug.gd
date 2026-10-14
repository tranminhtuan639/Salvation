extends Node2D
## DEBUG TẠM cho test_arena (gắn vào node gốc TestArena). HUD thật đã có, file này chỉ để test.
## Phím: T = player ăn 30 dmg (đẩy lùi khỏi dummy), Y = player ăn 500 dmg (thử chết), R = reset dummy.

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
	_label.text = "State: %s\nMiễn sát thương: %s\nBuff x%.1f (%.1fs)\n\n[T] ăn 30 dmg  [Y] chết  [R] reset dummy" % [
		p.machine.current.name, p.hurtbox.is_invulnerable(), p.damage_mult, p.buff_time_left]

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
