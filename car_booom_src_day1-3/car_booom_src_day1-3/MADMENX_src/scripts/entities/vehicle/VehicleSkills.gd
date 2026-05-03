## VehicleSkills — 载具技能系统
##
## 功能说明：
## - 管理载具的特殊技能
## - 技能冷却和激活
##
## 对接注意事项：
## - 技能效果通过 Callable 回调实现
## - 护盾持续时间由 Timer 控制，避免协程问题
##
## 创建人：池言いく
## 创建日期：2026-04-29
## 修复日期：2026-05-02

class_name VehicleSkills
extends Node

signal skill_activated(skill_id: String)
signal skill_ready(skill_id: String)
signal skill_cooldown_changed(skill_id: String, progress: float)

var vehicle: Node = null
var skill_slots: Dictionary = {}

var _cooldown_timers: Dictionary = {}

# ===== 接口定义 =====
## register_skill(skill_id: String, cooldown: float, effect: Callable) -> void
##   注册技能
##
## activate_skill(skill_id: String) -> void
##   激活技能
##
## is_skill_ready(skill_id: String) -> bool
##   检查技能是否就绪
##
## get_skill_cooldown_progress(skill_id: String) -> float
##   获取冷却进度
## ===== 接口结束 =====

func _ready() -> void:
	if vehicle == null:
		vehicle = get_parent()
	_initialize_default_skills()

func _process(delta: float) -> void:
	for skill_id in _cooldown_timers.keys():
		_cooldown_timers[skill_id] -= delta
		if _cooldown_timers[skill_id] <= 0:
			_cooldown_timers.erase(skill_id)
			skill_ready.emit(skill_id)

func _initialize_default_skills() -> void:
	register_skill("nitro", 10.0, _skill_nitro)
	register_skill("shield", 30.0, _skill_shield)
	register_skill("repair", 45.0, _skill_repair)

func register_skill(skill_id: String, cooldown: float, effect: Callable) -> void:
	skill_slots[skill_id] = {
		"cooldown": cooldown,
		"effect": effect,
	}
	print("[VehicleSkills] Registered skill: ", skill_id)

func activate_skill(skill_id: String) -> void:
	if not skill_slots.has(skill_id):
		return

	if _cooldown_timers.has(skill_id):
		return

	var skill = skill_slots[skill_id]
	skill["effect"].call()
	skill_activated.emit(skill_id)

	_cooldown_timers[skill_id] = skill["cooldown"]

var _nitro_active: bool = false
var _nitro_duration: float = 2.0

func _skill_nitro() -> void:
	if vehicle:
		if vehicle.has_method("apply_nitro_boost"):
			vehicle.apply_nitro_boost()
		else:
			var original_max = vehicle.max_speed
			vehicle.max_speed = original_max * 1.5
			vehicle.current_speed = vehicle.max_speed
			await get_tree().create_timer(_nitro_duration).timeout
			vehicle.max_speed = original_max
	_nitro_active = true
	AudioManager.play_sfx("nitro")
	print("[VehicleSkills] Nitro activated!")

func _skill_shield() -> void:
	if vehicle:
		vehicle.shield_active = true
		if vehicle.has_method("set_shield_timer"):
			vehicle.set_shield_timer(5.0)
		else:
			var timer = Timer.new()
			timer.one_shot = true
			timer.wait_time = 5.0
			timer.timeout.connect(_on_shield_expired.bind(vehicle))
			add_child(timer)
			timer.start()
	print("[VehicleSkills] Shield activated!")

func _on_shield_expired(v: Node) -> void:
	if v.has_method("set_shield_active"):
		v.set_shield_active(false)
	v.shield_active = false

func _skill_repair() -> void:
	if vehicle:
		vehicle.repair(vehicle.max_health * 0.5)
	print("[VehicleSkills] Repair activated!")

func is_skill_ready(skill_id: String) -> bool:
	return not _cooldown_timers.has(skill_id)

func get_skill_cooldown_progress(skill_id: String) -> float:
	if not skill_slots.has(skill_id):
		return 0.0
	if not _cooldown_timers.has(skill_id):
		return 1.0
	var cooldown = skill_slots[skill_id]["cooldown"]
	var remaining = _cooldown_timers[skill_id]
	return 1.0 - (remaining / cooldown)
