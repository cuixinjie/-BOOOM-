## LevelManager — 关卡管理器
##
## 功能说明：
## - 管理关卡流程
## - 控制路段生成和切换
## - 管理 BOSS 战
##
## 对接注意事项：
## - 被 GameManager 调用
## - 依赖 SpawnSystem, SegmentGenerator
##
## 创建人：新街
## 创建日期：2026-04-28

class_name LevelManager
extends Node

signal level_started(level_id: int)
signal segment_changed(segment_id: int)
signal level_completed(level_id: int)

@export var current_level_id: String = "level_01"

var _current_segment: int = 0
var _total_segments: int = 0
var _segment_timer: float = 0.0
var _is_level_active: bool = false

var _spawn_system: Node = null
var _segment_generator: Node = null

# ===== 接口定义 =====
## start_level(level_id: String) -> void
##   开始关卡
##
## next_segment() -> void
##   进入下一路段
##
## enter_rest_point() -> void
##   进入躲藏点
##
## spawn_boss() -> void
##   生成 BOSS
##
## complete_level() -> void
##   完成关卡
## ===== 接口结束 =====

func _ready() -> void:
	_spawn_system = get_node("/root/SpawnSystem") if has_node("/root/SpawnSystem") else null
	print("[LevelManager] Initialized")

func _process(delta: float) -> void:
	if not _is_level_active:
		return
	
	_segment_timer -= delta
	if _segment_timer <= 0:
		next_segment()

func start_level(level_id: String) -> void:
	current_level_id = level_id
	var level_config = ConfigManager.get_level_config(level_id)
	
	if level_config.is_empty():
		push_error("[LevelManager] Level config not found: " + level_id)
		return
	
	_total_segments = level_config.get("segments", []).size()
	_current_segment = 0
	_is_level_active = true
	level_started.emit(level_id)
	EventBus.game_started.emit()
	
	_load_segment(0)
	print("[LevelManager] Level started: ", level_id)

func _load_segment(index: int) -> void:
	var level_config = ConfigManager.get_level_config(current_level_id)
	var segments = level_config.get("segments", [])
	
	if index >= segments.size():
		_on_all_segments_completed()
		return
	
	var segment = segments[index]
	_segment_timer = segment.get("duration", 30.0)
	_current_segment = index
	segment_changed.emit(index)
	
	if _spawn_system:
		var enemies = segment.get("enemies", [])
		var spawn_rate = segment.get("spawn_rate", 2.0)
		_spawn_system.start_spawning(enemies, spawn_rate)
	
	EventBus.segment_completed.emit(index)
	print("[LevelManager] Segment loaded: ", index)

func next_segment() -> void:
	if _spawn_system:
		_spawn_system.stop_spawning()
	
	_current_segment += 1
	
	if _current_segment < _total_segments:
		_load_segment(_current_segment)
	else:
		_on_all_segments_completed()

func _on_all_segments_completed() -> void:
	var level_config = ConfigManager.get_level_config(current_level_id)
	if level_config.get("rest_point", {}).get("enabled", false):
		enter_rest_point()
	elif level_config.get("boss_enabled", false):
		spawn_boss()
	else:
		complete_level()

func enter_rest_point() -> void:
	_is_level_active = false
	EventBus.rest_point_entered.emit()
	print("[LevelManager] Rest point entered")

func exit_rest_point() -> void:
	if _current_segment < _total_segments - 1:
		next_segment()
	else:
		complete_level()

func spawn_boss() -> void:
	_is_level_active = false
	var level_config = ConfigManager.get_level_config(current_level_id)
	var boss_type = level_config.get("boss_type", "boss_01")
	
	if _spawn_system:
		_spawn_system.spawn_boss(boss_type)
	
	EventBus.boss_spawned.emit(null)
	print("[LevelManager] Boss spawned: ", boss_type)

func complete_level() -> void:
	_is_level_active = false
	level_completed.emit(current_level_id)
	print("[LevelManager] Level completed: ", current_level_id)
	GameManager.next_level()

func get_current_segment() -> int:
	return _current_segment

func get_total_segments() -> int:
	return _total_segments

func get_segment_progress() -> float:
	if _total_segments <= 0:
		return 0.0
	return float(_current_segment) / float(_total_segments)
