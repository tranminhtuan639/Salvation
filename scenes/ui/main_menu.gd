extends Control
## Menu chính: Chơi từ đầu, chọn stage, đăng xuất / đăng nhập, thoát. Giao diện dựng bằng code.
## Hiện mở khóa HẾT các stage (chưa có lưu tiến trình). Khi có cloud save thì khóa theo last_stage_cleared.

const LOGIN_SCENE := "res://scenes/ui/login.tscn"
const FIRST_STAGE := "res://scenes/levels/m1s1.tscn"

## Mỗi mục: [nhãn nút, scene]
const WORLDS := [
	{"title": "MÀN 1", "stages": [
		["Stage 1", "res://scenes/levels/m1s1.tscn"],
		["Stage 2", "res://scenes/levels/m1s2.tscn"],
		["Stage 3  ·  Boss", "res://scenes/levels/m1s3.tscn"],
	]},
	{"title": "MÀN 2", "stages": [
		["Stage 1", "res://scenes/levels/m2s1.tscn"],
		["Stage 2  ·  Boss", "res://scenes/levels/m2s2.tscn"],
	]},
]

var _play_btn: Button
var _account_btn: Button


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.1)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(520, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "SALVATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	box.add_child(title)

	var who := Label.new()
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.add_theme_font_size_override("font_size", 16)
	who.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
	who.text = "Đã đăng nhập: kết quả được ghi lên bảng xếp hạng" if Supa.is_logged_in() \
			else "Chơi offline: kết quả không lên bảng xếp hạng"
	box.add_child(who)

	_play_btn = _button(box, "Chơi từ đầu", func() -> void: _go(FIRST_STAGE), 52)

	for world in WORLDS:
		var label := Label.new()
		label.text = world["title"]
		label.add_theme_font_size_override("font_size", 20)
		box.add_child(label)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		for s in world["stages"]:
			var path: String = s[1]
			var b := _button(row, s[0], func() -> void: _go(path), 44)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.disabled = not ResourceLoader.exists(path)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	box.add_child(bottom)
	_account_btn = _button(bottom, "Đăng xuất" if Supa.is_logged_in() else "Đăng nhập", _on_account, 44)
	_account_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quit_btn := _button(bottom, "Thoát", func() -> void: get_tree().quit(), 44)
	quit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_play_btn.grab_focus()   # dùng bàn phím: mũi tên + Enter


func _button(parent: Control, text: String, handler: Callable, height: float) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.pressed.connect(handler)
	parent.add_child(b)
	return b


func _go(scene_path: String) -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(scene_path)


func _on_account() -> void:
	_account_btn.disabled = true
	if Supa.is_logged_in():
		await Supa.sign_out()
	_go(LOGIN_SCENE)
