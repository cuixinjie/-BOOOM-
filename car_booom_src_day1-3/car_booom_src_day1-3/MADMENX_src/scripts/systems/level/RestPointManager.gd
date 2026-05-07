## RestPointManager — 躲藏点管理器
##
## 功能说明：
## - 管理躲藏点的触发和功能
## - 玩家在躲藏点可以恢复状态
##
## Day 5 完善内容：
## 1. 移除冗余的 ShopSystem.open_shop() 调用（由 HUDController 统一管理）
## 2. 能量恢复通过 ConfigManager 配置
## 3. 更清晰的状态管理
##
## 对接注意事项：
## - 进入躲藏点时暂停关卡
## - 离开躲藏点时继续关卡
## - 商店显示由 HUDController 监听 rest_point_entered 信号后统一处理
##
## 创建人：新街（主）、cjs（修复）
## 创建日期：2026-04-29
## 修复日期：2026-05-03
## Day 5完善：2026-05-05

extends Node

signal rest_point_entered()
signal rest_point_exited()

var _is_in_rest_point: bool = false
var _rest_point_count: int = 0
var _rest_point_ui: Control = null
var _enter_cooldown: float = 0.0
const ENTER_COOLDOWN_TIME: float = 2.0

var _is_pausing_game: bool = false

# ===== 接口定义 =====
## enter_rest_point() -> void
##   进入躲藏点
##
## exit_rest_point() -> void
##   离开躲藏点
##
## is_in_rest_point() -> bool
##   检查是否在躲藏点
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	_find_rest_point_ui()
	print("[RestPointManager] Initialized")

func _find_rest_point_ui() -> void:
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world and game_world.has_node("RestPointUI"):
		_rest_point_ui = game_world.get_node("RestPointUI")
		_rest_point_ui.visible = false

func _connect_signals() -> void:
	EventBus.rest_point_enter_requested.connect(_on_rest_point_enter_requested)
	EventBus.rest_point_exit_requested.connect(_on_rest_point_exit_requested)
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.game_over.connect(_on_game_over)

func _process(delta: float) -> void:
	if _enter_cooldown > 0:
		_enter_cooldown -= delta

func _on_rest_point_enter_requested() -> void:
	if _is_in_rest_point:
		return
	if _enter_cooldown > 0:
		return

	_enter_cooldown = ENTER_COOLDOWN_TIME
	enter_rest_point()

func enter_rest_point() -> void:
	if _is_in_rest_point:
		return

	_is_in_rest_point = true
	_rest_point_count += 1

	rest_point_entered.emit()
	EventBus.rest_point_entered.emit()
	print("[RestPointManager] Entered rest point #", _rest_point_count)

	_show_rest_point_ui()
	_pause_game_for_rest()
	_apply_rest_point_benefits()

func exit_rest_point() -> void:
	if not _is_in_rest_point:
		return

	_is_in_rest_point = false
	rest_point_exited.emit()
	EventBus.rest_point_exited.emit()
	print("[RestPointManager] Exited rest point")

	_hide_rest_point_ui()
	_resume_game_from_rest()

func _apply_rest_point_benefits() -> void:
	var coin_bonus = 50
	var health_restore_ratio = 0.5

	var shop_config = ConfigMgr.get_game_config("shop_items")
	if not shop_config.is_empty():
		var rewards = shop_config.get("rest_point_rewards", {})
		coin_bonus = rewards.get("coin_bonus", 50)
		health_restore_ratio = rewards.get("health_restore_ratio", 0.5)

	EconomySystem.add_coins(coin_bonus)
	EconomySystem.add_energy(20.0)

	var max_health = GameManager.get_max_vehicle_health()
	var heal_amount = max_health * health_restore_ratio
	GameManager.repair_vehicle(heal_amount)

	print("[RestPointManager] Rest point benefits applied: +", coin_bonus, " coins, +20 energy, +", heal_amount, " health")

func is_in_rest_point() -> bool:
	return _is_in_rest_point

func get_rest_point_count() -> int:
	return _rest_point_count

func _show_rest_point_ui() -> void:
	if _rest_point_ui:
		_rest_point_ui.visible = true

func _hide_rest_point_ui() -> void:
	if _rest_point_ui:
		_rest_point_ui.visible = false

func _pause_game_for_rest() -> void:
	_is_pausing_game = true
	GameManager.pause_game()

func _resume_game_from_rest() -> void:
	if not _is_in_rest_point:
		_is_pausing_game = false
		GameManager.resume_game()

func _on_rest_point_exit_requested() -> void:
	exit_rest_point()

func _on_level_completed(_level_id: int) -> void:
	if _is_in_rest_point:
		exit_rest_point()

func _on_game_over(_victory: bool) -> void:
	if _is_in_rest_point:
		exit_rest_point()
