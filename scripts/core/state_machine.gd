class_name StateMachine
extends Node

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State
var current: State
var states: Dictionary = {}   # tên node (vd &"Idle") -> State


## Actor gọi hàm này trong _ready() của nó (node con ready trước node cha).
func setup(actor: Node) -> void:
	for child in get_children():
		if child is State:
			child.actor = actor
			child.machine = self
			states[child.name] = child
	assert(initial_state != null, "StateMachine thiếu initial_state")
	current = initial_state
	current.enter()


## Nhớ `return` ngay sau khi gọi, vì state cũ vẫn chạy tiếp phần code phía dưới.
func change_to(key: StringName, msg: Dictionary = {}) -> void:
	if not states.has(key):
		push_error("StateMachine: không có state '%s'" % key)
		return
	var from: StringName = current.name if current else &""
	if current:
		current.exit()
	current = states[key]
	current.enter(msg)
	state_changed.emit(from, key)


func _unhandled_input(event: InputEvent) -> void:
	if current:
		current.handle_input(event)


func _physics_process(delta: float) -> void:
	if current:
		current.physics_update(delta)
