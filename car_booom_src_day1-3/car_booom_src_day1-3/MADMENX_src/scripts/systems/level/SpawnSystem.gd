## SpawnSystem — 敌人生成系统
##
## 功能说明：
## - 根据路段配置生成敌人
## - 管理敌人生成的节奏和类型
## - 应用路段难度修正（敌人血量/速度随段位递增）
## - 敌人生成节奏根据难度曲线动态调整
## - 敌人类型动态调度(l1→l1+l2→l1+l2+l3)
##
## Day 4完善内容（长安旧梦）：
## 1. 添加敌人生成节奏配置支持（spawn_patterns）
## 2. 敌人类型动态调度：根据路段解锁更高级敌人
## 3. 敌人生成间隔随难度曲线动态调整
##
## 对接注意事项：
## - 敌人类型通过 ConfigManager 获取
## - 敌人生成后自动设置目标
## - 难度修正通过 enemy_speed_modifier 和 enemy_health_modifier 传递给敌人
## - 敌人类型与level_config.json的enemy_types配置对齐
## - 敌人生成节奏从enemy_stats.json的spawn_patterns读取
##
## 创建人：新街（主）、长安旧梦（Day4完善）
## 创建日期：2026-04-29
## 合并日期：2026-05-02
## Day 4完善：敌人生成节奏与动态调度（2026-05-06）

extends Node

signal spawn_wave_completed(wave: int)
signal all_enemies_cleared()
signal enemy_type_unlocked(enemy_type: String)

var _active_enemies: Array = []
var _spawn_queue: Array = []
var _current_wave: int = 0
var _spawn_timer: float = 0.0
var _is_spawning: bool = false
var _spawn_enabled: bool = false

# 难度修正（由 SegmentGenerator 在路段切换时更新）
var _current_speed_modifier: float = 1.0
var _current_health_modifier: float = 1.0
var _current_damage_modifier: float = 1.0
var _current_segment_id: int = 0

# Day 4新增：敌人生成节奏控制
var _base_spawn_interval: float = 8.0
var _min_spawn_interval: float = 2.0
var _current_spawn_interval: float = 8.0
var _spawn_patterns: Dictionary = {}
var _current_pattern_key: String = "segment_1"

# Day 4新增：敌人解锁状态
var _unlocked_enemy_types: Array = ["drone_basic"]
var _all_available_types: Array = []
var _level_config: Dictionary = {}

# ===== 接口定义 =====
## spawn_enemy(enemy_type: String, position: Vector2 = Vector2.ZERO) -> Node
##   生成敌人
##
## spawn_wave(enemy_types: Array, count: int) -> void
##   生成一波敌人
##
## clear_all_enemies() -> void
##   清除所有敌人
##
## get_active_enemy_count() -> int
##   获取当前存活敌人数量
##
## get_unlocked_enemy_types() -> Array
##   获取当前已解锁的敌人类型列表
##
## set_difficulty_curve(progress: float) -> void
##   设置难度曲线进度（0.0 - 1.0），影响敌人生成密度和类型解锁
## ===== 接口结束 =====

func _ready() -> void:
	_initialize_spawn_patterns()
	_connect_signals()
	print("[SpawnSystem] Initialized - Day 4 enhanced")

func _initialize_spawn_patterns() -> void:
	_spawn_patterns = {
		"segment_1": {
			"base_interval": 8.0,
			"min_interval": 5.0,
			"max_concurrent": 12,
			"unlock_thresholds": [0.0],  # 0%解锁
			"available_types": ["drone_basic"]
		},
		"segment_2": {
			"base_interval": 6.0,
			"min_interval": 4.0,
			"max_concurrent": 18,
			"unlock_thresholds": [0.0, 0.3],  # 30%解锁l2
			"available_types": ["drone_basic", "drone_laser"]
		},
		"segment_3": {
			"base_interval": 4.5,
			"min_interval": 3.0,
			"max_concurrent": 24,
			"unlock_thresholds": [0.0, 0.2, 0.5],  # 20%解锁l2, 50%解锁l3
			"available_types": ["drone_basic", "drone_laser", "drone_healer"]
		},
		"segment_boss": {
			"base_interval": 3.0,
			"min_interval": 2.0,
			"max_concurrent": 30,
			"unlock_thresholds": [0.0, 0.15, 0.3, 0.6],  # 全部解锁
			"available_types": ["drone_basic", "drone_laser", "drone_healer", "enemy_bike"]
		}
	}

