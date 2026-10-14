extends Control

func _ready() -> void:
	await Supa.restore_session()   # không có session thì bỏ qua, vào menu đăng nhập sau
	await Config.fetch_remote()    # lỗi mạng thì dùng cache/default
	# Tạm thời vào thẳng arena test, sau này đổi sang main_menu.tscn
	get_tree().change_scene_to_file("res://scenes/levels/test_arena.tscn")
