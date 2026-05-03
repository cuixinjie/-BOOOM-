## WorldStateManager — 里世界状态管理器
##
## 功能说明：
## - 管理表世界/里世界切换
## - 处理无敌状态反转
## - 处理玩家职责互换
## - 协调自动切换定时器
##
## 对接注意事项：
## - 被 WorldStateSystem、RoleSwapSystem 调用
## - 切换通过 EventBus.world_state_changed 广播
## - 预警通过 EventBus.world_swap_warning 广播
##
## 创建人：cjs（主）、长安旧梦（接口规范）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

extends Node

const STATE_NORMAL: int = 0
const STATE_INVERTED: int = 1

var current_world: int = STATE_NORMAL
var swap_timer: float = 0.0
var swap_interval: float = 30.0
var is_warning_active: bool = false
var warning_duration: float = 2.0

var _is_swap_in_progress: bool = false

# ===== 接口定义 =====
## get_current_world() -> WorldState
##   返回当前世界状态
##
## trigger_world_swap() -> void
##   触发世界切换
##
## is_in_inverted_world() -> bool
##   返回是否在里世界
##
## start_auto_swap_timer(interval: float) -> void
##   启动自动切换定时器
##
## stop_auto_swap_timer() -> void
##   停止自动切换定时器
## ===== 接口结束 =====

func _ready() -> void:
	var config = ConfigMgr.get_game_config("world_swap")
	if config:
		swap_interval = config.get("auto_swap_interval", 30.0)
		warning_duration = config.get("warning_duration", 2.0)

func _process(delta: float) -> void:
	if swap_timer > 0:
		swap_timer -= delta
		if swap_timer <= warning_duration and not is_warning_active:
			_start_warning()
		if swap_timer <= 0 and not _is_swap_in_progress:
			_execute_swap()

func _start_warning() -> void:
	is_warning_active = true
	EventBus.world_swap_warning.emit(warning_duration)
	print("[WorldStateManager] World swap warning!")
	AudioManager.play_sfx("warning")

func _execute_swap() -> void:
	_is_swap_in_progress = true
	var previous_world = current_world

	if current_world == STATE_NORMAL:
		current_world = STATE_INVERTED
		AudioManager.set_bgm_pitch(0.8)
	else:
		current_world = STATE_NORMAL
		AudioManager.set_bgm_pitch(1.0)

	is_warning_active = false
	swap_timer = 0.0
	_is_swap_in_progress = false

	EventBus.world_state_changed.emit(previous_world, current_world)
	EventBus.shield_state_inverted.emit()

	print("[WorldStateManager] World swapped to: ", "INVERTED" if current_world == STATE_INVERTED else "NORMAL")

func trigger_world_swap() -> void:
	if _is_swap_in_progress:
		return

	is_warning_active = true
	_start_warning()
	swap_timer = warning_duration

func get_current_world() -> int:
	return current_world

func is_in_inverted_world() -> bool:
	return current_world == STATE_INVERTED

func start_auto_swap_timer(interval: float = swap_interval) -> void:
	swap_interval = interval
	swap_timer = swap_interval

func stop_auto_swap_timer() -> void:
	swap_timer = 0.0
	is_warning_active = false

func get_swap_progress() -> float:
	if swap_timer <= 0:
		return 0.0
	if is_warning_active:
		return 1.0 - (swap_timer / warning_duration)
	return 1.0 - (swap_timer / swap_interval)
