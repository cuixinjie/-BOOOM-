## WorldStateSystem — 里世界切换系统
##
## 功能说明：
## - 管理表世界/里世界的具体切换逻辑
## - 处理视觉、敌人属性、玩家属性的反转
##
## 对接注意事项：
## - 切换逻辑由 WorldStateManager 触发
## - 切换效果在此系统实现
## - 视觉特效通过 EventBus 广播供 UI/Camera 层处理
##
## 创建人：长安旧梦
## 创建日期：2026-04-29
## 修复日期：2026-05-02

class_name WorldStateSystem
extends Node

const NORMAL_TINT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const INVERTED_TINT_COLOR: Color = Color(0.2, 0.3, 0.15, 1.0)

var _previous_world_state: int = 0
var _current_world_state: int = 0
var _is_inverted: bool = false

var _transition_tween: Tween = null

func _ready() -> void:
	_connect_signals()
	print("[WorldStateSystem] Initialized")

func _connect_signals() -> void:
	EventBus.world_state_changed.connect(_on_world_state_changed)
	EventBus.shield_state_inverted.connect(_on_shield_state_inverted)

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	_previous_world_state = from_state
	_current_world_state = to_state
	_is_inverted = to_state == 1

	match to_state:
		0:
			_apply_normal_world_effects()
		1:
			_apply_inverted_world_effects()

func _on_shield_state_inverted() -> void:
	print("[WorldStateSystem] Shield states inverted")

func _apply_normal_world_effects() -> void:
	print("[WorldStateSystem] Normal world effects applied")
	AudioManager.set_bgm_pitch(1.0)
	EventBus.world_tint_changed.emit(NORMAL_TINT_COLOR)
	EventBus.world_background_changed.emit("normal")
	_modify_enemy_properties(false)
	_modify_player_properties(false)

func _apply_inverted_world_effects() -> void:
	print("[WorldStateSystem] Inverted world effects applied")
	AudioManager.set_bgm_pitch(0.8)
	EventBus.world_tint_changed.emit(INVERTED_TINT_COLOR)
	EventBus.world_background_changed.emit("inverted")
	_modify_enemy_properties(true)
	_modify_player_properties(true)

func _modify_enemy_properties(inverted: bool) -> void:
	var enemies = _get_all_enemies()
	for enemy in enemies:
		if enemy.has_method("set_shield_inverted"):
			enemy.set_shield_inverted(inverted)
	print("[WorldStateSystem] Modified ", enemies.size(), " enemy properties")

func _modify_player_properties(inverted: bool) -> void:
	EventBus.role_swap_triggered.emit(0, 0)
	print("[WorldStateSystem] Player properties modified, roles swapped")

func _get_all_enemies() -> Array:
	var result: Array = []
	var groups = ["enemies", "enemy"]
	for group in groups:
		result.append_array(get_tree().get_nodes_in_group(group))
	return result

func is_in_inverted_world() -> bool:
	return _is_inverted
