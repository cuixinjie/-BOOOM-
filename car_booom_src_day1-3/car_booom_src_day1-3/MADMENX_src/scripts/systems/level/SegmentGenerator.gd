## SegmentGenerator — 路段生成器
##
## 功能说明：
## - 根据关卡配置生成路段内容
## - 控制敌人生成、障碍物、特殊事件
## - 触发休息点
##
## Day 3 修复内容：
## 1. 集成障碍物实际生成（通过 ObjectPool）
## 2. 集成休息点触发逻辑（每3个路段触发一次）
## 3. 连接 SpecialSegmentManager 触发特殊路段
## 4. 向 RoadVisualizer 发送路段进度更新
##
## 对接注意事项：
## - 路段内容通过 EventBus.segment_content_ready 广播
## - 障碍物通过 ObjectPool 生成到 GameWorld
## - 休息点通过 EventBus.rest_point_enter_requested 触发
##
## 创建人：新街（主）、cjs（修复）
## 创建日期：2026-04-29
## 修复日期：2026-05-03

extends Node

signal segment_generated(segment_id: int, content: Dictionary)

var _current_segment_id: int = 0
var _is_generating: bool = false

var _segment_templates: Dictionary = {
	"normal": {"enemies": 5, "obstacles": 3},
	"dense": {"enemies": 10, "obstacles": 6},
	"sparse": {"enemies": 2, "obstacles": 1},
	"boss_approach": {"enemies": 8, "obstacles": 4},
}

var _obstacle_pool_names: Array = [
	"ObstacleBarrier",
	"ObstaclePothole",
	"ObstacleLarge",
]

var _special_segment_manager: Node = null
var _rest_point_cooldown: int = 0

const REST_POINT_INTERVAL: int = 3

# ===== 接口定义 =====
## start_generation(segment_id: int) -> void
##   开始生成路段
##
## generate_segment_content(segment_id: int) -> Dictionary
##   生成路段内容
## ===== 接口结束 =====

func _ready() -> void:
	_find_special_segment_manager()
	print("[SegmentGenerator] Initialized")

func _find_special_segment_manager() -> void:
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world and game_world.has_node("SpecialSegmentManager"):
		_special_segment_manager = game_world.get_node("SpecialSegmentManager")
	elif has_node("../SpecialSegmentManager"):
		_special_segment_manager = get_node("../SpecialSegmentManager")
	print("[SegmentGenerator] SpecialSegmentManager: ", _special_segment_manager)

func _process(_delta: float) -> void:
	pass

func start_generation(segment_id: int) -> void:
	_current_segment_id = segment_id
	_is_generating = true

	var content = generate_segment_content(segment_id)
	_is_generating = false

	segment_generated.emit(segment_id, content)
	EventBus.segment_content_ready.emit(segment_id, content.get("density", "normal"))

	print("[SegmentGenerator] Generated segment ", segment_id)

	_spawn_obstacles_for_segment(content.get("obstacles", 0))

	_trigger_special_event_if_needed(segment_id, content)

	_check_rest_point_trigger(segment_id)

	_update_road_progress(segment_id)

func generate_segment_content(segment_id: int) -> Dictionary:
	var difficulty = _get_segment_difficulty(segment_id)
	var density = _get_density_for_difficulty(difficulty)

	var content = {
		"segment_id": segment_id,
		"difficulty": difficulty,
		"density": density,
		"enemies": _segment_templates.get(density, {}).get("enemies", 5),
		"obstacles": _segment_templates.get(density, {}).get("obstacles", 3),
		"has_special_event": _should_have_special_event(segment_id),
		"special_type": _get_special_type(segment_id)
	}

	return content

func _get_segment_difficulty(segment_id: int) -> String:
	if segment_id % 10 == 0:
		return "boss_approach"
	elif segment_id % 3 == 0:
		return "dense"
	elif segment_id % 5 == 0:
		return "sparse"
	return "normal"

func _get_density_for_difficulty(difficulty: String) -> String:
	return difficulty

func _should_have_special_event(segment_id: int) -> bool:
	return segment_id > 0 and segment_id % 7 == 0

func _get_special_type(segment_id: int) -> String:
	var types = ["road_narrow", "fog", "emp", "traffic_jam"]
	return types[segment_id % types.size()]

func _spawn_obstacles_for_segment(obstacle_count: int) -> void:
	if obstacle_count <= 0:
		return

	var spawn_bounds = _get_spawn_bounds()
	var spawned = 0
	var attempts = 0

	while spawned < obstacle_count and attempts < obstacle_count * 3:
		attempts += 1
		var pool_name = _obstacle_pool_names[randi() % _obstacle_pool_names.size()]
		var scene_path = "res://scenes/entities/obstacles/" + pool_name + ".tscn"

		var obstacle = ObjectPool.get_object(pool_name, scene_path)
		if obstacle:
			var x_pos = randf_range(spawn_bounds["left"], spawn_bounds["right"])
			var y_pos = randf_range(spawn_bounds["top"], spawn_bounds["bottom"])
			obstacle.global_position = Vector2(x_pos, y_pos)
			obstacle.visible = true
			if obstacle.has_method("activate"):
				obstacle.activate()
			spawned += 1
			print("[SegmentGenerator] Spawned obstacle: ", pool_name, " at ", obstacle.global_position)

func _get_spawn_bounds() -> Dictionary:
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world and game_world.has_node("RoadVisualizer"):
		return game_world.get_node("RoadVisualizer").get_road_spawn_bounds()
	return {
		"left": 100.0,
		"right": 1820.0,
		"top": 320.0,
		"bottom": 760.0
	}

func _trigger_special_event_if_needed(_segment_id: int, content: Dictionary) -> void:
	if not content.get("has_special_event", false):
		return

	var special_type = content.get("special_type", "")
	if special_type == "":
		return

	if _special_segment_manager and _special_segment_manager.has_method("trigger_special_segment"):
		_special_segment_manager.trigger_special_segment(special_type)
		print("[SegmentGenerator] Triggered special segment: ", special_type)
	else:
		EventBus.special_segment_trigger_requested.emit(_get_special_type_enum(special_type), 15.0)
		print("[SegmentGenerator] Emitted special segment event: ", special_type)

func _get_special_type_enum(seg_type: String) -> int:
	match seg_type:
		"road_narrow": return 0
		"fog": return 1
		"emp": return 2
		"traffic_jam": return 3
	return 0

func _check_rest_point_trigger(segment_id: int) -> void:
	_rest_point_cooldown -= 1

	if segment_id == 0:
		return

	if _rest_point_cooldown > 0:
		return

	var level_config = ConfigMgr.get_level_config("Level01")
	if level_config.is_empty() or not level_config.get("has_rest_point", false):
		return

	if segment_id > 0 and segment_id % REST_POINT_INTERVAL == 0:
		_rest_point_cooldown = REST_POINT_INTERVAL
		EventBus.rest_point_enter_requested.emit()
		print("[SegmentGenerator] Rest point triggered at segment: ", segment_id)

func _update_road_progress(segment_id: int) -> void:
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world and game_world.has_node("RoadVisualizer"):
		var rv = game_world.get_node("RoadVisualizer")
		if rv.has_method("update_segment_progress"):
			var progress = float(segment_id % REST_POINT_INTERVAL) / float(REST_POINT_INTERVAL)
			rv.update_segment_progress(progress)
