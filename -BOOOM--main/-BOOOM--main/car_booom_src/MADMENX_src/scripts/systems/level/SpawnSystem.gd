## SpawnSystem — 敌人生成系统
##
## 功能说明：
## - 管理敌人生成
## - 支持不同敌人类型和难度曲线
##
## 对接注意事项：
## - 被 LevelManager 调用
## - 敌人通过 ObjectPool 管理
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name SpawnSystem
extends Node

signal enemy_spawned(enemy: Node)
signal spawn_rate_changed(rate: float)

var _spawn_timer: float = 0.0
var _spawn_rate: float = 2.0
var _is_spawning: bool = false
var _active_enemies: Array = []
var _enemy_types: Array = []
var _difficulty_curve: float = 1.0

# ===== 接口定义 =====
## spawn_enemy(type: String, position: Vector2 = Vector2.ZERO) -> Node
##   生成敌人
##
## set_difficulty_curve(progress: float) -> void
##   设置难度曲线
##
## clear_all_enemies() -> void
##   清空所有敌人
##
## start_spawning(enemy_types: Array, rate: float) -> void
##   开始生成
##
## stop_spawning() -> void
##   停止生成
##
## spawn_boss(type: String) -> Node
##   生成 BOSS
## ===== 接口结束 =====

func _ready() -> void:
	print("[SpawnSystem] Initialized")

func _process(delta: float) -> void:
	if not _is_spawning:
		return
	
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_next_enemy()
		_spawn_timer = _spawn_rate

func spawn_enemy(type: String, position: Vector2 = Vector2.ZERO) -> Node:
	var enemy_scene_path = _get_enemy_scene_path(type)
	if enemy_scene_path == "":
		push_warning("[SpawnSystem] Unknown enemy type: " + type)
		return null
	
	var enemy = ObjectPool.get_object("enemy_" + type, enemy_scene_path)
	if enemy:
		if position == Vector2.ZERO:
			position = _get_spawn_position()
		enemy.global_position = position
		enemy.set_target(get_tree().get_first_node_in_group("vehicle"))
		_active_enemies.append(enemy)
		enemy_spawned.emit(enemy)
		print("[SpawnSystem] Enemy spawned: ", type)
	return enemy

func _spawn_next_enemy() -> void:
	if _enemy_types.size() > 0:
		var random_type = _enemy_types[randi() % _enemy_types.size()]
		spawn_enemy(random_type)

func _get_enemy_scene_path(type: String) -> String:
	var stats = ConfigManager.get_enemy_stats(type)
	return stats.get("scene", "")

func _get_spawn_position() -> Vector2:
	var viewport = get_viewport_rect()
	var spawn_edge = randi() % 4
	var margin = 100
	
	match spawn_edge:
		0: # Top
			return Vector2(randf_range(margin, viewport.size.x - margin), -50)
		1: # Right
			return Vector2(viewport.size.x + 50, randf_range(margin, viewport.size.y - margin))
		2: # Bottom
			return Vector2(randf_range(margin, viewport.size.x - margin), viewport.size.y + 50)
		3: # Left
			return Vector2(-50, randf_range(margin, viewport.size.y - margin))
		_:
			return Vector2(randf_range(100, viewport.size.x - 100), -50)

func start_spawning(enemy_types: Array, rate: float) -> void:
	_enemy_types = enemy_types
	_spawn_rate = rate
	_is_spawning = true
	_spawn_timer = 0.0
	print("[SpawnSystem] Spawning started with types: ", enemy_types)

func stop_spawning() -> void:
	_is_spawning = false
	print("[SpawnSystem] Spawning stopped")

func set_difficulty_curve(progress: float) -> void:
	_difficulty_curve = lerp(1.0, 2.0, progress)
	_spawn_rate = max(0.5, 2.0 / _difficulty_curve)
	spawn_rate_changed.emit(_spawn_rate)
	print("[SpawnSystem] Difficulty curve: ", _difficulty_curve)

func clear_all_enemies() -> void:
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			ObjectPool.return_object("enemy_" + enemy.enemy_type, enemy)
	_active_enemies.clear()
	print("[SpawnSystem] All enemies cleared")

func spawn_boss(type: String) -> Node:
	var boss = spawn_enemy(type)
	if boss:
		boss_spawned.emit(boss)
	return boss

func get_active_enemy_count() -> int:
	return _active_enemies.size()

func remove_enemy(enemy: Node) -> void:
	_active_enemies.erase(enemy)
