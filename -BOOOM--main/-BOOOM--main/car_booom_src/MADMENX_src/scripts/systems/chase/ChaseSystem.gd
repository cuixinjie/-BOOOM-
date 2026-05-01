## ChaseSystem — 追兵系统
##
## 功能说明：
## - 管理追兵逼近机制
## - 提供距离奖励和惩罚
##
## 对接注意事项：
## - 被 GameManager 调用
## - 通过 EventBus.chase_distance_changed 广播
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name ChaseSystem
extends Node

signal distance_changed(distance: float)
signal caught()

@export var max_distance: float = 100.0
@export var initial_distance: float = 50.0
@export var approach_rate: float = 5.0

var _current_distance: float = 50.0
var _is_chase_active: bool = false

# ===== 接口定义 =====
## start_chase() -> void
##   开始追捕
##
## stop_chase() -> void
##   停止追捕
##
## get_chase_distance() -> float
##   获取追兵距离
##
## add_distance_reward(amount: float) -> void
##   添加距离奖励
##
## check_catch() -> bool
##   检查是否追上
## ===== 接口结束 =====

func _ready() -> void:
	_current_distance = initial_distance
	_connect_signals()
	print("[ChaseSystem] Initialized")

func _connect_signals() -> void:
	EventBus.segment_completed.connect(_on_segment_completed)
	EventBus.repair_completed.connect(_on_repair_completed)

func _process(delta: float) -> void:
	if not _is_chase_active:
		return
	
	if _current_distance > 0:
		_current_distance -= approach_rate * delta
		_current_distance = max(0, _current_distance)
		distance_changed.emit(_current_distance)
		
		if _current_distance <= 0:
			caught.emit()
			EventBus.chase_caught.emit()
			print("[ChaseSystem] Caught!")

func start_chase() -> void:
	_is_chase_active = true
	_current_distance = initial_distance
	print("[ChaseSystem] Chase started")

func stop_chase() -> void:
	_is_chase_active = false
	print("[ChaseSystem] Chase stopped")

func get_chase_distance() -> float:
	return _current_distance

func get_distance_percent() -> float:
	return _current_distance / max_distance

func add_distance_reward(amount: float) -> void:
	_current_distance = min(max_distance, _current_distance + amount)
	distance_changed.emit(_current_distance)
	print("[ChaseSystem] Distance reward: +", amount)

func check_catch() -> bool:
	return _current_distance <= 0

func _on_segment_completed(segment_id: int) -> void:
	var reward = ConfigManager.get_game_config("追兵").get("distance_reward_segment_complete", 10)
	add_distance_reward(reward)

func _on_repair_completed() -> void:
	var reward = ConfigManager.get_game_config("追兵").get("distance_reward_repair", 15)
	add_distance_reward(reward)