func _connect_signals() -> void:
	EventBus.segment_content_ready.connect(_on_segment_content_ready)
	EventBus.spawn_boss_requested.connect(_on_boss_requested)
	EventBus.all_enemies_cleared.connect(_on_all_enemies_cleared)
	EventBus.segment_changed.connect(_on_segment_changed)
	EventBus.level_start_requested.connect(_on_level_start)

func _check_pools_ready() -> Dictionary:
	var pools_to_check = ["Enemy_drone_basic", "Enemy_drone_laser", "Enemy_drone_healer", "Enemy_enemy_bike"]
	var status = {}
	for pool_name in pools_to_check:
		if ObjectPool and "_pools" in ObjectPool:
			status[pool_name] = ObjectPool._pools.has(pool_name)
		else:
			status[pool_name] = false
	return status

func _on_level_start(level_id: String) -> void:
	_spawn_enabled = true
	_spawn_timer = 0.0
	_current_wave = 0
	_unlocked_enemy_types = ["drone_basic"]
	_all_available_types = []
	
	# 从level_config加载敌人类型列表
	_level_config = ConfigMgr.get_level_config(level_id)
	if not _level_config.is_empty():
		_all_available_types = _level_config.get("enemy_types", ["drone_basic"])
		print("[SpawnSystem] Loaded enemy types from level config: ", _all_available_types)
	
	print("[SpawnSystem] Level start: ", level_id, " | Pool status: ", _check_pools_ready())

func _on_segment_changed(segment_id: int) -> void:
	print("[SpawnSystem] Segment changed to: ", segment_id)
	_current_segment_id = segment_id
	_update_difficulty_modifiers(segment_id)
	_update_spawn_pattern_for_segment(segment_id)
	_update_enemy_unlocks(segment_id)
	_spawn_enabled = true

func _update_spawn_pattern_for_segment(segment_id: int) -> void:
	# 根据路段ID确定对应的生成节奏
	if segment_id < 3:
		_current_pattern_key = "segment_1"
	elif segment_id < 6:
		_current_pattern_key = "segment_2"
	elif segment_id < 9:
		_current_pattern_key = "segment_3"
	else:
		_current_pattern_key = "segment_boss"
	
	var pattern = _spawn_patterns.get(_current_pattern_key, _spawn_patterns["segment_1"])
	_base_spawn_interval = pattern["base_interval"]
	_min_spawn_interval = pattern["min_interval"]
	_current_spawn_interval = _base_spawn_interval
	
	print("[SpawnSystem] Spawn pattern: ", _current_pattern_key, " | interval: ", _current_spawn_interval)

func _update_enemy_unlocks(segment_id: int) -> void:
	# 根据路段进度解锁新敌人类型
	var total_segments = float(_level_config.get("total_segments", 10))
	var progress_ratio = float(segment_id) / max(total_segments, 1.0)
	
	var pattern = _spawn_patterns.get(_current_pattern_key, _spawn_patterns["segment_1"])
	var thresholds = pattern.get("unlock_thresholds", [0.0])
	var available = pattern.get("available_types", ["drone_basic"])
	
	var newly_unlocked: Array = []
	for i in range(thresholds.size()):
		if progress_ratio >= thresholds[i] and i < available.size():
			var enemy_type = available[i]
			if enemy_type not in _unlocked_enemy_types:
				_unlocked_enemy_types.append(enemy_type)
				newly_unlocked.append(enemy_type)
	
	if not newly_unlocked.is_empty():
		print("[SpawnSystem] New enemy types unlocked: ", newly_unlocked)
		for enemy_type in newly_unlocked:
			enemy_type_unlocked.emit(enemy_type)

