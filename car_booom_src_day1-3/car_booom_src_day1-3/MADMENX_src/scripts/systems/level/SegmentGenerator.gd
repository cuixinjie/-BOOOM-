## SegmentGenerator — 路段生成器
##
## 功能说明：
## - 根据关卡配置生成路段内容
## - 控制敌人生成、障碍物、特殊事件
## - 触发休息点
##
## Day 5 完善内容：
## 1. 从 level_config.json 读取路段配置（替代硬编码难度模式）
## 2. 读取 segment_types 配置
## 3. 读取各关卡的敌人类型列表
## 4. 障碍密度与路段类型对齐
##
## Day 6 完善内容：
## 1. 敌人类型过滤逻辑增强，支持动态填充
## 2. 更健壮的空配置处理
## 3. 多效果叠加支持
##
## 对接注意事项：
## - 路段内容通过 EventBus.segment_content_ready 广播
## - 障碍物通过 ObjectPool 生成到 GameWorld
## - 休息点通过 EventBus.rest_point_enter_requested 触发
## - 特殊事件通过 SpecialSegmentManager 处理多效果叠加
##
## 创建人：新街（主）、cjs（修复）
## 创建日期：2026-04-29
## 修复日期：2026-05-03
## Day 5完善：2026-05-05
## Day 6完善：敌人类型动态填充、边界处理增强（2026-05-05）

extends Node

signal segment_generated(segment_id: int, content: Dictionary)

var _current_segment_id: int = 0
var _is_generating: bool = false
var _current_level_id: String = "Level01"
var _level_config: Dictionary = {}
var _full_config: Dictionary = {}

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
	_connect_signals()
	print("[SegmentGenerator] Initialized")

func _find_special_segment_manager() -> void:
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world and game_world.has_node("SpecialSegmentManager"):
		_special_segment_manager = game_world.get_node("SpecialSegmentManager")
	elif has_node("../SpecialSegmentManager"):
		_special_segment_manager = get_node("../SpecialSegmentManager")

func _connect_signals() -> void:
	EventBus.level_start_requested.connect(_on_level_start_requested)
	EventBus.traffic_jam_obstacles_requested.connect(_on_traffic_jam_obstacles_requested)

func _on_level_start_requested(level_id: String) -> void:
	_load_level_config(level_id)

func _load_level_config(level_id: String) -> void:
	_current_level_id = level_id
	_level_config = ConfigMgr.get_level_config(level_id)
	_full_config = _load_full_level_config()
	if _level_config.is_empty():
		_level_config = {}
	print("[SegmentGenerator] Loaded level config for: ", level_id)

