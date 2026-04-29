## TimerUtils — 计时器工具类
##
## 功能说明：
## - 提供计时器管理工具
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name TimerUtils

static func create_timer(node: Node, duration: float, callback: Callable, oneshot: bool = true) -> Timer:
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = oneshot
	timer.timeout.connect(callback)
	node.add_child(timer)
	timer.start()
	return timer

static func create_autofree_timer(node: Node, duration: float, callback: Callable) -> Timer:
	var timer = create_timer(node, duration, callback, true)
	timer.timeout.connect(func(): timer.queue_free())
	return timer

static func delay_call(node: Node, duration: float, callback: Callable) -> void:
	await node.create_timer(duration).timeout
	callback.call()

static func create_countdown(node: Node, duration: float, on_tick: Callable, on_complete: Callable) -> void:
	var remaining = duration
	while remaining > 0:
		on_tick.call(remaining)
		await node.get_tree().create_timer(1.0).timeout
		remaining -= 1.0
	on_complete.call()

class CooldownManager:
	var _cooldowns: Dictionary = {}
	
	func start_cooldown(cooldown_id: String, duration: float) -> void:
		_cooldowns[cooldown_id] = duration
	
	func update(delta: float) -> void:
		for id in _cooldowns.keys():
			_cooldowns[id] -= delta
			if _cooldowns[id] <= 0:
				_cooldowns.erase(id)
	
	func is_ready(cooldown_id: String) -> bool:
		return not _cooldowns.has(cooldown_id)
	
	func get_remaining(cooldown_id: String) -> float:
		return _cooldowns.get(cooldown_id, 0.0)
