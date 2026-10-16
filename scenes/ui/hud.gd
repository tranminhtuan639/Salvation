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
@onready var _objective: Label = $Root/ObjectiveLabel
@onready var _victory: Control = $Root/Victory
@onready var _victory_stats: Label = $Root/Victory/Center/Box/Stats
@onready var _victory_retry: Button = $Root/Victory/Center/Box/Retry
@onready var _victory_status: Label = $Root/Victory/Center/Box/RunStatus
@onready var _gameover_status: Label = $Root/GameOver/Center/Box/RunStatus

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const BOSS_BAR_W := 520.0   # px, canh giữa phía trên (nằm lọt giữa máu player bên trái và mục tiêu bên phải)
const BOSS_BAR_H := 22.0

var _player: Player
var _boss: Enemy
var _boss_root: Control
var _boss_bar: ProgressBar
var _boss_trail: ProgressBar
var _boss_name: Label
var _boss_hp_label: Label
var _boss_mark: ColorRect
var _boss_w := BOSS_BAR_W
var _boss_tween: Tween
var _boss_trail_tween: Tween
var _run_status := ""
var _next_scene := ""
var _next_text := "Stage tiếp"
var _banner: Control
var _banner_stats: Label
var _banner_status: Label
var _arrow_root: Control
var _arrow: Label
var _arrow_tween: Tween
var _next_btn: Button
var _victory_menu_btn: Button
var _slots: Array[Dictionary] = []
var _hp_tween: Tween
var _trail_tween: Tween


func _ready() -> void:
	_style_bar(_hp_trail, Color(1.0, 0.85, 0.3), Color(0.08, 0.08, 0.1, 0.9))
	_style_bar(_hp_bar, Color(0.85, 0.2, 0.25), Color(0, 0, 0, 0))   # nền trong suốt để thấy vệt trễ phía sau
	_build_slots()
	_build_boss_bar()
	_build_clear_banner()
	_build_go_arrow()
	add_to_group(&"hud")   # Level tìm HUD qua group này
	_game_over.hide()
	_victory.hide()
	_retry.pressed.connect(_on_retry)
	_victory_retry.pressed.connect(_on_retry)
	_add_menu_button(_retry.get_parent())
	_victory_menu_btn = _add_menu_button(_victory_retry.get_parent())
	Runs.submitted.connect(_on_run_submitted)

	await get_tree().process_frame   # đợi Player chạy xong _ready
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null:
		push_warning("Hud: không thấy Player trong group 'player'")
		return
	_player.health.changed.connect(_on_hp_changed)
	_player.died.connect(_on_player_died)
	_apply_hp(_player.health.current, _player.health.max_hp, true)


func _process(_delta: float) -> void:
	_poll_boss()
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


# ---------------- Thanh máu boss ----------------
## Tự tìm boss qua group "boss" (kể cả boss spawn muộn). Thanh hiện khi boss bắt đầu giao chiến
## (rời Idle) và mờ dần khi boss chết. Dùng chung kiểu vệt trễ với thanh máu player.

func _build_boss_bar() -> void:
	_boss_root = Control.new()
	_boss_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_root.anchor_left = 0.5
	_boss_root.anchor_right = 0.5
	_boss_root.offset_left = -_boss_w / 2.0
	_boss_root.offset_right = _boss_w / 2.0
	_boss_root.offset_top = 14.0
	_boss_root.offset_bottom = 14.0 + 26.0 + BOSS_BAR_H
	$Root.add_child(_boss_root)

	_boss_name = Label.new()
	_boss_name.size = Vector2(_boss_w, 26.0)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline(_boss_name, 20)
	_boss_root.add_child(_boss_name)

	_boss_trail = _make_boss_bar(Color(1.0, 0.85, 0.3), Color(0.08, 0.08, 0.1, 0.9))
	_boss_bar = _make_boss_bar(Color(0.8, 0.12, 0.2), Color(0, 0, 0, 0))

	_boss_mark = ColorRect.new()   # vạch 50% máu: dưới mức này boss enrage / sang phase 2
	_boss_mark.color = Color(1, 1, 1, 0.6)
	_boss_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_mark.position = Vector2(_boss_w * 0.5 - 1.0, 26.0)
	_boss_mark.size = Vector2(2.0, BOSS_BAR_H)
	_boss_root.add_child(_boss_mark)

	_boss_hp_label = Label.new()
	_boss_hp_label.position = Vector2(0, 26.0)
	_boss_hp_label.size = Vector2(_boss_w, BOSS_BAR_H)
	_boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_outline(_boss_hp_label, 14)
	_boss_root.add_child(_boss_hp_label)

	_boss_root.modulate.a = 0.0
	_boss_root.hide()


