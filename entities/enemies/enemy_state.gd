class_name EnemyState
extends State
## Lớp cha state của quái. Luồng: Idle -> Chase -> Telegraph -> Attack -> Recover -> (Chase ...)
## Bị đánh từ bất kỳ state nào -> Hurt -> Chase. Hết máu -> Dead.

var enemy: Enemy:
	get:
		return actor as Enemy
