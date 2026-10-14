extends Control
## Đăng nhập / đăng ký / chơi offline. Giao diện dựng bằng code cho gọn.
## Chơi offline vẫn vào game được nhưng không có phiên nên không lên bảng xếp hạng.

const START_SCENE := "res://scenes/levels/m1s1.tscn"

var _email: LineEdit
var _password: LineEdit
var _username: LineEdit
var _status: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.1)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "SALVATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)

	_email = _field(box, "Email")
	_password = _field(box, "Mật khẩu")
	_password.secret = true
	_username = _field(box, "Tên hiển thị (chỉ cần khi đăng ký, 3-20 ký tự a-z 0-9 _)")
	_password.text_submitted.connect(func(_t: String) -> void: _on_login())

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
	box.add_child(_status)

	_button(box, "Đăng nhập", _on_login)
	_button(box, "Tạo tài khoản", _on_register)
	_button(box, "Chơi offline (không lên bảng xếp hạng)", _go_game)
	_email.grab_focus()


func _field(parent: Control, hint: String) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = hint
	le.custom_minimum_size = Vector2(0, 40)
	parent.add_child(le)
	return le


func _button(parent: Control, text: String, handler: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(handler)
	parent.add_child(b)
	_buttons.append(b)


func _busy(on: bool, message := "") -> void:
	for b in _buttons:
		b.disabled = on
	_status.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0) if on else Color(1.0, 0.6, 0.5))
	_status.text = message


func _on_login() -> void:
	if _email.text.strip_edges() == "" or _password.text == "":
		_status.text = "Nhập email và mật khẩu"
		return
	_busy(true, "Đang đăng nhập...")
	var r: Dictionary = await Supa.sign_in(_email.text.strip_edges(), _password.text)
	if r.ok:
		_go_game()
		return
	_busy(false, _error_text(r))


func _on_register() -> void:
	var name := _username.text.strip_edges()
	var regex := RegEx.create_from_string("^[A-Za-z0-9_]{3,20}$")
	if _email.text.strip_edges() == "" or _password.text.length() < 6:
		_status.text = "Cần email và mật khẩu từ 6 ký tự"
		return
	if regex.search(name) == null:
		_status.text = "Tên hiển thị phải 3-20 ký tự gồm chữ, số, dấu _"
		return
	_busy(true, "Đang tạo tài khoản...")
	var r: Dictionary = await Supa.sign_up(_email.text.strip_edges(), _password.text, name)
	if r.ok and Supa.is_logged_in():
		_go_game()
	elif r.ok:
		_busy(false, "Đã tạo tài khoản. Kiểm tra email để xác nhận rồi đăng nhập.")
	else:
		_busy(false, _error_text(r))


func _go_game() -> void:
	get_tree().change_scene_to_file(START_SCENE)


## Lỗi của Supabase Auth có 2 dạng: {msg} / {error_description}. Lỗi trigger tạo profile là 500 chung chung.
func _error_text(r: Dictionary) -> String:
	if r.status == 0:
		return "Không kết nối được máy chủ"
	var d: Dictionary = r["data"] if r.get("data") is Dictionary else {}
	var msg := str(d.get("msg", d.get("error_description", d.get("message", ""))))
	if msg.contains("Database error saving new user"):
		return "Tên hiển thị đã có người dùng (hoặc không hợp lệ)"
	if msg.contains("Invalid login credentials"):
		return "Sai email hoặc mật khẩu"
	if msg.contains("already registered"):
		return "Email này đã đăng ký"
	return msg if msg != "" else "Lỗi (%d)" % r.status
