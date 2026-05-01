## StateMachine — 状态机基类
##
## 功能说明：
## - 提供状态机基础功能
## - 支持状态切换、状态栈
## - 集成 EventBus 事件监听
##
## 对接注意事项：
## - 被所有需要状态管理的实体继承
## - 子类需实现各状态的 _enter_state 和 _exit_state 方法
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name StateMachine
extends Node

signal state_changed(from_state: String, to_state: String)

var current_state: String = ""
var previous_state: String = ""
var _state_stack: Array = []

var _states: Dictionary = {}
var _is_processing: bool = true

# ===== 接口定义 =====
## register_state(state_name: String, state_node: Node) -> void
##   注册一个状态
##
## set_state(state_name: String) -> void
##   切换到指定状态
##
## push_state(state_name: String) -> void
##   压入新状态（保留当前状态）
##
## pop_state() -> void
##   弹出状态，恢复上一个状态
##
## can_transition(from_state: String, to_state: String) -> bool
##   检查是否可以切换状态
## ===== 接口结束 =====

func _ready() -> void:
	_initialize_states()
	if get_children().size() > 0 and current_state == "":
		current_state = get_children()[0].name

func _process(delta: float) -> void:
	if _is_processing and current_state != "":
		var state_node = _states.get(current_state)
		if state_node and state_node.has_method("_state_update"):
			state_node._state_update(delta)

func _physics_process(delta: float) -> void:
	if _is_processing and current_state != "":
		var state_node = _states.get(current_state)
		if state_node and state_node.has_method("_state_physics_update"):
			state_node._state_physics_update(delta)

func _initialize_states() -> void:
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.state_machine = self
			child._ready()
			if current_state == "":
				current_state = child.name

func register_state(state_name: String, state_node: Node) -> void:
	_states[state_name] = state_node
	state_node.state_machine = self

func set_state(state_name: String) -> void:
	if not _states.has(state_name):
		push_warning("[StateMachine] State not found: " + state_name)
		return
	
	if current_state == state_name:
		return
	
	if not can_transition(current_state, state_name):
		return
	
	var old_state = current_state
	_exit_state(old_state)
	previous_state = old_state
	current_state = state_name
	_enter_state(state_name)
	state_changed.emit(old_state, state_name)
	print("[StateMachine] State changed: ", old_state, " -> ", state_name)

func push_state(state_name: String) -> void:
	if current_state != "":
		_state_stack.push_front(current_state)
	set_state(state_name)

func pop_state() -> void:
	if _state_stack.size() > 0:
		var previous = _state_stack.pop_front()
		set_state(previous)

func _enter_state(state_name: String) -> void:
	var state_node = _states.get(state_name)
	if state_node:
		state_node._enter()

func _exit_state(state_name: String) -> void:
	var state_node = _states.get(state_name)
	if state_node:
		state_node._exit()

func can_transition(from_state: String, to_state: String) -> bool:
	var from_node = _states.get(from_state)
	if from_node and from_node.has_method("_can_transition_to"):
		return from_node._can_transition_to(to_state)
	return true

func pause_processing() -> void:
	_is_processing = false

func resume_processing() -> void:
	_is_processing = true

# 内置状态基类
class State:
	var state_machine: StateMachine
	
	func _ready() -> void:
		pass
	
	func _enter() -> void:
		pass
	
	func _exit() -> void:
		pass
	
	func _state_update(delta: float) -> void:
		pass
	
	func _state_physics_update(delta: float) -> void:
		pass
	
	func _can_transition_to(next_state: String) -> bool:
		return true
