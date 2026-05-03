## SpawnSystem — 敌人生成系统
##
## 功能说明：
## - 根据路段配置生成敌人
## - 管理敌人生成的节奏和类型
##
## 对接注意事项：
## - 敌人类型通过 ConfigManager 获取
## - 敌人生成后自动设置目标
##
## 创建人：新街（主）、长安旧梦（AI初始化）
## 创建日期：2026-04-29
## 合并日期：2026-05-02

extends Node

signal spawn_wave_completed(wave: int)
signal all_enemies_cleared()

var _active_enemies: Array = []
var _spawn_queue: Array = []
var _current_wave: int = 0
var _spawn_timer: float = 0.0
var _is_spawning: bool = false
var _spawn_enabled: bool = false

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
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	print("[SpawnSystem] Initialized")

func _connect_signals() -> void:
	EventBus.segment_content_ready.connect(_on_segment_content_ready)
	EventBus.spawn_boss_requested.connect(_on_boss_requested)
	EventBus.all_enemies_cleared.connect(_on_all_enemies_cleared)
	EventBus.segment_changed.connect(_on_segment_changed)
	EventBus.level_start_requested.connect(_on_level_start)

func _check_pools_ready() -> Dictionary:
	# 检查关键对象池是否已创建
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
	_spawn_timer = 0.0  # 立即开始生成
	print("[SpawnSystem] Spawning enabled for level: ", level_id, " | Pool status: ", _check_pools_ready())

func _on_segment_changed(segment_id: int) -> void:
	print("[SpawnSystem] Segment changed to: ", segment_id)
	# 路段变化后重新启用敌人生成
	_spawn_enabled = true

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
	_spawn_timer = spawn_data.get("interval", 1.0)

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
		# 设置位置
		var spawn_pos = position if position != Vector2.ZERO else _get_spawn_position()
		enemy.global_position = spawn_pos
		enemy.set_target(_get_player_target())
		_active_enemies.append(enemy)
		
		# 确保敌人被添加到GameWorld而不是SpawnSystem自身
		var game_world = get_tree().get_first_node_in_group("GameWorld")
		if game_world:
			if enemy.get_parent() != game_world:
				enemy.reparent(game_world)
				print("[SpawnSystem] Reparented enemy to GameWorld")
		else:
			push_warning("[SpawnSystem] GameWorld not found in group, checking parent...")
			print("[SpawnSystem] Enemy current parent: ", enemy.get_parent().name if enemy.get_parent() else "null")
			# 尝试使用备用父节点
			var current_parent = enemy.get_parent()
			if current_parent and (current_parent == ObjectPool or current_parent == get_tree().current_scene):
				enemy.reparent(get_tree().current_scene)
		
		# 确保敌人可见且激活
		if enemy.has_method("activate"):
			enemy.activate()
		enemy.visible = true
		
		add_to_group("enemy")
		add_to_group("enemies")
		print("[SpawnSystem] Spawned: ", enemy_type, " at ", enemy.global_position, " parent: ", enemy.get_parent().name if enemy.get_parent() else "null", " visible: ", enemy.visible)
		return enemy
	else:
		push_error("[SpawnSystem] Failed to get enemy from pool: " + pool_name)
	return null

func spawn_wave(enemy_types: Array, count: int) -> void:
	_is_spawning = true
	_spawn_queue.clear()

	for i in range(count):
		var enemy_type = enemy_types[randi() % enemy_types.size()]
		_spawn_queue.append({
			"type": enemy_type,
			"position": _get_spawn_position(),
			"interval": 0.5
		})

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
	# 优先使用已知的道路范围
	var road_top = 300.0
	var road_bottom = 780.0
	var road_center_y = (road_top + road_bottom) / 2.0
	
	# 尝试获取实际视口大小
	var viewport = get_viewport()
	if viewport:
		var visible_rect = viewport.get_visible_rect()
		var spawn_x = visible_rect.size.x + 50
		var spawn_y = randf_range(road_top + 50, road_bottom - 50)
		return Vector2(spawn_x, spawn_y)
	
	# 默认值
	return Vector2(1400, road_center_y)

func _get_player_target() -> Node:
	# 首先查找 GameWorld
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world:
		# 优先返回 Player 节点
		var player = game_world.get_node_or_null("Player")
		if player:
			return player
		# 然后查找 Vehicle
		var vehicle = game_world.get_node_or_null("Vehicle")
		if vehicle:
			return vehicle

	# 兼容旧的查找方式
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
	# 根据难度生成对应波次的敌人
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
	# 根据路段进度逐渐增加敌人类型
	if segment_id < 3:
		return ["drone_basic"]
	elif segment_id < 6:
		return ["drone_basic", "drone_basic"]
	elif segment_id < 10:
		return ["drone_basic", "drone_basic", "drone_laser"]
	else:
		return ["drone_basic", "drone_laser", "drone_healer"]

func _on_boss_requested(boss_type: String) -> void:
	spawn_enemy(boss_type, _get_spawn_position())

func _on_all_enemies_cleared() -> void:
	_is_spawning = false
