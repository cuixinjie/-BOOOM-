## VehicleController — 载具控制器
##
## 功能说明：
## - 管理载具的物理和状态
## - 连接驾驶员输入和载具行为
##
## 对接注意事项：
## - 被 Motorcycle 等载具继承
## - 驾驶员通过此控制器操作载具
##
## 创建人：池言いく（主）、新街（重构）
## 创建日期：2026-04-29
## 合并日期：2026-05-02

class_name VehicleController
extends Node2D

signal speed_changed(current_speed: float)
signal health_changed(current: float, maximum: float)
signal breakdown_triggered()
signal breakdown_recovered()

enum VehicleState {
	NORMAL,
	DAMAGED,
	BREAKDOWN,
	REPAIRING
}

var vehicle_state: VehicleState = VehicleState.NORMAL

var max_speed: float = 400.0
var current_speed: float = 0.0
var acceleration: float = 300.0
var deceleration: float = 200.0

var health: float = 100.0
var max_health: float = 100.0
var damage_threshold: float = 20.0

var _driver: Node = null
var _shooter: Node = null

var velocity: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT

var shield_active: bool = false

var _base_max_speed: float = 400.0

# ===== 接口定义 =====
## apply_driver_input(direction: Vector2, speed: float) -> void
##   应用驾驶员输入
##
## apply_dodge(velocity: Vector2) -> void
##   应用闪避速度
##
## damage(amount: float) -> void
##   对载具造成伤害
##
## repair(amount: float) -> void
##   修复载具
##
## set_driver(driver: Node) -> void
##   设置驾驶员
##
## set_shooter(shooter: Node) -> void
##   设置射击手
## ===== 接口结束 =====

func _ready() -> void:
	_base_max_speed = max_speed
	_connect_signals()

func _connect_signals() -> void:
	EventBus.world_state_changed.connect(_on_world_state_changed)

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	pass

func _process(delta: float) -> void:
	_update_movement(delta)
	_apply_physics(delta)

func _update_movement(delta: float) -> void:
	pass

func _apply_physics(delta: float) -> void:
	global_position += velocity * delta

func apply_driver_input(direction: Vector2, speed: float, delta: float = 0.016) -> void:
	if vehicle_state == VehicleState.BREAKDOWN:
		return

	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
		current_speed = min(current_speed + acceleration * delta, speed)
		velocity = facing_direction * current_speed
	else:
		current_speed = max(current_speed - deceleration * delta, 0)
		velocity = facing_direction * current_speed

	speed_changed.emit(current_speed)
	EventBus.vehicle_speed_changed.emit(current_speed)

func apply_dodge(velocity_vec: Vector2) -> void:
	velocity = velocity_vec
	current_speed = velocity_vec.length()

func damage(amount: float) -> void:
	if vehicle_state == VehicleState.BREAKDOWN:
		return

	health -= amount
	health_changed.emit(health, max_health)
	EventBus.vehicle_damaged.emit(amount)

	if health <= 0:
		_trigger_breakdown()
	elif health < max_health * 0.3 and vehicle_state == VehicleState.NORMAL:
		vehicle_state = VehicleState.DAMAGED
		_print_state()

func _trigger_breakdown() -> void:
	vehicle_state = VehicleState.BREAKDOWN
	velocity = Vector2.ZERO
	current_speed = 0.0
	breakdown_triggered.emit()
	EventBus.vehicle_breakdown.emit()
	print("[VehicleController] BREAKDOWN!")

func recover() -> void:
	health = max_health
	vehicle_state = VehicleState.NORMAL
	breakdown_recovered.emit()
	EventBus.repair_completed.emit()
	print("[VehicleController] Recovered from breakdown")

func repair(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func set_driver(driver: Node) -> void:
	_driver = driver

func set_shooter(shooter: Node) -> void:
	_shooter = shooter

func get_speed_ratio() -> float:
	return current_speed / max_speed if max_speed > 0 else 0.0

func set_shield_active(active: bool) -> void:
	shield_active = active
	print("[VehicleController] Shield: ", shield_active)

func set_shield_timer(duration: float) -> void:
	if has_node("ShieldTimer"):
		var timer = $ShieldTimer
		timer.stop()
		timer.wait_time = duration
		timer.start()
	else:
		var timer = Timer.new()
		timer.name = "ShieldTimer"
		timer.one_shot = true
		timer.wait_time = duration
		timer.timeout.connect(_on_shield_expired)
		add_child(timer)
		timer.start()
		print("[VehicleController] Created ShieldTimer for duration: ", duration)

func _on_shield_expired() -> void:
	shield_active = false
	print("[VehicleController] Shield expired")

func apply_nitro_boost() -> void:
	if has_node("NitroBoostTimer"):
		var timer = $NitroBoostTimer
		timer.stop()
		timer.start()
		max_speed = _base_max_speed * 1.5
		current_speed = min(current_speed * 1.5, max_speed)
	else:
		var timer = Timer.new()
		timer.name = "NitroBoostTimer"
		timer.one_shot = true
		timer.wait_time = 2.0
		timer.timeout.connect(_on_nitro_expired)
		add_child(timer)
		max_speed = _base_max_speed * 1.5
		current_speed = min(current_speed * 1.5, max_speed)
		timer.start()
		print("[VehicleController] Nitro boost applied for 2s")

func _on_nitro_expired() -> void:
	max_speed = _base_max_speed
	print("[VehicleController] Nitro expired, speed restored")

func _print_state() -> void:
	print("[VehicleController] State: ", VehicleState.keys()[vehicle_state], " | Health: ", health)
