## ObjectPool — 对象池管理器
##
## 功能说明：
## - 高效管理子弹、敌人、道具等对象的创建和销毁
## - 减少频繁的 instance() 和 queue_free() 开销
## - 支持预加载和动态扩容
##
## 对接注意事项：
## - 高频创建销毁的对象必须通过此管理器
## - 禁止在高频逻辑中直接 instance()
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name ObjectPool
extends Node

var _pools: Dictionary = {}
var _pool_size: Dictionary = {}
var _preload_size: int = 10

signal pool_expanded(pool_name: String, new_size: int)

# ===== 接口定义 =====
## create_pool(pool_name: String, scene_path: String, initial_size: int = 10) -> void
##   创建对象池
##
## get_object(pool_name: String) -> Node
##   从池中获取对象（如果池不存在则自动创建）
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
	var scene: PackedScene
	
	if ResourceLoader.exists(scene_path):
		scene = load(scene_path)
		for i in initial_size:
			var instance = scene.instantiate()
			instance.set_process(false)
			instance.set_physics_process(false)
			instance.visible = false
			instance.owner = self
			pool.append(instance)
			add_child(instance)
	
	_pools[pool_name] = {
		"scene_path": scene_path,
		"pool": pool,
		"scene": scene
	}
	_pool_size[pool_name] = initial_size
	print("[ObjectPool] Created pool: ", pool_name, " with ", initial_size, " objects")

func get_object(pool_name: String, scene_path: String = "") -> Node:
	if not _pools.has(pool_name):
		if scene_path == "":
			push_error("[ObjectPool] Pool not found and no scene_path provided: " + pool_name)
			return null
		create_pool(pool_name, scene_path, _preload_size)
	
	var pool_data = _pools[pool_name]
	var pool: Array = pool_data["pool"]
	
	for instance in pool:
		if not instance.visible and not instance.get_parent() == null:
			instance.set_process(true)
			instance.set_physics_process(true)
			instance.visible = true
			instance.reparent(get_tree().current_scene)
			if instance.has_method("on_spawned"):
				instance.on_spawned()
			return instance
	
	var scene = pool_data["scene"]
	if scene:
		var new_instance = scene.instantiate()
		new_instance.owner = self
		add_child(new_instance)
		pool.append(new_instance)
		_pool_size[pool_name] += 1
		new_instance.set_process(true)
		new_instance.set_physics_process(true)
		new_instance.visible = true
		new_instance.reparent(get_tree().current_scene)
		if new_instance.has_method("on_spawned"):
			new_instance.on_spawned()
		pool_expanded.emit(pool_name, _pool_size[pool_name])
		return new_instance
	
	return null

func return_object(pool_name: String, instance: Node) -> void:
	if not _pools.has(pool_name):
		push_warning("[ObjectPool] Unknown pool: " + pool_name)
		instance.queue_free()
		return
	
	if is_instance_valid(instance):
		if instance.has_method("on_despawned"):
			instance.on_despawned()
		instance.set_process(false)
		instance.set_physics_process(false)
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