func _load_full_level_config() -> Dictionary:
	if ResourceLoader.exists("res://assets/configs/level_config.json"):
		var file = FileAccess.open("res://assets/configs/level_config.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			if parse_result == OK:
				return json.get_data()
	return {}

func _process(_delta: float) -> void:
	pass

func start_generation(segment_id: int) -> void:
	_current_segment_id = segment_id
	_is_generating = true

	var content = generate_segment_content(segment_id)
	_is_generating = false

	segment_generated.emit(segment_id, content)
	EventBus.segment_content_ready.emit(segment_id, content.get("density", "normal"))

	print("[SegmentGenerator] Generated segment ", segment_id, " (", content.get("density", "unknown"), ")")

	_spawn_obstacles_for_segment(content.get("obstacles", 0), content.get("density", "normal"))

	_trigger_special_event_if_needed(segment_id, content)

	_check_rest_point_trigger(segment_id)

	_update_road_progress(segment_id)

func generate_segment_content(segment_id: int) -> Dictionary:
	var segment_type = _get_segment_type(segment_id)
	var segment_config = _get_segment_config(segment_type)

	var content = {
		"segment_id": segment_id,
		"segment_type": segment_type,
		"density": segment_type,
		"enemies": segment_config.get("enemies", 5),
		"obstacles": segment_config.get("obstacles", 3),
		"enemy_speed_modifier": segment_config.get("enemy_speed_modifier", 1.0),
		"duration": segment_config.get("duration", 15),
		"has_special_event": _should_have_special_event(segment_id),
		"special_type": _get_special_type(segment_id),
		"enemy_types": _get_enemy_types_for_segment(segment_id)
	}

	return content

func _get_segment_type(segment_id: int) -> String:
	var level_segments = _level_config.get("total_segments", 10)
	var _segment_templates = _get_segment_templates()  # 保留用于将来扩展

	if segment_id < 0 or segment_id >= level_segments:
		return "normal"

	var segment_position = float(segment_id) / float(level_segments)

	if segment_position >= 0.9:
		return "boss_approach"
	elif segment_position >= 0.6:
		return "dense"
	elif segment_position >= 0.3:
		return "normal"
	else:
		return "sparse"

func _get_segment_config(segment_type: String) -> Dictionary:
	var segment_types = _full_config.get("segment_types", {})
	if segment_types is Dictionary and segment_types.has(segment_type):
		return segment_types[segment_type]

	var level_segment_types = _level_config.get("segment_types", {})
	if level_segment_types is Dictionary and level_segment_types.has(segment_type):
		return level_segment_types[segment_type]

	var default_templates = _get_segment_templates()
	return default_templates.get(segment_type, default_templates["normal"])

func _get_segment_templates() -> Dictionary:
	return {
		"normal": {"enemies": 5, "obstacles": 3, "duration": 15, "enemy_speed_modifier": 1.0},
		"dense": {"enemies": 10, "obstacles": 6, "duration": 20, "enemy_speed_modifier": 1.1},
		"sparse": {"enemies": 2, "obstacles": 1, "duration": 10, "enemy_speed_modifier": 0.9},
		"boss_approach": {"enemies": 8, "obstacles": 4, "duration": 30, "enemy_speed_modifier": 1.2}
	}

func _should_have_special_event(segment_id: int) -> bool:
	if _level_config.is_empty():
		return segment_id > 0 and segment_id % 7 == 0
	var special_events = _level_config.get("special_events", [])
	return segment_id > 0 and segment_id % 7 == 0 and not special_events.is_empty()

func _get_special_type(segment_id: int) -> String:
	var default_types = ["road_narrow", "fog", "emp", "traffic_jam"]

	if not _level_config.is_empty():
		var special_events = _level_config.get("special_events", [])
		if not special_events.is_empty():
			return special_events[segment_id % special_events.size()]

	return default_types[segment_id % default_types.size()]

func _get_enemy_types_for_segment(segment_id: int) -> Array:
	if not _level_config.is_empty():
		var enemy_types = _level_config.get("enemy_types", [])
		if not enemy_types.is_empty():
			var segment_position = float(segment_id) / float(_level_config.get("total_segments", 10))
			var type_count = _get_enemy_type_count(segment_position)
			return _filter_enemy_types_by_count(enemy_types, type_count)

	# 默认敌人类型配置
	if segment_id < 3:
		return ["drone_basic"]
	elif segment_id < 6:
		return ["drone_basic", "drone_basic"]
	elif segment_id < 10:
		return ["drone_basic", "drone_basic", "drone_laser"]
	else:
		return ["drone_basic", "drone_laser", "drone_healer", "enemy_bike"]

func _get_enemy_type_count(segment_position: float) -> int:
	if segment_position >= 0.8:
		return 4  # 全部4种敌人
	elif segment_position >= 0.5:
		return 3  # 3种敌人
	elif segment_position >= 0.2:
		return 2  # 2种敌人
	return 1  # 只有基础敌人

func _filter_enemy_types_by_count(enemy_types: Array, count: int) -> Array:
	var result: Array = []
	for i in range(count):
		var idx = i % enemy_types.size()
		if not enemy_types[idx] in result:
			result.append(enemy_types[idx])
	# 如果结果数量不足，重复已有类型填充
	while result.size() < count and not enemy_types.is_empty():
		result.append(enemy_types[result.size() % enemy_types.size()])
	return result

func _spawn_obstacles_for_segment(obstacle_count: int, density: String = "normal") -> void:
	if obstacle_count <= 0:
		return

	var adjusted_count = _adjust_obstacle_count(obstacle_count, density)

	var spawn_bounds = _get_spawn_bounds()
	var spawned = 0
	var attempts = 0
	var max_attempts = adjusted_count * 5

	while spawned < adjusted_count and attempts < max_attempts:
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

	if spawned > 0:
		print("[SegmentGenerator] Spawned ", spawned, " obstacles (density: ", density, ")")

func _adjust_obstacle_count(base_count: int, density: String) -> int:
	match density:
		"dense": return int(base_count * 1.5)
		"sparse": return int(base_count * 0.6)
		"boss_approach": return int(base_count * 1.2)
	return base_count

func _get_spawn_bounds() -> Dictionary:
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world and game_world.has_node("RoadVisualizer"):
		var rv = game_world.get_node("RoadVisualizer")
		if rv.has_method("get_road_spawn_bounds"):
			return rv.get_road_spawn_bounds()
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
		EventBus.emit_signal("special_segment_trigger_requested", _get_special_type_enum(special_type), _get_special_duration(special_type))
		print("[SegmentGenerator] Emitted special segment event: ", special_type)

func _get_special_type_enum(seg_type: String) -> int:
	match seg_type:
		"road_narrow": return 0
		"fog": return 1
		"emp": return 2
		"traffic_jam": return 3
	return 0

func _get_special_duration(seg_type: String) -> float:
	var special_config = _level_config.get("special_events_config", {})
	if special_config is Dictionary and special_config.has(seg_type):
		return special_config[seg_type].get("duration", 15.0)

	match seg_type:
		"road_narrow": return 15.0
		"fog": return 20.0
		"emp": return 10.0
		"traffic_jam": return 12.0
	return 15.0

func _check_rest_point_trigger(segment_id: int) -> void:
	_rest_point_cooldown -= 1

	if segment_id == 0:
		return

	if _rest_point_cooldown > 0:
		return

	var has_rest_point = true
	if not _level_config.is_empty():
		has_rest_point = _level_config.get("has_rest_point", true)

	if not has_rest_point:
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
			var total_segments = _level_config.get("total_segments", 10)
			var progress = float(segment_id % REST_POINT_INTERVAL) / float(REST_POINT_INTERVAL)
			rv.update_segment_progress(progress)
			if rv.has_method("set_total_segments"):
				rv.set_total_segments(total_segments)

# ===== Traffic Jam 障碍物生成（Day 6新增）=====

var _traffic_jam_obstacles: Array = []  # 追踪 Traffic Jam 生成的障碍物
var _is_traffic_jam_active: bool = false

func _on_traffic_jam_obstacles_requested(multiplier: float) -> void:
	# 标记 Traffic Jam 激活状态
	_is_traffic_jam_active = true
	
	# 清除之前的 Traffic Jam 障碍物
	_clear_traffic_jam_obstacles()
	
	# 生成额外的障碍物
	var base_obstacles = 3  # 默认基础障碍物数量
	var extra_obstacles = int(base_obstacles * (multiplier - 1.0))
	var total_obstacles = base_obstacles + extra_obstacles
	
	_spawn_traffic_jam_obstacles(total_obstacles)
	print("[SegmentGenerator] Traffic jam spawned ", total_obstacles, " obstacles (multiplier: ", multiplier, ")")

func _spawn_traffic_jam_obstacles(count: int) -> void:
	var spawn_bounds = _get_spawn_bounds()
	var spawned = 0
	var attempts = 0
	var max_attempts = count * 5

	while spawned < count and attempts < max_attempts:
		attempts += 1
		var pool_name = _obstacle_pool_names[randi() % _obstacle_pool_names.size()]
		var scene_path = "res://scenes/entities/obstacles/" + pool_name + ".tscn"

		var obstacle = ObjectPool.get_object(pool_name, scene_path)
		if obstacle:
			obstacle.set("pool_name", pool_name)  # 保存池名以便回收
			var x_pos = randf_range(spawn_bounds["left"], spawn_bounds["right"])
			var y_pos = randf_range(spawn_bounds["top"], spawn_bounds["bottom"])
			obstacle.global_position = Vector2(x_pos, y_pos)
			obstacle.visible = true
			if obstacle.has_method("activate"):
				obstacle.activate()
			_traffic_jam_obstacles.append(obstacle)
			spawned += 1

func _clear_traffic_jam_obstacles() -> void:
	for obstacle in _traffic_jam_obstacles:
		if is_instance_valid(obstacle):
			if obstacle.has_method("deactivate"):
				obstacle.deactivate()
			var pool_name = obstacle.get("pool_name", "")
			if pool_name != "":
				ObjectPool.return_object(pool_name, obstacle)
	_traffic_jam_obstacles.clear()
	_is_traffic_jam_active = false
	print("[SegmentGenerator] Cleared traffic jam obstacles")
