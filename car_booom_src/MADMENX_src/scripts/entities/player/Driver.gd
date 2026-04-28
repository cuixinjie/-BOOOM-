## Driver — 驾驶员
##
## 功能说明：
## - 负责驾驶机车
## - 控制移动、冲刺、技能使用
##
## 对接注意事项：
## - 输入通过 InputManager 获取
## - 车辆状态通过 EventBus 广播
## - 被 VehicleController 管理
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name Driver
extends PlayerBase

@export var vehicle_node_path: NodePath
@export var stamina: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_recovery_rate: float = 15.0

var _vehicle: Node = null
var _energy: float = 100.0
var _max_energy: float = 100.0
var _energy_recovery_rate: float = 20.0

var _is_sprinting: bool = false
var _is_in_breakdown: bool = false

# ===== 接口定义 =====
## get_vehicle_health() -> float
##   获取机车血量
##
## get_energy() -> float
##   获取当前能量
##
## use_skill(skill_id: String) -> bool
##   使用技能
##
## trigger_breakdown() -> void
##   触发抛锚
##
## start_breakdown_recovery() -> void
##   开始修车
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	_connect_signals()

func _connect_signals() -> void:
	EventBus.vehicle_breakdown.connect(_on_vehicle_breakdown)
	EventBus.repair_completed.connect(_on_repair_completed)

func _process_input(delta: float) -> void:
	if not _input_enabled:
		return
	
	if _is_in_breakdown:
		_handle_breakdown_input(delta)
	else:
		_handle_normal_input(delta)
	
	_update_resources(delta)

func _handle_normal_input(delta: float) -> void:
	var input_data = InputManager.get_driver_input()
	
	player_input_received.emit({
		"move_direction": input_data.move_direction,
		"is_sprinting": input_data.is_sprinting
	})

func _handle_breakdown_input(delta: float) -> void:
	if Input.is_action_pressed("skill_1"):
		EventBus.repair_progress_changed.emit(delta * 10.0)
	else:
		EventBus.repair_progress_changed.emit(-delta * 5.0)

func _update_resources(delta: float) -> void:
	_energy = min(_max_energy, _energy + _energy_recovery_rate * delta)
	_stamina = min(max_stamina, _stamina + stamina_recovery_rate * delta)

func get_vehicle_health() -> float:
	if _vehicle:
		return _vehicle.current_health
	return GameManager.get_vehicle_health()

func get_energy() -> float:
	return _energy

func consume_energy(amount: float) -> bool:
	if _energy >= amount:
		_energy -= amount
		return true
	return false

func _on_vehicle_breakdown() -> void:
	_is_in_breakdown = true
	disable_input()
	print("[Driver] Breakdown occurred, entering repair mode")

func _on_repair_completed() -> void:
	_is_in_breakdown = false
	enable_input()
	print("[Driver] Repair completed, resuming control")

func trigger_breakdown() -> void:
	EventBus.vehicle_breakdown.emit()
