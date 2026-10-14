class_name FollowCamera
extends Camera2D
## Camera bám theo Player (tìm qua group "player"), nhìn trước một đoạn theo hướng mặt.
## Giới hạn màn hình đặt bằng limit_left/right/top/bottom của chính node Camera2D này.

@export var look_ahead := 90.0         # px, nhìn trước theo hướng mặt
@export var vertical_offset := -140.0  # px, đẩy camera lên để thấy phía trước thay vì dưới chân

var target: Player
var _ahead := 0.0


func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player") as Player
		if target == null:
			return
		global_position = target.global_position + Vector2(0.0, vertical_offset)
		reset_smoothing()   # frame đầu: nhảy thẳng tới player, không trượt từ góc map
		return
	_ahead = lerpf(_ahead, target.facing * look_ahead, 0.04)
	global_position = target.global_position + Vector2(_ahead, vertical_offset)
