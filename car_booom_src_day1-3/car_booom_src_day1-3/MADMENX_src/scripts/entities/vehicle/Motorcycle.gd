## Motorcycle — 摩托车（自包含版本）
extends Node2D

## 信号（从 VehicleController 复制）
signal speed_changed(current_speed: float)
signal health_changed(current: float, maximum: float)
signal breakdown_triggered()
signal breakdown_recovered()

## 状态枚举
enum VehicleState {
	NORMAL,
	DAMAGED,
	BREAKDOWN,
	REPAIRING
}

## 载具属性
var vehicle_state: VehicleState = VehicleState.NORMAL

var max_speed: float = 450.0
var current_speed: float = 0.0
var acceleration: float = 350.0
var deceleration: float = 250.0

var health: float = 120.0
var max_health: float = 120.0

var velocity: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT

var wheelbase: float = 120.0
var max_tilt_angle: float = 0.4
var current_tilt: float = 0.0

var _lean_input: float = 0.0
var _base_max_speed: float = 450.0
var _shield_active: bool = false

## 与 VehicleSkills / VehicleController 约定一致的可写护盾状态
var shield_active: bool:
	get:
		return _shield_active
	set(value):
		set_shield_active(value)

var _driver: Node = null
var _shooter: Node = null

func _ready() -> void:
	_base_max_speed = max_speed
	_connect_signals()
	print("[Motorcycle] Initialized — speed: ", max_speed, " | health: ", health)

func _connect_signals() -> void:
	if EventBus.has_signal("world_state_changed"):
		EventBus.world_state_changed.connect(_on_world_state_changed)

func _on_world_state_changed(_from_state: int, _to_state: int) -> void:
	pass

func _process(delta: float) -> void:
	_update_movement(delta)
	_apply_physics(delta)

func _update_movement(delta: float) -> void:
	if vehicle_state == VehicleState.BREAKDOWN:
		return

	if vehicle_state == VehicleState.DAMAGED:
		max_speed = 250.0
		acceleration = 200.0

	_update_tilt(delta)

func _update_tilt(delta: float) -> void:
	var target_tilt = _lean_input * max_tilt_angle
	current_tilt = lerp(current_tilt, target_tilt, 5.0 * delta)
	rotation = current_tilt

func _apply_physics(delta: float) -> void:
	global_position += velocity * delta

func apply_driver_input(direction: Vector2, speed: float, delta: float) -> void:
	if vehicle_state == VehicleState.BREAKDOWN:
		return

	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
		current_speed = min(current_speed + acceleration * delta, speed)
		velocity = facing_direction * current_speed
	else:
		current_speed = max(current_speed - deceleration * delta, 0)
		velocity = facing_direction * current_speed

	if direction.x != 0:
		_lean_input = direction.x
	else:
		_lean_input = lerp(_lean_input, 0.0, 3.0 * delta)

	speed_changed.emit(current_speed)
	EventBus.vehicle_speed_changed.emit(current_speed)

func apply_dodge(velocity_vec: Vector2) -> void:
	_lean_input = sign(velocity_vec.x) * 1.0
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
		print("[Motorcycle] State: DAMAGED | Health: ", health)

func _trigger_breakdown() -> void:
	vehicle_state = VehicleState.BREAKDOWN
	velocity = Vector2.ZERO
	current_speed = 0.0
	breakdown_triggered.emit()
	EventBus.vehicle_breakdown.emit()
	print("[Motorcycle] BREAKDOWN!")

func recover() -> void:
	health = max_health
	vehicle_state = VehicleState.NORMAL
	breakdown_recovered.emit()
	EventBus.repair_completed.emit()
	print("[Motorcycle] Recovered from breakdown")

func repair(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func set_driver(driver: Node) -> void:
	_driver = driver

func set_shooter(shooter: Node) -> void:
	_shooter = shooter
	if shooter != null and has_node("ShooterMarker"):
		var marker_global_pos = $ShooterMarker.global_position
		var marker_global_rot = $ShooterMarker.global_rotation
		shooter.get_parent().remove_child(shooter)
		add_child(shooter)
		shooter.global_position = marker_global_pos
		shooter.global_rotation = marker_global_rot

func get_speed_ratio() -> float:
	return current_speed / max_speed if max_speed > 0 else 0.0

func set_shield_active(active: bool) -> void:
	_shield_active = active
	print("[Motorcycle] Shield: ", _shield_active)

func apply_nitro_boost() -> void:
	max_speed = _base_max_speed * 1.5
	current_speed = min(current_speed * 1.5, max_speed)
	print("[Motorcycle] Nitro boost applied for 2s")

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
		print("[Motorcycle] Created ShieldTimer for duration: ", duration)

func _on_shield_expired() -> void:
	_shield_active = false
	print("[Motorcycle] Shield expired")
