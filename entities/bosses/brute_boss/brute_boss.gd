class_name BruteBoss
extends Enemy
## Boss màn 1 (biến thể Brute). Hai đòn: Húc (Charge) và Đập đất (Slam), chọn ở BossChase.
## - Đòn đang telegraph / đang ra không bị ngắt khi bị đánh (chỉ Idle/Chase/Recover mới bị khựng),
##   nếu không player combo liên tục sẽ khóa boss và không bao giờ thấy được đòn.
## - Dưới `enrage_hp_ratio` máu: attack_speed_mult = `enrage_speed_mult` (1.2) -> telegraph/recover ngắn lại 20%, lao nhanh hơn 20%.
## Màu đổi bằng sprite.self_modulate (Telegraph nhấp nháy dùng `modulate` nên không đè mất màu boss).

const NORMAL_TINT := Color(0.6, 0.2, 0.75)
const ENRAGE_TINT := Color(1.0, 0.22, 0.22)
const INTERRUPTIBLE := [&"Idle", &"Chase", &"Recover", &"Hurt"]

signal enraged

## Tên hiện trên thanh máu boss ở HUD.
@export var boss_name := "BRUTE"

var next_attack := &"Charge"   # BossChase ghi, BossTelegraph đọc
var last_attack := &""
var is_enraged := false


func _ready() -> void:
	super()
	add_to_group(&"boss")   # HUD tìm boss qua group này để hiện thanh máu lớn
	show_world_hp_bar = false
	sprite.self_modulate = NORMAL_TINT
	health.changed.connect(_check_enrage)


func _check_enrage(current: float, maximum: float) -> void:
	if is_enraged or current <= 0.0:
		return
	if current < maximum * cfg("enrage_hp_ratio", 0.5):
		is_enraged = true
		attack_speed_mult = cfg("enrage_speed_mult", 1.2)
		sprite.self_modulate = ENRAGE_TINT
		enraged.emit()


func _on_damaged(amount: float, from_position: Vector2) -> void:
	damage_received.emit(minf(amount, _hp_prev))
	if health.current <= 0.0:
		return
	if machine.current.name in INTERRUPTIBLE:
		machine.change_to(&"Hurt", {"from_x": from_position.x})
