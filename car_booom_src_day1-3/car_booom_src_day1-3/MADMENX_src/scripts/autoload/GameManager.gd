## GameManager — 游戏总管理器
##
## 功能说明：
## - 管理游戏主状态（菜单、游戏中、暂停、结束）
## - 协调各系统初始化和清理
## - 提供游戏流程控制接口
##
## 对接注意事项：
## - 被所有系统依赖，但不应依赖其他单例
## - 游戏状态变更通过 EventBus 广播
##
## 创建人：cjs（主）、新街（扩展）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

extends Node

enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

var current_state: GameState = GameState.MAIN_MENU
var current_level: int = 1
var is_paused: bool = false

var _vehicle_health: float = 100.0
var _max_vehicle_health: float = 100.0
var _game_config_initialized: bool = false

var _vehicle_speed: float = 0.0

var _score: int = 0

var is_breakdown_recovery: bool = false

# ===== 接口定义 =====
## start_game() -> void
##   开始新游戏，初始化所有系统
##
## pause_game() -> void
##   暂停游戏
##
## resume_game() -> void
##   继续游戏
##
## end_game(victory: bool) -> void
##   结束游戏，victory=true 表示胜利
##
## get_game_state() -> GameState
##   返回当前游戏状态
##
## is_playing() -> bool
##   返回是否正在游戏中
##
## get_vehicle_health() -> float
##   返回当前机车血量
##
## damage_vehicle(amount: float) -> void
##   对机车造成伤害
##
## repair_vehicle(amount: float) -> void
##   修复机车
## ===== 接口结束 =====

func _process(_delta: float) -> void:
	if not _game_config_initialized and Engine.get_process_frames() > 2:
		_initialize_game_config()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _initialize_game_config() -> void:
	_connect_signals()
	var config = ConfigMgr.get_game_config("vehicle")
	if config:
		_max_vehicle_health = config.get("max_health", 100.0)
		_vehicle_health = _max_vehicle_health
	_game_config_initialized = true

func _connect_signals() -> void:
	EventBus.game_pause_requested.connect(_on_game_pause_requested)
	EventBus.game_resume_requested.connect(_on_game_resume_requested)
	EventBus.game_restart_requested.connect(_on_game_restart_requested)
	EventBus.level_start_requested.connect(_on_level_start_requested)
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.vehicle_speed_changed.connect(_on_vehicle_speed_changed)

func start_game() -> void:
	current_state = GameState.PLAYING
	_vehicle_health = _max_vehicle_health
	_score = 0
	current_level = 1
	is_breakdown_recovery = false
	EventBus.game_started.emit()
	print("[GameManager] Game started")

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		is_paused = true
		get_tree().paused = true
		EventBus.game_paused.emit()
		print("[GameManager] Game paused")

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		is_paused = false
		get_tree().paused = false
		EventBus.game_resumed.emit()
		print("[GameManager] Game resumed")

func end_game(victory: bool) -> void:
	if victory:
		current_state = GameState.VICTORY
		print("[GameManager] Victory!")
	else:
		current_state = GameState.GAME_OVER
		print("[GameManager] Game Over")
	get_tree().paused = true
	EventBus.game_over.emit(victory)

func get_game_state() -> GameState:
	return current_state

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func get_vehicle_health() -> float:
	return _vehicle_health

func get_max_vehicle_health() -> float:
	return _max_vehicle_health

func get_vehicle_speed() -> float:
	return _vehicle_speed

func _on_vehicle_speed_changed(speed: float) -> void:
	_vehicle_speed = speed

func damage_vehicle(amount: float) -> void:
	if is_breakdown_recovery:
		return

	_vehicle_health = max(0, _vehicle_health - amount)
	EventBus.vehicle_damaged.emit(amount)
	print("[GameManager] Vehicle damaged: ", amount, " | Health: ", _vehicle_health)

	if _vehicle_health <= 0:
		_trigger_breakdown()

func repair_vehicle(amount: float) -> void:
	_vehicle_health = min(_max_vehicle_health, _vehicle_health + amount)
	EventBus.vehicle_repaired.emit(amount)
	print("[GameManager] Vehicle repaired: ", amount, " | Health: ", _vehicle_health)

func _trigger_breakdown() -> void:
	is_breakdown_recovery = true
	EventBus.vehicle_breakdown.emit()
	print("[GameManager] Breakdown triggered!")

func complete_breakdown_recovery() -> void:
	is_breakdown_recovery = false
	var heal_amount = _max_vehicle_health * 0.3
	repair_vehicle(heal_amount)
	EventBus.repair_completed.emit()
	print("[GameManager] Breakdown recovery completed, healed: ", heal_amount)

func fail_breakdown_recovery() -> void:
	is_breakdown_recovery = false
	end_game(false)
	EventBus.repair_failed.emit()
	print("[GameManager] Breakdown recovery failed!")

func add_score(amount: int) -> void:
	_score += amount
	EventBus.score_changed.emit(_score)
	print("[GameManager] Score: ", _score)

func get_score() -> int:
	return _score

func next_level() -> void:
	current_level += 1
	print("[GameManager] Entering level: ", current_level)

func get_current_level_id() -> int:
	return current_level

## get_current_level_id_string() -> String
##   获取当前关卡ID的字符串格式（用于配置读取）
##   例如：current_level=1 返回 "Level01"
func get_current_level_id_string() -> String:
	return "Level%02d" % current_level

func restart_level() -> void:
	current_level = 1
	_vehicle_health = _max_vehicle_health
	_score = 0
	is_breakdown_recovery = false
	EventBus.game_started.emit()
	print("[GameManager] Level restarted")

func _on_game_pause_requested() -> void:
	pause_game()

func _on_game_resume_requested() -> void:
	resume_game()

func _on_game_restart_requested() -> void:
	restart_level()

func _on_level_start_requested(level_id: String) -> void:
	print("[GameManager] Level start requested: ", level_id)

func _on_level_completed(_level_id: int) -> void:
	next_level()

func _on_boss_phase_timeout() -> void:
	print("[GameManager] Boss phase timeout — triggering game over")
	end_game(false)
