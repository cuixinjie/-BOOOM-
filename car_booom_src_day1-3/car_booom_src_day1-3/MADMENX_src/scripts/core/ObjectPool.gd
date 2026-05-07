## ObjectPool — 对象池管理器
##
## 功能说明：
## - 高效管理子弹、敌人、道具等对象的创建和销毁
## - 减少频繁的 instance() 和 queue_free() 开销
## - 支持预加载和动态扩容
## - 支持指定spawn到特定父节点
##
## 对接注意事项：
## - 高频创建销毁的对象必须通过此管理器
## - 禁止在高频逻辑中直接 instance()
##
## 创建人：cjs（主）、新街（优化）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

extends Node

var _pools: Dictionary = {}
var _pool_size: Dictionary = {}
var _preload_size: int = 10

signal pool_expanded(pool_name: String, new_size: int)

# ===== 接口定义 =====
## create_pool(pool_name: String, scene_path: String, initial_size: int = 10) -> void
##   创建对象池
##
## get_object(pool_name: String, scene_path: String = "", spawn_parent: Node = null) -> Node
##   从池中获取对象（如果池不存在则自动创建）
##   spawn_parent: 可选，指定对象的父节点
##
## get_object_with_parent(pool_name: String, scene_path: String, parent_node: Node) -> Node
##   从池中获取对象并spawn到指定父节点
##
## return_object(pool_name: String, instance: Node) -> void
##   归还对象到池中
##
## clear_pool(pool_name: String) -> void
##   清空指定池
##
## clear_all_pools() -> void
##   清空所有池
##
## get_pool_size(pool_name: String) -> int
##   获取池中可用对象数量
## ===== 接口结束 =====

func _ready() -> void:
	print("[ObjectPool] Initialized")

func create_pool(pool_name: String, scene_path: String, initial_size: int = _preload_size) -> void:
	if _pools.has(pool_name):
		return

	var pool: Array = []
	var scene: PackedScene = null

	if ResourceLoader.exists(scene_path):
		scene = load(scene_path)
		if scene == null:
			push_error("[ObjectPool] Failed to load scene: " + scene_path)
			return
		for i in initial_size:
			var instance = scene.instantiate()
			instance.set_process(false)
			instance.set_physics_process(false)
			instance.visible = false
			add_child(instance)
			instance.owner = self
			pool.append(instance)

	_pools[pool_name] = {
		"scene_path": scene_path,
		"pool": pool,
		"scene": scene
	}
	_pool_size[pool_name] = initial_size
	print("[ObjectPool] Created pool: ", pool_name, " with ", initial_size, " objects")

func get_object(pool_name: String, scene_path: String = "", spawn_parent: Node = null) -> Node:
	if not _pools.has(pool_name):
		if scene_path == "":
			push_error("[ObjectPool] Pool not found and no scene_path provided: " + pool_name)
			return null
		create_pool(pool_name, scene_path, _preload_size)

	var pool_data = _pools[pool_name]
	var pool: Array = pool_data["pool"]

	for instance in pool:
		# 关键修复：先检查有效性，再访问 visible 属性
		if not is_instance_valid(instance):
			continue
		if not instance.visible and instance.get_parent() == self:
			instance.set_process(true)
			instance.set_physics_process(true)
			instance.visible = true
			# 使用传入的spawn_parent或GameWorld
			var target_parent = spawn_parent if spawn_parent else _get_spawn_target()
			instance.reparent(target_parent)
			if instance.has_method("on_spawned"):
				instance.on_spawned()
			return instance

	var scene = pool_data["scene"]
	if scene == null:
		push_error("[ObjectPool] Scene is null for pool: " + pool_name + ", path: " + pool_data["scene_path"])
		return null

	var new_instance = scene.instantiate()
	var target_parent = spawn_parent if spawn_parent else _get_spawn_target()
	add_child(new_instance)
	pool.append(new_instance)
	_pool_size[pool_name] += 1
	new_instance.set_process(true)
	new_instance.set_physics_process(true)
	new_instance.visible = true
	new_instance.reparent(target_parent)
	if new_instance.has_method("on_spawned"):
		new_instance.on_spawned()
	pool_expanded.emit(pool_name, _pool_size[pool_name])
	return new_instance

func get_object_with_parent(pool_name: String, scene_path: String, parent_node: Node) -> Node:
	return get_object(pool_name, scene_path, parent_node)

func _get_spawn_target() -> Node:
	# 优先查找GameWorld组
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world:
		return game_world
	# 回退到当前场景
	return get_tree().current_scene

func return_object(pool_name: String, instance: Node) -> void:
	if not _pools.has(pool_name):
		push_warning("[ObjectPool] Unknown pool: " + pool_name)
		if is_instance_valid(instance):
			instance.queue_free()
		return

	# 关键修复：检查实例有效性后再操作
	if is_instance_valid(instance):
		if instance.has_method("on_despawned"):
			instance.on_despawned()
		instance.set_process(false)
		instance.set_physics_process(false)
		if instance.has_method("visible"):
			instance.visible = false
		instance.reparent(self)

func clear_pool(pool_name: String) -> void:
	if not _pools.has(pool_name):
		return

	var pool_data = _pools[pool_name]
	var pool: Array = pool_data["pool"]

	for instance in pool:
		if is_instance_valid(instance):
			instance.queue_free()

	pool.clear()
	_pool_size[pool_name] = 0
	print("[ObjectPool] Cleared pool: ", pool_name)

func clear_all_pools() -> void:
	for pool_name in _pools.keys():
		clear_pool(pool_name)
	print("[ObjectPool] All pools cleared")

func get_pool_size(pool_name: String) -> int:
	return _pool_size.get(pool_name, 0)

func get_available_count(pool_name: String) -> int:
	if not _pools.has(pool_name):
		return 0

	var count = 0
	for instance in _pools[pool_name]["pool"]:
		if not instance.visible:
			count += 1
	return count

func set_preload_size(size: int) -> void:
	_preload_size = size
