extends CanvasLayer
## HUD: thanh máu (có vệt trễ), cooldown 4 skill + dash, buff Lửa, màn hình thua.
## Tự tìm Player qua group "player", nên chỉ cần kéo hud.tscn vào mỗi level.

const SLOT_SIZE := 72.0
## Thứ tự hiển thị trái -> phải
const SLOT_DEFS := [
	{"id": &"skill_wind",  "key": "U", "color": Color(0.45, 0.85, 0.70)},
	{"id": &"skill_water", "key": "I", "color": Color(0.30, 0.60, 1.00)},
	{"id": &"skill_earth", "key": "O", "color": Color(0.65, 0.45, 0.25)},
	{"id": &"skill_fire",  "key": "P", "color": Color(1.00, 0.45, 0.15)},
	{"id": &"dash",        "key": "K", "color": Color(0.65, 0.65, 0.72)},
]

@onready var _hp_bar: ProgressBar = $Root/HpBar
@onready var _hp_trail: ProgressBar = $Root/HpTrail
@onready var _hp_label: Label = $Root/HpLabel
@onready var _buff_label: Label = $Root/BuffLabel
@onready var _skills: HBoxContainer = $Root/Skills
@onready var _game_over: Control = $Root/GameOver
@onready var _retry: Button = $Root/GameOver/Center/Box/Retry

var _player: Player
var _slots: Array[Dictionary] = []
var _hp_tween: Tween
var _trail_tween: Tween


func _ready() -> void:
	_style_bar(_hp_trail, Color(1.0, 0.85, 0.3), Color(0.08, 0.08, 0.1, 0.9))
	_style_bar(_hp_bar, Color(0.85, 0.2, 0.25), Color(0, 0, 0, 0))   # nền trong suốt để thấy vệt trễ phía sau
	_build_slots()
	_game_over.hide()
	_retry.pressed.connect(_on_retry)

	await get_tree().process_frame   # đợi Player chạy xong _ready
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null:
		push_warning("Hud: không thấy Player trong group 'player'")
		return
	_player.health.changed.connect(_on_hp_changed)
	_player.died.connect(_on_player_died)
	_apply_hp(_player.health.current, _player.health.max_hp, true)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var cd: Cooldowns = _player.cooldowns
	for s in _slots:
		var ratio := cd.ratio(s["id"])
		var remaining := cd.remaining(s["id"])
		(s["overlay"] as ColorRect).size = Vector2(SLOT_SIZE, SLOT_SIZE * ratio)
		(s["timer"] as Label).text = "" if remaining <= 0.0 \
				else ("%.1f" % remaining if remaining < 10.0 else str(ceili(remaining)))

	_buff_label.visible = _player.buff_time_left > 0.0
	if _buff_label.visible:
		_buff_label.text = "BUFF LỬA x%.1f  ·  %.1fs" % [_player.damage_mult, _player.buff_time_left]


# ---------------- Máu ----------------

func _on_hp_changed(current: float, maximum: float) -> void:
	_apply_hp(current, maximum, false)


func _apply_hp(current: float, maximum: float, instant: bool) -> void:
	_hp_bar.max_value = maximum
	_hp_trail.max_value = maximum
	_hp_label.text = "%d / %d" % [ceili(current), int(maximum)]
	if _hp_tween != null and _hp_tween.is_valid():
		_hp_tween.kill()
	if _trail_tween != null and _trail_tween.is_valid():
		_trail_tween.kill()
	if instant:
		_hp_bar.value = current
		_hp_trail.value = current
		return
	_hp_tween = create_tween()
	_hp_tween.tween_property(_hp_bar, "value", current, 0.12)
	if current >= _hp_trail.value:
		_hp_trail.value = current   # hồi máu: vệt trễ đi theo luôn
	else:
		_trail_tween = create_tween()
		_trail_tween.tween_property(_hp_trail, "value", current, 0.4).set_delay(0.45)


func _style_bar(bar: ProgressBar, fill: Color, background: Color) -> void:
	var f := StyleBoxFlat.new()
	f.bg_color = fill
	f.set_corner_radius_all(4)
	var b := StyleBoxFlat.new()
	b.bg_color = background
	b.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", f)
	bar.add_theme_stylebox_override("background", b)


# ---------------- Ô skill ----------------

func _build_slots() -> void:
	for def in SLOT_DEFS:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)

		var bg := ColorRect.new()
		bg.color = def["color"]
		bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.add_child(bg)

		var overlay := ColorRect.new()   # phủ tối từ trên xuống, tỉ lệ = phần cooldown còn lại
		overlay.color = Color(0, 0, 0, 0.7)
		overlay.size = Vector2(SLOT_SIZE, 0.0)
		slot.add_child(overlay)

		var key_label := Label.new()
		key_label.text = def["key"]
		key_label.position = Vector2(6, 2)
		_outline(key_label, 18)
		slot.add_child(key_label)

		var timer := Label.new()
		timer.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_outline(timer, 26)
		slot.add_child(timer)

		_skills.add_child(slot)
		_slots.append({"id": def["id"], "overlay": overlay, "timer": timer})


func _outline(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color.BLACK)


# ---------------- Thua ----------------

func _on_player_died() -> void:
	await get_tree().create_timer(1.0).timeout   # cho xem nốt animation ngã
	_game_over.show()
	_retry.grab_focus()   # Enter / Space cũng bấm được


func _on_retry() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
