## LevelManager — 关卡管理器
##
## 功能说明：
## - 管理关卡的开始、进度、完成
## - 协调路段生成和敌人生成
##
## 对接注意事项：
## - 关卡状态通过 EventBus 广播
## - 路段切换通过 SegmentGenerator
##
## 创建人：新街（主）、cjs（配置加载）
## 创建日期：2026-04-29
## 合并日期：2026-05-02

class_name LevelManager
extends Node

signal level_started(level_id: int)
signal level_completed(level_id: int)
signal segment_started(segment_id: int)
signal segment_completed(segment_id: int)

enum LevelState {
	IDLE,
	LOADING,
	PLAYING,
	PAUSED,
	COMPLETED,
	GAME_OVER
}

var current_level_id: String = "Level01"
var level_state: LevelState = LevelState.IDLE

var _current_segment_index: int = 0
var _total_segments: int = 10
var _level_config: Dictionary = {}

var _is_in_rest_point: bool = false

# ===== 接口定义 =====
## start_level(level_id: String) -> void
##   开始关卡
##
## pause_level() -> void
##   暂停关卡
##
## resume_level() -> void
##   继续关卡
##
## get_current_segment() -> int
##   获取当前路段索引
##
## advance_segment() -> void
##   进入下一个路段
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	print("[LevelManager] Initialized")

func _connect_signals() -> void:
	EventBus.segment_completed.connect(_on_segment_completed)
	EventBus.rest_point_entered.connect(_on_rest_point_entered)
	EventBus.rest_point_exited.connect(_on_rest_point_exited)
	EventBus.all_enemies_cleared.connect(_on_all_enemies_cleared)
	EventBus.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	# 游戏开始时启动关卡
	start_level(current_level_id)

func start_level(level_id: String) -> void:
	current_level_id = level_id
	level_state = LevelState.LOADING
	_current_segment_index = 0

	_level_config = ConfigMgr.get_level_config(level_id)
	if _level_config.is_empty():
		push_warning("[LevelManager] Level config not found: " + level_id + ", using defaults")
		_level_config = {"total_segments": 10, "name": "Default Level"}

	_total_segments = _level_config.get("total_segments", 10)
	print("[LevelManager] Starting level: ", level_id, " with ", _total_segments, " segments")

	level_state = LevelState.PLAYING
	level_started.emit(_get_level_number())
	EventBus.level_start_requested.emit(level_id)
	segment_started.emit(_current_segment_index)
	EventBus.segment_changed.emit(_current_segment_index)

	# 启动路段生成
	var segment_gen = _get_segment_generator()
	if segment_gen:
		segment_gen.start_generation(_current_segment_index)

func _get_segment_generator() -> Node:
	# 优先使用 Autoload 全局单例（project.godot 中注册）
	if has_node("/root/SegmentGenerator"):
		var sg = get_node("/root/SegmentGenerator")
		if sg.has_method("start_generation"):
			return sg

	# 其次在当前节点下查找 SegmentGenerator
	if has_node("SegmentGenerator"):
		var seg_gen = get_node("SegmentGenerator")
		if seg_gen.has_method("start_generation"):
			return seg_gen

	# 尝试通过 GameWorld 组查找
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world and game_world.has_node("SegmentGenerator"):
		var seg_gen = game_world.get_node("SegmentGenerator")
		if seg_gen.has_method("start_generation"):
			return seg_gen

	# 最后才创建内联生成器
	var gen = Node.new()
	gen.set_script(load("res://scripts/systems/level/SegmentGenerator.gd"))
	gen.name = "SegmentGenerator"
	add_child(gen)
	print("[LevelManager] Created inline SegmentGenerator (Autoload not found)")
	return gen

func pause_level() -> void:
	if level_state == LevelState.PLAYING:
		level_state = LevelState.PAUSED
		print("[LevelManager] Level paused")

func resume_level() -> void:
	if level_state == LevelState.PAUSED:
		level_state = LevelState.PLAYING
		print("[LevelManager] Level resumed")

func _on_segment_completed(segment_id: int) -> void:
	print("[LevelManager] Segment ", segment_id, " completed")

func _on_all_enemies_cleared() -> void:
	# 所有敌人被清除，进入下一路段
	print("[LevelManager] All enemies cleared")
	advance_segment()

func advance_segment() -> void:
	_current_segment_index += 1
	segment_completed.emit(_current_segment_index)
	EventBus.segment_completed.emit(_current_segment_index)

	if _current_segment_index >= _total_segments:
		_complete_level()
	else:
		segment_started.emit(_current_segment_index)
		EventBus.segment_changed.emit(_current_segment_index)

		# 启动下一路段的生成
		var segment_gen = _get_segment_generator()
		if segment_gen and segment_gen.has_method("start_generation"):
			segment_gen.start_generation(_current_segment_index)

func _complete_level() -> void:
	level_state = LevelState.COMPLETED
	var level_num = _get_level_number()
	level_completed.emit(level_num)
	EventBus.level_completed.emit(level_num)
	print("[LevelManager] Level completed!")

	# 触发胜利
	GameManager.end_game(true)

func _on_rest_point_entered() -> void:
	_is_in_rest_point = true
	pause_level()

func _on_rest_point_exited() -> void:
	_is_in_rest_point = false
	resume_level()

func get_current_segment() -> int:
	return _current_segment_index

func get_total_segments() -> int:
	return _total_segments

func _get_level_number() -> int:
	var num_str = current_level_id.replace("Level", "").replace("level", "")
	return int(num_str) if num_str.is_valid_int() else 1

func get_level_config() -> Dictionary:
	return _level_config
