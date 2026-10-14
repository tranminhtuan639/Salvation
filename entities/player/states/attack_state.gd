class_name AttackState
extends PlayerState

@export var anim: StringName = &"attack1"
@export var config_prefix := "player.attack1"   # đọc <prefix>.damage và <prefix>.cooldown
@export var cooldown_id: StringName = &""       # rỗng = không cooldown (đánh thường)
@export var startup := 0.10
@export var active := 0.10
@export var recovery := 0.25
@export var hitbox_size := Vector2(2.0, 1.2)    # đơn vị u
@export var hitbox_offset := Vector2(1.2, -0.9) # đơn vị u, x dương = phía trước
@export var lunge := 0.0                        # u, lướt tới trong pha active
@export_range(0.0, 1.0) var dash_cancel_ratio := 0.0   # 0 = hủy dash ngay sau active, 1 = sau hết recovery
@export var allow_skill_cancel := false         # đánh thường: true, skill: false
@export var next_attack: StringName = &""      # nối combo

var _t := 0.0
var _total := 0.0
var _armed := false


func enter(_msg: Dictionary = {}) -> void:
	var p := player
	_t = 0.0
	_armed = false
	_total = startup + active + recovery
	if cooldown_id != &"":
		p.cooldowns.start(cooldown_id, Config.get_value(config_prefix + ".cooldown", 1.0))
	var px := Config.PX_PER_UNIT
	p.hitbox.set_box(hitbox_size * px, hitbox_offset * px)
	if not p.hitbox.hit_landed.is_connected(_on_hit):
		p.hitbox.hit_landed.connect(_on_hit)
	p.sprite.play(anim)
	p.velocity.x = 0.0


func physics_update(delta: float) -> void:
	var p := player
	_t += delta
	p.apply_gravity(delta)

	var in_active := _t >= startup and _t < startup + active
	if in_active and not _armed:
		_armed = true
		p.hitbox.arm(Config.get_value(config_prefix + ".damage") * p.damage_mult)
		p.velocity.x = p.facing * lunge * Config.PX_PER_UNIT / maxf(active, 0.01)
	elif _t >= startup + active and _armed:
		_armed = false
		p.hitbox.disarm()
		p.velocity.x = 0.0

	p.move_and_slide()

	if _t >= _total:
		machine.change_to(&"Idle")
		return
	if _try_cancel():
		return


func exit() -> void:
	var p := player
	p.hitbox.disarm()
	if p.hitbox.hit_landed.is_connected(_on_hit):
		p.hitbox.hit_landed.disconnect(_on_hit)


## Luật animation cancel (GDD mục 2).
func _try_cancel() -> bool:
	var p := player
	if _t < startup + active:
		return false   # chưa hết pha active thì không hủy được

	if next_attack != &"" and p.input_buffer.consume(&"attack"):
		machine.change_to(next_attack)
		return true

	if allow_skill_cancel:
		var skill := p.poll_skill()
		if skill != &"":
			machine.change_to(skill)
			return true

	if _t >= startup + active + recovery * dash_cancel_ratio:
		if p.cooldowns.is_ready(&"dash") and p.input_buffer.consume(&"dash"):
			machine.change_to(&"Dash")
			return true
	return false


func _on_hit(_hurtbox: Hurtbox) -> void:
	Fx.hit_stop(0.05)
