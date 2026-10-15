class_name Level
extends Node2D
## Điều khiển một stage: đếm quái trong node "Enemies", hiện mục tiêu lên HUD,
## thắng khi hạ hết quái, thu thống kê (RunStats) và nộp lên backend qua autoload Runs.

signal cleared(stats: Dictionary)

@export var stage_id := "m1s1"   # trùng stages.id trong Supabase
## Scene tiếp theo: có thì màn thắng hiện nút "Tiếp tục" (rỗng = chỉ có "Chơi lại").
@export_file("*.tscn") var next_scene := ""
## Ám màu lên quái spawn theo đợt (creep "chiều không gian khác" theo GDD). WHITE = giữ nguyên.
@export var creep_tint := Color.WHITE
## Nghỉ giữa các đợt (giây).
@export var wave_delay := 1.5

var total_enemies := 0
var remaining := 0
var finished := false
var stats := RunStats.new()

var _player: Player
var _hud: Node
var _submitted := false
var _waves: Array[Node] = []   # node con của "Waves": mỗi con là 1 đợt, được rút khỏi cây tới lúc spawn
var _wave_index := 0
var _wave_alive := 0		   # quái còn sống của đợt hiện tại (hoặc quái đặt sẵn trong Enemies)


func _ready() -> void:
	stats.start_msec = Time.get_ticks_msec()
	Runs.start(stage_id)   # không await: chơi ngay, lúc nộp kết quả sẽ tự đợi nếu phiên chưa mở xong

	for e in $Enemies.get_children():
		if e is Enemy:
			total_enemies += 1
			e.died.connect(_on_enemy_died)
			e.damage_received.connect(stats.add_damage_dealt)
			if e.has_signal(&"phase_changed"):   # boss nhiều phase: ghi phase_reached cho thống kê
				stats.phase_reached = 1
				e.connect(&"phase_changed", func(ph: int) -> void: stats.phase_reached = ph)
	_wave_alive = total_enemies

	# Node "Waves" (tùy chọn): mỗi con (Wave1, Wave2...) chứa quái của 1 đợt. Đợt sau chỉ xuất hiện khi đợt trước chết hết.
	var waves_node := get_node_or_null("Waves")
	if waves_node != null:
		for w in waves_node.get_children():
			for e in w.get_children():
				if e is Enemy:
					total_enemies += 1
					e.died.connect(_on_enemy_died)
					e.damage_received.connect(stats.add_damage_dealt)
			waves_node.remove_child(w)
			_waves.append(w)
	remaining = total_enemies

	await get_tree().process_frame   # đợi Player và HUD chạy xong _ready
	_player = get_tree().get_first_node_in_group(&"player") as Player
	_hud = get_tree().get_first_node_in_group(&"hud")
	if _player != null:
		stats.attach_player(_player)
		_player.died.connect(_on_player_died)
	if _hud != null and next_scene != "":
		_hud.set_next_scene(next_scene)
	if _wave_alive == 0:
		_spawn_next_wave()   # không có quái đặt sẵn: vào là có đợt 1
	_update_objective()


## Rời stage giữa chừng (đổi scene) mà chưa nộp thì nộp "quit". Phiên không bỏ dở trên server.
func _exit_tree() -> void:
	if _submitted or not is_inside_tree() or not get_tree().root.has_node("Runs"):
		return
	_submitted = true
	Runs.submit("quit", stats)


func _update_objective() -> void:
	if _hud == null:
		return
	if _waves.is_empty():
		_hud.set_objective("Quái còn lại: %d / %d" % [remaining, total_enemies])
	else:
		_hud.set_objective("Đợt %d/%d  ·  Quái còn lại: %d / %d" % [maxi(_wave_index, 1), _waves.size(), remaining, total_enemies])


## Đưa đợt kế tiếp vào cây (đặt dưới node Enemies), ám màu creep nếu có.
func _spawn_next_wave() -> void:
	if _wave_index >= _waves.size():
		return
	var w := _waves[_wave_index]
	_wave_index += 1
	_wave_alive = 0
	for e in w.get_children():
		if e is Enemy:
			_wave_alive += 1
	$Enemies.add_child(w)   # _ready của quái chạy ngay tại đây
	for e in w.get_children():
		if e is Enemy and creep_tint != Color.WHITE:
			e.sprite.self_modulate = creep_tint
	_update_objective()


func _on_enemy_died(_enemy: Enemy) -> void:
	remaining -= 1
	_wave_alive -= 1
	_update_objective()
	if _wave_alive <= 0 and _wave_index < _waves.size() and not finished:
		await get_tree().create_timer(wave_delay).timeout   # thở một nhịp rồi mới ra đợt sau
		if not finished and is_inside_tree():
			_spawn_next_wave()
		return
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
