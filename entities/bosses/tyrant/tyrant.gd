class_name TyrantBoss
extends Enemy
## BOSS CUỐI (Màn 2 stage 2): NGƯỜI ANH. 2 phase: The Fallen Tyrant (HP 100% -> 50%) và The Mad Tyrant (50% -> 0).
## Chỉ số đọc từ Config: "enemy.tyrant.*" (chung) và "enemy.tyrant.p1.*" / "enemy.tyrant.p2.*" (theo phase), xem pcfg().
## State (tên node trong scene): Idle, Chase, Telegraph, Combo, Quake, Rend, Wrath, Stagger, Ascend, Recover, Hurt, Dead.
##  - Chase chọn đòn (choose_attack) -> Telegraph (báo hiệu) -> state trùng tên đòn -> Recover -> Chase.
##  - HP chạm `phase2_hp_ratio` (0.5): ngắt mọi thứ, vào Ascend (bất tử `ascend_time` giây, xoay 360), sau đó cường hóa VĨNH VIỄN.
##  - Đòn đang telegraph/ra không bị ngắt khi bị đánh (giống BruteBoss), nếu không player combo liên tục sẽ khóa boss.
## HUD tìm boss qua group "boss", đọc boss_name / boss_bar_width / phase_changed.

signal phase_changed(phase: int)

const P1_TINT := Color(0.5, 0.38, 0.72)
const P2_TINT := Color(1.0, 0.82, 0.22)
const SWORD_P1 := Color(0.78, 0.8, 0.95)
const SWORD_P2 := Color(1.0, 0.9, 0.25)
const BOLT_P1 := Color(0.85, 0.7, 1.0)
const BOLT_P2 := Color(1.0, 0.9, 0.3)
const INTERRUPTIBLE := [&"Idle", &"Chase", &"Recover", &"Hurt"]

# Góc kiếm (độ). 0 = thẳng đứng, + = ngả về phía trước.
const POSE_REST := 25.0
const POSE_RAISED := -45.0
const POSE_SLASH := 110.0
const POSE_SLAM := 95.0

## Tên hiện trên thanh máu HUD (HUD đổi theo phase qua phase_title()).
@export var boss_name := "NGƯỜI ANH  ·  THE FALLEN TYRANT"
## Bề rộng thanh máu boss trên HUD (px). Giữ <= 590 để không đè máu player (trái) và mục tiêu (phải).
@export var boss_bar_width := 580.0

var phase := 1
var next_attack := &"Combo"   # Chase ghi, Telegraph đọc
var range_mult := 1.0         # phase 2: tầm đánh +27%
var cooldowns := Cooldowns.new()

var _history: Array[StringName] = []   # các đòn đặc biệt gần nhất (chống lặp 3 lần liên tiếp)
var _sword_tw: Tween
var _base_sprite_scale := Vector2.ONE

@onready var sword: ColorRect = $Pivot/Sword
@onready var spin_hitbox: Hitbox = $Pivot/SpinHitbox


func _ready() -> void:
	super()
	add_to_group(&"boss")
	show_world_hp_bar = false
	add_child(cooldowns)
	_base_sprite_scale = sprite.scale
	_apply_phase_stats()
	# Mở màn chưa tung đòn đặc biệt ngay
	cooldowns.start(&"quake", 3.0)
	cooldowns.start(&"rend", 2.0)
	cooldowns.start(&"wrath", 5.0)
	sprite.self_modulate = P1_TINT
	sword.color = SWORD_P1
	sword.rotation_degrees = POSE_REST
	health.changed.connect(_check_phase)


## Đọc chỉ số theo phase hiện tại: pcfg("quake_cooldown") -> enemy.tyrant.p1.quake_cooldown / p2...
func pcfg(stat: String, fallback := 0.0) -> float:
	return cfg("p%d.%s" % [phase, stat], fallback)


func phase_title() -> String:
	return "NGƯỜI ANH  ·  THE FALLEN TYRANT" if phase == 1 else "NGƯỜI ANH  ·  THE MAD TYRANT"


func _apply_phase_stats() -> void:
	move_speed = pcfg("move_speed", 4.5) * Config.PX_PER_UNIT
	attack_speed_mult = pcfg("attack_speed_mult", 1.0)   # p2 = 1.54 -> recover/animation ngắn lại ~35%
	range_mult = pcfg("range_mult", 1.0)                 # p2 = 1.27