func _update_difficulty_modifiers(segment_id: int) -> void:
	var total_segments = 10.0
	if not _level_config.is_empty():
		total_segments = float(_level_config.get("total_segments", 10))
	
	var position_ratio = float(segment_id) / max(total_segments - 1.0, 1.0)
	position_ratio = clamp(position_ratio, 0.0, 1.0)
	
	var difficulty_curve = _level_config.get("difficulty_curve", [1.0, 1.5, 2.0, 2.5])
	var curve_count = difficulty_curve.size()
	
	var curve_index = position_ratio * (curve_count - 1)
	var lower_idx = int(curve_index)
	var upper_idx = min(lower_idx + 1, curve_count - 1)
	var curve_ratio = curve_index - lower_idx
	
	var curve_value = lerp(difficulty_curve[lower_idx], difficulty_curve[upper_idx], curve_ratio)
	
	_current_speed_modifier = lerp(curve_value * 0.5, curve_value * 0.75, position_ratio)
	_current_health_modifier = lerp(curve_value * 0.5, curve_value, position_ratio)
	_current_damage_modifier = lerp(curve_value * 0.5, curve_value * 0.9, position_ratio)
	
	# 更新生成间隔
	var interval_reduction = lerp(0.0, _base_spawn_interval - _min_spawn_interval, position_ratio)
	_current_spawn_interval = _base_spawn_interval - interval_reduction
	
	print("[SpawnSystem] Segment ", segment_id, " | speed=", _current_speed_modifier, 
		  " | health=", _current_health_modifier, " | interval=", _current_spawn_interval)

func _process(delta: float) -> void:
	if not _spawn_enabled:
		return

	if not _is_spawning:
		return

	if _spawn_queue.size() > 0 and _spawn_timer <= 0:
		_process_spawn_queue()
	elif _spawn_timer > 0:
		_spawn_timer -= delta

func _process_spawn_queue() -> void:
	if _spawn_queue.is_empty():
		return

	var spawn_data = _spawn_queue.pop_front()
	print("[SpawnSystem] Processing spawn: ", spawn_data["type"])
	spawn_enemy(spawn_data["type"], spawn_data["position"])
	_spawn_timer = spawn_data.get("interval", _current_spawn_interval)

	if _spawn_queue.is_empty():
		_spawn_wave_completed()

func _spawn_wave_completed() -> void:
	_current_wave += 1
	spawn_wave_completed.emit(_current_wave)
	_is_spawning = false
	print("[SpawnSystem] Wave ", _current_wave, " completed")

func spawn_enemy(enemy_type: String, position: Vector2 = Vector2.ZERO) -> Node:
	var scene_path = _get_enemy_scene_path(enemy_type)
	if scene_path == "":
		push_error("[SpawnSystem] Unknown enemy type: " + enemy_type)
		return null

	var pool_name = "Enemy_" + enemy_type
	var enemy = ObjectPool.get_object(pool_name, scene_path)
	if enemy:
		var spawn_pos = position if position != Vector2.ZERO else _get_spawn_position()
		enemy.global_position = spawn_pos
		enemy.set_target(_get_player_target())

		_apply_difficulty_to_enemy(enemy)

		_active_enemies.append(enemy)
		
		var game_world = get_tree().get_first_node_in_group("GameWorld")
		if game_world:
			if enemy.get_parent() != game_world:
				enemy.reparent(game_world)
		else:
			var current_parent = enemy.get_parent()
			if current_parent and (current_parent == ObjectPool or current_parent == get_tree().current_scene):
				enemy.reparent(get_tree().current_scene)
		
		if enemy.has_method("activate"):
			enemy.activate()
		if is_instance_valid(enemy):
			enemy.visible = true
		
		add_to_group("enemy")
		add_to_group("enemies")
		print("[SpawnSystem] Spawned: ", enemy_type, " at ", enemy.global_position)
		return enemy
	else:
		push_error("[SpawnSystem] Failed to get enemy from pool: " + pool_name)
	return null

