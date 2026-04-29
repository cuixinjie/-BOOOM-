## BreakdownRecovery — 抛锚修复系统
##
## 功能说明：
## - 管理抛锚状态
## - 处理修车机制
##
## 对接注意事项：
## - 被 GameManager 调用
## - 驾驶员 Q 键充能
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name BreakdownRecovery
extends Node

signal recovery_started()
signal recovery_progress_changed(progress: float)
signal recovery_completed()
signal recovery_failed()

@export var total_time: float = 10.0
@export var charge_rate: float = 10.0
@export var drain_rate: float = 5.0
@export var health_restore_percent: float = 0.3

var _is_recovering: bool = false
var _recovery_progress: float = 0.0
var _time_remaining: float = 0.0

# ===== 接口定义 =====
## start_breakdown_recovery() -> void
##   开始修车
##
## update_repair(delta: float, is_charging: bool) -> void
##   更新修车进度
##
## complete_repair() -> void
##   完成修车
##
## fail_repair() -> void
##   修车失败
## ===== 接口结束 =====

func _ready() -> void:
	print("[BreakdownRecovery] Initialized")

func start_breakdown_recovery() -> void:
	if _is_recovering:
		return
	
	_is_recovering = true
	_time_remaining = total_time
	_recovery_progress = 0.0
	
	recovery_started.emit()
	EventBus.repair_started.emit()
	
	SpawnSystem.clear_all_enemies()
	AudioManager.play_sfx("repair_mode")
	
	print("[BreakdownRecovery] Recovery started")

func _process(delta: float) -> void:
	if not _is_recovering:
		return
	
	_time_remaining -= delta
	if _time_remaining <= 0:
		fail_repair()

func update_repair(delta: float, is_charging: bool) -> void:
	if not _is_recovering:
		return
	
	if is_charging:
		_recovery_progress += charge_rate * delta
		_recovery_progress = min(100.0, _recovery_progress)
	else:
		_recovery_progress -= drain_rate * delta
		_recovery_progress = max(0.0, _recovery_progress)
	
	recovery_progress_changed.emit(_recovery_progress)
	EventBus.repair_progress_changed.emit(_recovery_progress)
	
	if _recovery_progress >= 100.0:
		complete_repair()

func complete_repair() -> void:
	_is_recovering = false
	GameManager.complete_breakdown_recovery()
	recovery_completed.emit()
	print("[BreakdownRecovery] Recovery completed!")

func fail_repair() -> void:
	_is_recovering = false
	GameManager.fail_breakdown_recovery()
	recovery_failed.emit()
	print("[BreakdownRecovery] Recovery failed!")

func cancel_recovery() -> void:
	_is_recovering = false
	_time_remaining = 0.0
	_recovery_progress = 0.0
