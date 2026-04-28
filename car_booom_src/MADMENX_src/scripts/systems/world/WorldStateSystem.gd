## WorldStateSystem — 里世界切换系统
##
## 功能说明：
## - 管理表世界/里世界切换
## - 处理无敌状态反转
## - 协调背景和音效切换
##
## 对接注意事项：
## - 被 WorldStateManager 调用
## - 通过 EventBus.world_state_changed 广播
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name WorldStateSystem
extends Node

var _current_world: int = WorldStateManager.WorldState.NORMAL

# ===== 接口定义 =====
## invert_shield_states() -> void
##   反转所有敌人护盾状态
##
## get_inverted_shield_state(enemy: Node) -> bool
##   获取敌人反转后的护盾状态
##
## swap_player_roles() -> void
##   互换玩家职责
##
## set_world_state(state: int) -> void
##   设置世界状态
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	print("[WorldStateSystem] Initialized")

func _connect_signals() -> void:
	EventBus.world_state_changed.connect(_on_world_state_changed)

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	_current_world = to_state
	invert_shield_states()
	print("[WorldStateSystem] World state changed to: ", to_state)

func invert_shield_states() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("invert_shield"):
			enemy.invert_shield()
	
	EventBus.shield_state_inverted.emit()
	print("[WorldStateSystem] All enemy shields inverted")

func get_inverted_shield_state(enemy: Node) -> bool:
	if not enemy.has_method("is_shielded"):
		return false
	
	var base_state = enemy.is_shielded()
	var is_inverted = _current_world == WorldStateManager.WorldState.INVERTED
	return base_state != is_inverted

func swap_player_roles() -> void:
	EventBus.role_swap_triggered.emit(2, 1)
	print("[WorldStateSystem] Player roles swapped")

func set_world_state(state: int) -> void:
	_current_world = state
