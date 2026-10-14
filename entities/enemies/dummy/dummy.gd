extends Node2D
## Bao cát để thử đòn. Đánh trúng sẽ in sát thương, chết thì hồi máu lại.

@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var body: ColorRect = $Body

func _ready() -> void:
	health.setup(200.0)
	hurtbox.health = health
	health.damaged.connect(_on_damaged)
	health.died.connect(func(): health.setup(200.0))

func _on_damaged(amount: float, _from: Vector2) -> void:
	print("Dummy -%s (còn %s)" % [amount, health.current])
	body.color = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	body.color = Color(0.8, 0.3, 0.3)
