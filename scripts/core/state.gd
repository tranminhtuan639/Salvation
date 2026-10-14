class_name State
extends Node
## Lớp cha của mọi state. `machine` để kiểu Node (gọi change_to bằng duck typing)
## nhằm tránh tham chiếu vòng giữa State và StateMachine.

var actor: Node
var machine: Node

func enter(_msg: Dictionary = {}) -> void: pass
func exit() -> void: pass
func handle_input(_event: InputEvent) -> void: pass
func physics_update(_delta: float) -> void: pass
