## PlayerBase — 玩家基类
##
## 功能说明：
## - 玩家角色基类
## - 提供输入处理、移动、状态管理
##
## 对接注意事项：
## - 被 Driver、Shooter 继承
## - 输入通过 InputManager 获取
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name PlayerBase
extends LivingEntity

@export var player_id: int = 1
@export var player_name: String = "Player"

signal player_ready(player_id: int)
signal player_input_received(input_data: Dictionary)

var _input_enabled: bool = true
var _state_machine: Node

# ===== 接口定义 =====
## get_player_id() -> int
##   获取玩家ID
##
## enable_input() -> void
##   启用输入
##
## disable_input() -> void
##   禁用输入
##
## is_input_enabled() -> bool
##   检查输入是否启用
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	add_to_group("players")
	add_to_group("player_" + str(player_id))
	print("[PlayerBase] Player ", player_id, " ready")

func _process(delta: float) -> void:
	if _input_enabled:
		_process_input(delta)

func _process_input(delta: float) -> void:
	pass

func get_player_id() -> int:
	return player_id

func enable_input() -> void:
	_input_enabled = true

func disable_input() -> void:
	_input_enabled = false

func is_input_enabled() -> bool:
	return _input_enabled

func _on_damaged(damage_info) -> void:
	EventBus.player_damaged.emit(self, damage_info.base_damage)
