extends Control
## Màn kết thúc sau khi hạ boss cuối. HIỆN LÀ PLACEHOLDER.
## TODO (cốt truyện): thay `_ready` bằng chuỗi vài trang chữ / ảnh tĩnh (cutscene), bấm phím để qua trang,
## hết trang cuối mới hiện nút "Về menu chính". Nội dung cốt truyện nằm trong tài liệu GDD.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.06)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(640, 0)
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var title := Label.new()
	title.text = "HẾT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	box.add_child(title)

	var text := Label.new()
	text.text = "Bạn đã vượt qua Màn 2.\n(Phần cốt truyện sẽ được bổ sung sau.)"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 22)
	box.add_child(text)

	var back := Button.new()
	back.text = "Về menu chính"
	back.custom_minimum_size = Vector2(240, 52)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	box.add_child(back)
	back.grab_focus()