func _make_boss_bar(fill: Color, background: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = Vector2(0, 26.0)
	bar.size = Vector2(_boss_w, BOSS_BAR_H)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_bar(bar, fill, background)
	_boss_root.add_child(bar)
	return bar


func _poll_boss() -> void:
	if _boss != null and is_instance_valid(_boss):
		return
	_boss = null
	var b := get_tree().get_first_node_in_group(&"boss") as Enemy
	if b == null or b.health.current <= 0.0:
		return
	_boss = b
	var n: Variant = b.get(&"boss_name")
	_boss_name.text = str(n) if n != null else "BOSS"
	var w: Variant = b.get(&"boss_bar_width")   # boss nào cần thanh to hơn thì khai báo boss_bar_width
	_set_boss_bar_width(float(w) if w != null else BOSS_BAR_W)
	_style_bar(_boss_bar, Color(0.8, 0.12, 0.2), Color(0, 0, 0, 0))
	if b.has_signal(&"phase_changed"):
		b.connect(&"phase_changed", _on_boss_phase_changed)
	_apply_boss_hp(b.health.current, b.health.max_hp, true)
	b.health.changed.connect(func(c: float, m: float) -> void: _apply_boss_hp(c, m, false))
	b.died.connect(_on_boss_died)
	b.machine.state_changed.connect(func(_from: StringName, to: StringName) -> void:
		if to != &"Idle":
			_show_boss_bar())
	if b.machine.current != null and b.machine.current.name != &"Idle":
		_show_boss_bar()


func _set_boss_bar_width(w: float) -> void:
	_boss_w = w
	_boss_root.offset_left = -w / 2.0
	_boss_root.offset_right = w / 2.0
	_boss_name.size.x = w
	_boss_hp_label.size.x = w
	_boss_bar.size.x = w
	_boss_trail.size.x = w
	_boss_mark.position.x = w * 0.5 - 1.0


## Boss nhiều phase: đổi tên theo phase (boss.phase_title()), thanh máu chuyển vàng, tên chớp sáng.
func _on_boss_phase_changed(_phase: int) -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	if _boss.has_method(&"phase_title"):
		_boss_name.text = _boss.call(&"phase_title")
	_style_bar(_boss_bar, Color(1.0, 0.78, 0.15), Color(0, 0, 0, 0))
	var tw := create_tween()
	tw.tween_property(_boss_name, "modulate", Color(1.0, 0.9, 0.3), 0.15)
	tw.tween_property(_boss_name, "modulate", Color.WHITE, 0.6)


func _show_boss_bar() -> void:
	if _boss_root.visible:
		return
	_boss_root.show()
	create_tween().tween_property(_boss_root, "modulate:a", 1.0, 0.4)


func _on_boss_died(_e: Enemy) -> void:
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(_boss_root, "modulate:a", 0.0, 0.6)
	tw.tween_callback(_boss_root.hide)


func _apply_boss_hp(current: float, maximum: float, instant: bool) -> void:
	_boss_bar.max_value = maximum
	_boss_trail.max_value = maximum
	_boss_hp_label.text = "%d / %d" % [ceili(current), int(maximum)]
	if _boss_tween != null and _boss_tween.is_valid():
		_boss_tween.kill()
	if _boss_trail_tween != null and _boss_trail_tween.is_valid():
		_boss_trail_tween.kill()
	if instant:
		_boss_bar.value = current
		_boss_trail.value = current
		return
	_boss_tween = create_tween()
	_boss_tween.tween_property(_boss_bar, "value", current, 0.12)
	if current >= _boss_trail.value:
		_boss_trail.value = current
	else:
		_boss_trail_tween = create_tween()
		_boss_trail_tween.tween_property(_boss_trail, "value", current, 0.5).set_delay(0.45)


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


# ---------------- Mục tiêu & thắng stage ----------------

func set_objective(text: String) -> void:
	_objective.text = text
	_objective.show()


func show_victory(clear_time_ms: int, kills: int, total: int, hp_left: float) -> void:
	var secs := clear_time_ms / 1000.0
	_victory_stats.text = "Thời gian:  %02d:%04.1f\nHạ quái:  %d / %d\nMáu còn lại:  %d" % [
		floori(secs / 60.0), fmod(secs, 60.0), kills, total, ceili(hp_left)]
	if _run_status == "":
		set_run_status("Đang nộp kết quả...")
	if _next_scene != "" and _next_btn == null:
		_next_btn = Button.new()
		_next_btn.text = _next_text
		_next_btn.custom_minimum_size = Vector2(200, 48)
		_next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var box := _victory_retry.get_parent()
		box.add_child(_next_btn)
		box.move_child(_next_btn, _victory_retry.get_index())   # "Tiếp tục" nằm trên "Chơi lại"
		_next_btn.pressed.connect(_on_next)
	_victory_menu_btn.visible = _next_scene != MENU_SCENE   # nút "tiếp" đã dẫn về menu thì khỏi hiện trùng
	_victory.show()
	if _next_btn != null:
		_next_btn.grab_focus()
	else:
		_victory_retry.grab_focus()


## Level gọi khi có scene kế tiếp: màn thắng sẽ hiện nút với chữ `text`.
func set_next_scene(path: String, text := "Stage tiếp") -> void:
	_next_scene = path
	_next_text = text


func _add_menu_button(box: Node) -> Button:
	var b := Button.new()
	b.text = "Về menu chính"
	b.custom_minimum_size = Vector2(200, 48)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_on_menu)
	box.add_child(b)
	return b


