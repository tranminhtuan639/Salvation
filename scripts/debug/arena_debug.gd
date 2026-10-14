extends Node2D
## DEBUG TẠM cho test_arena. Xóa khi làm HUD thật.

@onready var player: Player = $Player
@onready var dummy = $Dummy
var _label: Label

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(16, 12)
	layer.add_child(_label)

func _process(_delta: float) -> void:
	var p := player
	var s := "HP %d / %d\nState: %s\nMiễn sát thương: %s\nBuff x%.1f\n" % [
		p.health.current, p.health.max_hp, p.machine.current.name,
		p.hurtbox.is_invulnerable(), p.damage_mult]
	for id in [&"dash", &"skill_wind", &"skill_water", &"skill_earth", &"skill_fire"]:
		s += "%s: %.1fs\n" % [id, p.cooldowns.remaining(id)]
	s += "\n[T] player ăn 30 dmg   [R] reset dummy"
	_label.text = s

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_T:
				if player.hurtbox.is_invulnerable():
					print("Player đang miễn sát thương -> không mất máu")
				else:
					player.health.take_damage(30.0)
			KEY_R:
				dummy.health.setup(200.0)