func _check_phase(current: float, maximum: float) -> void:
	if phase != 1 or current <= 0.0:
		return
	if current <= maximum * cfg("phase2_hp_ratio", 0.5):
		phase = 2
		hurtbox.set_invulnerable(&"phase", true)   # bất tử ngay lập tức; Ascend gỡ khi kết thúc
		_apply_phase_stats()
		machine.change_to(&"Ascend")
		phase_changed.emit(2)


## Look phase 2: thân và kiếm chuyển vàng sáng.
func enter_mad_look() -> void:
	sprite.self_modulate = P2_TINT
	sword.color = SWORD_P2


func bolt_color() -> Color:
	return BOLT_P1 if phase == 1 else BOLT_P2


func set_sword_pose(deg: float, dur := 0.0) -> void:
	if _sword_tw != null and _sword_tw.is_valid():
		_sword_tw.kill()
	if dur <= 0.0:
		sword.rotation_degrees = deg
		return
	_sword_tw = create_tween()
	_sword_tw.tween_property(sword, "rotation_degrees", deg, dur)


func reset_sprite_scale() -> void:
	sprite.scale = _base_sprite_scale


## Tầm kích hoạt Đánh thường: 80% bề rộng hitbox (đã nhân buff tầm).
func melee_range() -> float:
	return cfg("combo_width", 2.5) * 0.8 * range_mult * Config.PX_PER_UNIT


func telegraph_time(attack: StringName) -> float:
	return pcfg(String(attack).to_lower() + "_telegraph", 0.4)


## Khoảng ngang tối đa tới cột sét cuối của Thunderquake (u).
func quake_reach() -> float:
	return cfg("quake_start", 1.8) + (int(pcfg("quake_count", 4)) - 1) * pcfg("quake_spacing", 2.0)


## Giới hạn ngang của arena (lấy theo limit của camera). Không có camera thì không giới hạn.
func arena_x_range() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return Vector2(-INF, INF)
	return Vector2(cam.limit_left + 24.0, cam.limit_right - 24.0)


## Chọn đòn tiếp theo theo khoảng cách. Trả &"" nếu chưa nên ra đòn (cứ tiến sát tiếp).
## `force` = bị kẹt đứng quá 0.5s: tung đại một đòn đặc biệt đã hồi.
func choose_attack(dist: float, dy: float, force := false) -> StringName:
	var px := Config.PX_PER_UNIT
	var close := dist <= melee_range() and dy <= 3.0 * px
	var w := {}
	if close:
		w[&"Combo"] = 5.0
	if cooldowns.is_ready(&"quake") and (force or dist <= quake_reach() * px):
		w[&"Quake"] = 1.5 if close else 3.0
	if cooldowns.is_ready(&"rend") and (force or dist >= 2.5 * px):
		w[&"Rend"] = 3.0
	if phase == 2 and cooldowns.is_ready(&"wrath") and (force or (dist >= 2.5 * px and dist <= cfg("wrath_distance", 10.0) * px * 0.95)):
		w[&"Wrath"] = 3.5
	# Không dùng cùng một đòn đặc biệt 3 lần liên tiếp
	if _history.size() >= 2 and _history[-1] == _history[-2]:
		w.erase(_history[-1])
	if w.is_empty():
		return &""
	var total := 0.0
	for k in w:
		total += w[k]
	var r := randf() * total
	for k in w:
		r -= w[k]
		if r <= 0.0:
			return k
	return w.keys()[0]


## Chốt đòn: ghi nhớ, bắt đầu hồi chiêu.
func commit_attack(attack: StringName) -> void:
	next_attack = attack
	if attack == &"Combo":
		_history.clear()   # Đánh thường "liên tục" nên không tính vào chuỗi chống lặp
		return
	_history.append(attack)
	if _history.size() > 2:
		_history.pop_front()
	cooldowns.start(StringName(String(attack).to_lower()), pcfg(String(attack).to_lower() + "_cooldown", 6.0))


func _on_damaged(amount: float, from_position: Vector2) -> void:
	damage_received.emit(minf(amount, _hp_prev))
	if health.current <= 0.0:
		return
	if machine.current.name in INTERRUPTIBLE:
		machine.change_to(&"Hurt", {"from_x": from_position.x})


func _on_died() -> void:
	super()
	for h in get_tree().get_nodes_in_group(&"boss_hazard"):
		h.queue_free()   # cột sét / lưỡi kiếm còn sót thì xóa
	sword.hide()
