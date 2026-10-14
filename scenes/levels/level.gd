class_name Level
extends Node2D
## Điều khiển một stage: đếm quái trong node "Enemies", hiện mục tiêu lên HUD,
## thắng khi hạ hết quái, thu thống kê (RunStats) và nộp lên backend qua autoload Runs.

signal cleared(stats: Dictionary)

@export var stage_id := "m1s1"   # trùng stages.id trong Supabase

var total_enemies := 0
var remaining := 0
var finished := false
var stats := RunStats.new()

var _player: Player
var _hud: Node
var _submitted := false


func _ready() -> void:
	stats.start_msec = Time.get_ticks_msec()
	Runs.start(stage_id)   # không await: chơi ngay, lúc nộp kết quả sẽ tự đợi nếu phiên chưa mở xong

	for e in $Enemies.get_children():
		if e is Enemy:
			total_enemies += 1
			e.died.connect(_on_enemy_died)
			e.damage_received.connect(stats.add_damage_dealt)
	remaining = total_enemies

	await get_tree().process_frame   # đợi Player và HUD chạy xong _ready
	_player = get_tree().get_first_node_in_group(&"player") as Player
	_hud = get_tree().get_first_node_in_group(&"hud")
	if _player != null:
		stats.attach_player(_player)
		_player.died.connect(_on_player_died)
	_update_objective()


## Rời stage giữa chừng (đổi scene) mà chưa nộp thì nộp "quit". Phiên không bỏ dở trên server.
func _exit_tree() -> void:
	if _submitted or not is_inside_tree() or not get_tree().root.has_node("Runs"):
		return
	_submitted = true
	Runs.submit("quit", stats)


func _update_objective() -> void:
	if _hud != null:
		_hud.set_objective("Quái còn lại: %d / %d" % [remaining, total_enemies])


func _on_enemy_died(_enemy: Enemy) -> void:
	remaining -= 1
	_update_objective()
	if remaining > 0 or finished:
		return
	if _player != null and _player.health.current <= 0.0:
		return   # player chết cùng lúc thì không tính thắng
	finished = true
	var hp_left := _player.health.current if _player != null else 0.0
	var clear_ms := stats.elapsed_ms()
	cleared.emit({"stage_id": stage_id, "clear_time_ms": clear_ms, "kills": total_enemies, "hp_left": hp_left})
	_submit("clear")
	await get_tree().create_timer(1.0).timeout   # cho xem nốt cú chốt rồi mới hiện màn thắng
	if _hud != null:
		_hud.show_victory(clear_ms, total_enemies, total_enemies, hp_left)


func _on_player_died() -> void:
	if not finished:
		_submit("death")


func _submit(result: String) -> void:
	if _submitted:
		return
	_submitted = true
	Runs.submit(result, stats)   # kết quả báo về HUD qua signal Runs.submitted