func spawn_wave(_enemy_types: Array, count: int) -> void:
	_is_spawning = true
	_spawn_queue.clear()
	
	# 使用当前解锁的敌人类型
	var available_types = _get_current_available_types()
	if available_types.is_empty():
		available_types = ["drone_basic"]

	for i in range(count):
		var enemy_type = available_types[randi() % available_types.size()]
		_spawn_queue.append({
			"type": enemy_type,
			"position": _get_spawn_position(),
			"interval": _current_spawn_interval
		})

func _get_current_available_types() -> Array:
	# 返回当前解锁的类型与配置类型的交集
	var result: Array = []
	for enemy_type in _unlocked_enemy_types:
		if enemy_type in _all_available_types:
			result.append(enemy_type)
	return result if not result.is_empty() else ["drone_basic"]

func get_unlocked_enemy_types() -> Array:
	return _unlocked_enemy_types.duplicate()

func _get_enemy_scene_path(enemy_type: String) -> String:
	var paths = {
		"drone_basic": "res://scenes/entities/enemies/DroneBasic.tscn",
		"drone_laser": "res://scenes/entities/enemies/DroneLaser.tscn",
		"drone_healer": "res://scenes/entities/enemies/DroneHealer.tscn",
		"enemy_bike": "res://scenes/entities/enemies/EnemyBike.tscn",
		"boss_drone_commander": "res://scenes/entities/enemies/bosses/Boss01.tscn",
		"boss01": "res://scenes/entities/enemies/bosses/Boss01.tscn",
	}
	return paths.get(enemy_type, "")

func _get_spawn_position() -> Vector2:
	# 垂直追尾视角：敌人从屏幕上方道路区域生成
	var road_top = RoadVisualizer.ROAD_TOP if has_node("/root/RoadVisualizer") else 450.0
	var road_bottom = RoadVisualizer.ROAD_BOTTOM if has_node("/root/RoadVisualizer") else 900.0
	
	var viewport = get_viewport()
	if viewport:
		var visible_rect = viewport.get_visible_rect()
		# 敌人从屏幕上方外侧生成（屏幕顶部之外）
		var spawn_x = randf_range(visible_rect.size.x * 0.2, visible_rect.size.x * 0.8)
		var spawn_y = road_top - 50  # 从道路上边界上方生成
		return Vector2(spawn_x, spawn_y)
	
	# 默认生成位置（屏幕上方外侧）
	return Vector2(960, 400)

func _apply_difficulty_to_enemy(enemy: Node) -> void:
	if "move_speed" in enemy and enemy.move_speed > 0:
		var base_speed = enemy.get("move_speed")
		enemy.move_speed = base_speed * _current_speed_modifier

	if "max_health" in enemy and enemy.max_health > 0:
		var base_health = enemy.get("max_health")
		enemy.max_health = base_health * _current_health_modifier
		enemy.current_health = enemy.max_health

	if "attack_damage" in enemy and enemy.attack_damage > 0:
		enemy.attack_damage = enemy.get("attack_damage") * _current_damage_modifier

func _get_player_target() -> Node:
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world:
		var player = game_world.get_node_or_null("Player")
		if player:
			return player
		var vehicle = game_world.get_node_or_null("Vehicle")
		if vehicle:
			return vehicle

	var scene = get_tree().current_scene
	if scene and scene.has_node("Player"):
		return scene.get_node("Player")
	if scene and scene.has_node("Vehicle"):
		return scene.get_node("Vehicle")

	return null

func clear_all_enemies() -> void:
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.die(null)
	_active_enemies.clear()
	_spawn_enabled = false
	print("[SpawnSystem] All enemies cleared")
	all_enemies_cleared.emit()

func get_active_enemy_count() -> int:
	_active_enemies = _active_enemies.filter(func(e): return is_instance_valid(e) and not e.is_dead)
	return _active_enemies.size()

func get_active_enemies() -> Array:
	return _active_enemies.filter(func(e): return is_instance_valid(e) and not e.is_dead)

func _on_segment_content_ready(segment_id: int, obstacle_density: String) -> void:
	print("[SpawnSystem] Segment ", segment_id, " ready, density: ", obstacle_density)
	var enemy_count = _get_enemy_count_for_density(obstacle_density)
	var enemy_types = _get_enemy_types_for_segment(segment_id)
	if enemy_count > 0:
		spawn_wave(enemy_types, enemy_count)

