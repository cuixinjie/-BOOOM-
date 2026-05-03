## BreakdownRecovery — 抛锚修复系统
##
## 功能说明：
## - 机车抛锚时的修复小游戏
## - QTE 机制考验玩家反应
## - 成功修复并回复部分血量，失败则游戏结束
##
## 对接注意事项：
## - 通过 EventBus.vehicle_breakdown 触发
## - 修复完成/失败通过 EventBus 广播
## - 按键输入通过 InputManager 的 driver_input_changed 获取
##
## 创建人：池言いく（主）、新街（接口规范）、cjs（修复）
## 创建日期：2026-04-29
## 合并日期：2026-05-02
## 修复日期：2026-05-02

class_name BreakdownRecovery
extends Node2D

signal recovery_started()
signal recovery_progress_changed(progress: float)
signal recovery_completed()
signal recovery_failed()

const SUCCESS_THRESHOLD: float = 100.0
const FAILURE_THRESHOLD: float = -30.0
const PROGRESS_PER_CORRECT: float = 22.5
const PENALTY_PER_WRONG: float = 7.5
const DECAY_PER_SECOND: float = 5.0
const DECAY_PENALTY_MULTIPLIER: float = 2.0
const BUTTON_SEQUENCE: Array = ["Q", "W", "E", "R"]
const DRONE_INTERFERENCE_RANGE: float = 150.0
const DRONE_INTERFERENCE_PENALTY: float = 3.0

var repair_time: float = 8.0
var current_progress: float = 0.0

var _is_active: bool = false
var _target_button: String = ""
var _current_button_index: int = 0

# ===== 接口定义 =====
## start_recovery() -> void
##   开始修复流程
##
## input_button(button: String) -> void
##   处理玩家按键输入
##
## cancel_recovery() -> void
##   取消修复
##
## get_progress() -> float
##   获取修复进度
##
## is_active() -> bool
##   是否正在进行修复
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	print("[BreakdownRecovery] Initialized")

func _connect_signals() -> void:
	EventBus.vehicle_breakdown.connect(start_recovery)
	EventBus.repair_failed.connect(_on_repair_failed)
	EventBus.driver_input_changed.connect(_on_driver_input)

func _on_driver_input(input_data: Dictionary) -> void:
	if not _is_active:
		return
	var skill_1 = input_data.get("skill_1", false)
	if skill_1:
		input_button(BUTTON_SEQUENCE[_current_button_index % BUTTON_SEQUENCE.size()])

func _on_repair_failed() -> void:
	_is_active = false
	print("[BreakdownRecovery] Repair failed externally!")

func _process(delta: float) -> void:
	if not _is_active:
		return

	_apply_drone_interference(delta)

	if current_progress > 0:
		current_progress -= DECAY_PER_SECOND * delta
	else:
		current_progress -= DECAY_PER_SECOND * DECAY_PENALTY_MULTIPLIER * delta

	current_progress = clamp(current_progress, -100.0, 100.0)
	recovery_progress_changed.emit(current_progress / SUCCESS_THRESHOLD)

	if current_progress <= FAILURE_THRESHOLD:
		fail_recovery()
	elif current_progress >= SUCCESS_THRESHOLD:
		complete_recovery()

func _apply_drone_interference(delta: float) -> void:
	var nearby_drones = _get_nearby_interfering_drones()
	for drone in nearby_drones:
		current_progress -= DRONE_INTERFERENCE_PENALTY * delta
		if not drone.is_dead:
			EventBus.sfx_requested.emit("repair_interference")

func _get_nearby_interfering_drones() -> Array:
	var result: Array = []
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.is_dead or not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= DRONE_INTERFERENCE_RANGE:
			result.append(enemy)
	return result

func start_recovery() -> void:
	if _is_active:
		return

	_is_active = true
	current_progress = 0.0
	_current_button_index = 0
	_next_button()
	recovery_started.emit()
	EventBus.repair_started.emit()
	print("[BreakdownRecovery] Recovery started!")

func _next_button() -> void:
	_target_button = BUTTON_SEQUENCE[_current_button_index % BUTTON_SEQUENCE.size()]
	print("[BreakdownRecovery] Press: ", _target_button)
	EventBus.sfx_requested.emit("repair_hint")

func input_button(button: String) -> void:
	if not _is_active:
		return

	if button.to_upper() == _target_button:
		current_progress += PROGRESS_PER_CORRECT
		_current_button_index += 1
		AudioManager.play_sfx("repair_correct")
		print("[BreakdownRecovery] Correct! Progress: ", current_progress)
		_next_button()
	else:
		current_progress -= PENALTY_PER_WRONG
		AudioManager.play_sfx("repair_wrong")
		print("[BreakdownRecovery] Wrong button! Progress: ", current_progress)

func complete_recovery() -> void:
	_is_active = false
	recovery_completed.emit()
	EventBus.repair_completed.emit()
	GameManager.complete_breakdown_recovery()
	print("[BreakdownRecovery] Recovery completed!")

func fail_recovery() -> void:
	_is_active = false
	recovery_failed.emit()
	EventBus.repair_failed.emit()
	GameManager.fail_breakdown_recovery()
	print("[BreakdownRecovery] Recovery failed!")

func cancel_recovery() -> void:
	_is_active = false
	current_progress = 0.0

func get_progress() -> float:
	return current_progress / SUCCESS_THRESHOLD

func is_active() -> bool:
	return _is_active
