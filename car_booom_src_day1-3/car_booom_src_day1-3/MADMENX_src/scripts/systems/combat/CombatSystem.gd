## CombatSystem — 战斗系统
##
## 功能说明：
## - 管理战斗相关逻辑
## - 协调敌人生成、战斗流程
##
## 对接注意事项：
## - 战斗激活状态由关卡事件驱动
## - 清空敌人时暂停战斗状态
##
## 创建人：长安旧梦
## 创建日期：2026-04-29

class_name CombatSystem
extends Node

var _active_combat: bool = false

func _ready() -> void:
	_connect_signals()
	print("[CombatSystem] Initialized")

func _connect_signals() -> void:
	EventBus.level_started.connect(_on_level_started)
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.all_enemies_cleared.connect(_on_all_enemies_cleared)

func _on_level_started(level_id: int) -> void:
	_active_combat = true

func _on_level_completed(level_id: int) -> void:
	_active_combat = false

func _on_all_enemies_cleared() -> void:
	print("[CombatSystem] All enemies cleared")
	_active_combat = false

func is_combat_active() -> bool:
	return _active_combat

func pause_combat() -> void:
	_active_combat = false

func resume_combat() -> void:
	_active_combat = true