func _on_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_next() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(_next_scene)


func _on_run_submitted(text: String, _response: Dictionary) -> void:
	set_run_status(text)


## Dòng trạng thái nộp kết quả lên backend, hiện ở cả màn thắng lẫn màn thua.
func set_run_status(text: String) -> void:
	_run_status = text
	if _banner_status != null:
		_banner_status.text = text
	_victory_status.text = text
	_gameover_status.text = text


# ---------------- Báo hiệu qua cổng (stage có ExitGate) ----------------
## Thay cho bảng thắng: banner nhỏ phía trên + mũi tên đỏ ở mép phải chỉ hướng tới cổng, không chặn gameplay.

func _build_clear_banner() -> void:
	_banner = VBoxContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.offset_left = -300.0
	_banner.offset_right = 300.0
	_banner.offset_top = 84.0   # nằm dưới thanh máu boss
	$Root.add_child(_banner)

	var title := Label.new()
	title.text = "HOÀN THÀNH STAGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_outline(title, 30)
	_banner.add_child(title)

	_banner_stats = Label.new()
	_banner_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline(_banner_stats, 20)
	_banner.add_child(_banner_stats)

	_banner_status = Label.new()
	_banner_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_status.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	_outline(_banner_status, 16)
	_banner.add_child(_banner_status)

	var hint := Label.new()
	hint.text = "Chạy sang phải để qua cổng"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline(hint, 18)
	_banner.add_child(hint)

	_banner.modulate.a = 0.0
	_banner.hide()


func show_clear_banner(clear_time_ms: int, kills: int, total: int, hp_left: float) -> void:
	var secs := clear_time_ms / 1000.0
	_banner_stats.text = "Thời gian %02d:%04.1f  ·  Hạ quái %d/%d  ·  Máu còn %d" % [
		floori(secs / 60.0), fmod(secs, 60.0), kills, total, ceili(hp_left)]
	_banner_status.text = _run_status if _run_status != "" else "Đang nộp kết quả..."
	_banner.show()
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.4)
	tw.tween_interval(8.0)
	tw.tween_property(_banner, "modulate:a", 0.0, 1.0)   # tự mờ đi cho đỡ vướng
	tw.tween_callback(_banner.hide)


func _build_go_arrow() -> void:
	_arrow_root = Control.new()
	_arrow_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow_root.anchor_left = 1.0
	_arrow_root.anchor_right = 1.0
	_arrow_root.anchor_top = 0.5
	_arrow_root.anchor_bottom = 0.5
	$Root.add_child(_arrow_root)

	_arrow = Label.new()
	_arrow.text = ">"
	_arrow.position = Vector2(-100.0, -70.0)
	_arrow.size = Vector2(80.0, 140.0)
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_arrow.add_theme_color_override("font_color", Color(0.9, 0.15, 0.12))
	_outline(_arrow, 110)
	_arrow_root.add_child(_arrow)
	_arrow_root.hide()


## Bật/tắt mũi tên đỏ ở mép phải màn hình (Level bật khi cổng đã mở mà còn ngoài tầm nhìn).
func set_go_arrow(on: bool) -> void:
	if on == _arrow_root.visible:
		return
	_arrow_root.visible = on
	if _arrow_tween != null and _arrow_tween.is_valid():
		_arrow_tween.kill()
	if not on:
		return
	_arrow.position.x = -100.0
	_arrow.modulate.a = 1.0
	_arrow_tween = create_tween().set_loops()   # nhấp nhô sang phải + chớp nhẹ
	_arrow_tween.tween_property(_arrow, "position:x", -84.0, 0.45)
	_arrow_tween.parallel().tween_property(_arrow, "modulate:a", 0.45, 0.45)
	_arrow_tween.tween_property(_arrow, "position:x", -100.0, 0.45)
	_arrow_tween.parallel().tween_property(_arrow, "modulate:a", 1.0, 0.45)


# ---------------- Thua ----------------

func _on_player_died() -> void:
	await get_tree().create_timer(1.0).timeout   # cho xem nốt animation ngã
	if _run_status == "":
		set_run_status("Đang nộp kết quả...")
	_game_over.show()
	_retry.grab_focus()   # Enter / Space cũng bấm được


func _on_retry() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
