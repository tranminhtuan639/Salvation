class_name Level
extends Node2D
## Điều khiển một stage: đếm quái trong node "Enemies", hiện mục tiêu lên HUD,
## thắng khi hạ hết quái, thu thống kê (RunStats) và nộp lên backend qua autoload Runs.

signal cleared(stats: Dictionary)

@export var stage_id := "m1s1"   # trùng stages.id trong Supabase
## Scene tiếp theo: có thì màn thắng hiện nút "Tiếp tục" (rỗng = chỉ có "Chơi lại").
@export_file("*.tscn") var next_scene := ""
## Nhãn nút ở màn thắng khi có scene kế tiếp.
@export var next_label := "Stage tiếp"
## Cổng cuối bản đồ: hạ hết quái thì cổng mở, chạy vào cổng để sang `next_scene` (có hiệu ứng mờ dần).
## Bật thì KHÔNG hiện bảng thắng + nút; tắt thì dùng bảng thắng như cũ. Cần `next_scene` khác rỗng.
@export var use_exit_gate := false
## Quái spawn theo đợt tự lao tới player ngay khi xuất hiện (tắt thì chúng đứng yên tới khi player vào tầm phát hiện).
@export var wave_aggro := true
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
var _gate: ExitGate
var _leaving := false
var _waves: Array[Node] = []   # node con của "Waves": mỗi con là 1 đợt, được rút khỏi cây tới lúc spawn
var _wave_index := 0
var _wave_alive := 0		   # quái còn sống của đợt hiện tại (hoặc quái đặt sẵn trong Enemies)


func _ready() -> void:
	_fade_in()   # vào stage từ đen -> sáng
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
		_hud.set_next_scene(next_scene, next_label)
	if use_exit_gate and next_scene != "":
		_setup_gate()
	if _wave_alive == 0:
		_spawn_next_wave()   # không có quái đặt sẵn: vào là có đợt 1
	_update_objective()


## Cổng đặt ở cuối bản đồ (theo giới hạn phải của camera), sát tường, đứng trên mặt sàn.
func _setup_gate() -> void:
	var cam := get_node_or_null("Camera") as Camera2D
	var right := float(cam.limit_right) if cam != null else 3200.0
	_gate = ExitGate.new()
	_gate.position = Vector2(right - 130.0, 618.0)
	add_child(_gate)
	_gate.entered.connect(_on_gate_entered)


func _process(_delta: float) -> void:
	# Mũi tên đỏ chỉ đường: hiện khi cổng đã mở mà còn nằm ngoài màn hình phía bên phải
	if _gate == null or not _gate.is_open or _hud == null or _leaving:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var half_w := get_viewport_rect().size.x * 0.5 / cam.zoom.x
	var gate_in_view := _gate.global_position.x - 100.0 < cam.get_screen_center_position().x + half_w
	_hud.set_go_arrow(not gate_in_view)


func _on_gate_entered() -> void:
	if _leaving:
		return
	_leaving = true
	if _hud != null:
		_hud.set_go_arrow(false)
	var rect := _make_fade_rect()
	rect.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 1.0, 0.5)
	await tw.finished
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(next_scene)


func _fade_in() -> void:
	var rect := _make_fade_rect()
	rect.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 0.0, 0.6)
	tw.tween_callback(rect.get_parent().queue_free)


## Lớp đen phủ toàn màn hình, nằm trên cùng, không chặn chuột.
func _make_fade_rect() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


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
		if e is Enemy:
			if creep_tint != Color.WHITE:
				e.sprite.self_modulate = creep_tint
			if wave_aggro:
				e.aggro()
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
	if _gate != null:
		await get_tree().create_timer(0.8).timeout   # để cú chốt kịp hạ xuống rồi mới mở cổng
		if not is_inside_tree():
			return
		if _hud != null:
			_hud.show_clear_banner(clear_ms, total_enemies, total_enemies, hp_left)
		_gate.open()
		return
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
