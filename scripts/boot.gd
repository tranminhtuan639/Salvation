extends Control

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const LOGIN_SCENE := "res://scenes/ui/login.tscn"

func _ready() -> void:
	await Supa.restore_session()   # có refresh token đã lưu thì đăng nhập lại luôn
	await Config.fetch_remote()    # lỗi mạng thì dùng cache/default
	# Đã đăng nhập -> menu chính. Chưa -> màn đăng nhập (có nút chơi offline).
	get_tree().change_scene_to_file(MENU_SCENE if Supa.is_logged_in() else LOGIN_SCENE)