func _get_enemy_count_for_density(density: String) -> int:
	match density:
		"sparse": return 2
		"normal": return 5
		"dense": return 8
		"boss_approach": return 5
	return 3

func _get_enemy_types_for_segment(segment_id: int) -> Array:
	var enemy_types = _all_available_types
	
	if enemy_types.is_empty():
		enemy_types = ["drone_basic"]
	
	var total_segments = float(_level_config.get("total_segments", 10))
	var _position_ratio = float(segment_id) / max(total_segments, 1.0)
	
	var available_types = []
	# 根据进度解锁敌人
	if segment_id < 3:
		available_types = enemy_types.slice(0, 1) if enemy_types.size() > 0 else ["drone_basic"]
	elif segment_id < 6:
		available_types = enemy_types.slice(0, min(2, enemy_types.size())) if enemy_types.size() > 0 else ["drone_basic"]
	elif segment_id < 8:
		available_types = enemy_types.slice(0, min(3, enemy_types.size())) if enemy_types.size() > 0 else ["drone_basic", "drone_laser"]
	else:
		available_types = enemy_types.slice(0, min(4, enemy_types.size())) if enemy_types.size() > 0 else ["drone_basic", "drone_laser", "drone_healer"]
	
	return available_types

func _on_boss_requested(boss_type: String) -> void:
	spawn_enemy(boss_type, _get_spawn_position())

func _on_all_enemies_cleared() -> void:
	_is_spawning = false

# Day 4新增：设置难度曲线进度（供外部调用）
func set_difficulty_curve(progress: float) -> void:
	progress = clamp(progress, 0.0, 1.0)
	
	var difficulty_curve = _level_config.get("difficulty_curve", [1.0, 1.5, 2.0])
	var curve_count = difficulty_curve.size()
	
	var curve_index = progress * (curve_count - 1)
	var lower_idx = int(curve_index)
	var upper_idx = min(lower_idx + 1, curve_count - 1)
	var curve_ratio = curve_index - lower_idx
	
	var curve_value = lerp(difficulty_curve[lower_idx], difficulty_curve[upper_idx], curve_ratio)
	
	_current_speed_modifier = lerp(curve_value * 0.5, curve_value * 0.75, progress)
	_current_health_modifier = lerp(curve_value * 0.5, curve_value, progress)
	_current_damage_modifier = lerp(curve_value * 0.5, curve_value * 0.9, progress)
	
	# 更新生成间隔
	var interval_reduction = lerp(0.0, _base_spawn_interval - _min_spawn_interval, progress)
	_current_spawn_interval = _base_spawn_interval - interval_reduction
	
	# 根据进度更新敌人解锁
	_update_enemy_unlocks_by_progress(progress)
	
	print("[SpawnSystem] Difficulty curve set: progress=", progress, " | speed=", _current_speed_modifier)

func _update_enemy_unlocks_by_progress(progress: float) -> void:
	var newly_unlocked: Array = []
	
	if progress >= 0.0 and "drone_basic" not in _unlocked_enemy_types:
		_unlocked_enemy_types.append("drone_basic")
		newly_unlocked.append("drone_basic")
	
	if progress >= 0.2 and "drone_laser" in _all_available_types and "drone_laser" not in _unlocked_enemy_types:
		_unlocked_enemy_types.append("drone_laser")
		newly_unlocked.append("drone_laser")
	
	if progress >= 0.4 and "drone_healer" in _all_available_types and "drone_healer" not in _unlocked_enemy_types:
		_unlocked_enemy_types.append("drone_healer")
		newly_unlocked.append("drone_healer")
	
	if progress >= 0.6 and "enemy_bike" in _all_available_types and "enemy_bike" not in _unlocked_enemy_types:
		_unlocked_enemy_types.append("enemy_bike")
		newly_unlocked.append("enemy_bike")
	
	if not newly_unlocked.is_empty():
		print("[SpawnSystem] Enemy types unlocked by progress: ", newly_unlocked)
		for enemy_type in newly_unlocked:
			enemy_type_unlocked.emit(enemy_type)
