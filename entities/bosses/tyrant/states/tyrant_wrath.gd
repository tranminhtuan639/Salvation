extends EnemyState
## Tyrant's Wrath (chỉ phase 2): sau Telegraph (khựng, hạ trọng tâm) lao cực nhanh `wrath_speed` u/s, tối đa `wrath_distance` u,
## chém mạnh (`wrath_damage`). Để lại vệt sét CHỈ LÀ HÌNH ẢNH (LightningTrail, không sát thương).
## Kết quả:
##  - đâm vào tường -> Stagger `wrath_wall_stun` giây (choáng, player đánh thoải mái)
##  - lao hụt (hết quãng đường không trúng) -> Stagger `wrath_miss_recover` giây (cửa phản công)
##  - trúng player -> dừng lại, Recover bình thường

@export var hitbox_size := Vector2(2.2, 2.0)   # u

var _start_x := 0.0
var _dist_max := 640.0
var _hit := false
var _trail_t := 0.0


func enter(_msg: Dictionary = {}) -> void:
	var b := enemy as TyrantBoss
	var px := Config.PX_PER_UNIT
	_start_x = b.global_position.x
	_dist_max = b.cfg("wrath_distance", 10.0) * px
	_hit = false
	_trail_t = 0.0
	b.sprite.play(&"attack")
	b.set_sword_pose(TyrantBoss.POSE_SLASH, 0.05)
	b.hitbox.set_box(hitbox_size * px, Vector2(hitbox_size.x * 0.5, -1.1) * px)
	b.hitbox.arm(b.cfg("wrath_damage", 40.0))
	if not b.hitbox.hit_landed.is_connected(_on_hit):
		b.hitbox.hit_landed.connect(_on_hit)
	b.velocity.x = b.facing * b.cfg("wrath_speed", 14.0) * px
	CamShake.shake(b, 6.0, 0.25)


func _on_hit(_hurtbox: Hurtbox) -> void:
	_hit = true


func physics_update(delta: float) -> void:
	var b := enemy as TyrantBoss
	b.apply_gravity(delta)
	b.move_and_slide()
	_trail_t -= delta
	if _trail_t <= 0.0:
		_trail_t = 0.035
		LightningTrail.spawn(b.get_parent(), b.global_position + Vector2(0.0, -b.body_height * 0.5), b.facing, b.bolt_color())
	if b.is_on_wall():
		CamShake.shake(b, 11.0, 0.4)
		machine.change_to(&"Stagger", {"duration": b.cfg("wrath_wall_stun", 2.0), "wall": true})
		return
	if _hit:
		machine.change_to(&"Recover")
		return
	if absf(b.global_position.x - _start_x) >= _dist_max:
		machine.change_to(&"Stagger", {"duration": b.cfg("wrath_miss_recover", 1.2)})


func exit() -> void:
	var b := enemy as TyrantBoss
	b.hitbox.disarm()
	if b.hitbox.hit_landed.is_connected(_on_hit):
		b.hitbox.hit_landed.disconnect(_on_hit)
	b.velocity.x = 0.0
	b.set_sword_pose(TyrantBoss.POSE_REST, 0.25)
