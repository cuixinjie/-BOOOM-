## VehicleSkills — 载具技能系统
##
## 功能说明：
## - 管理载具的所有技能
## - 处理能量消耗和冷却
##
## 对接注意事项：
## - 被 Driver 调用
## - 技能效果通过 EventBus 广播
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name VehicleSkills
extends Node

class Skill:
	var skill_id: String
	var name: String
	var energy_cost: float
	var cooldown: float
	var current_cooldown: float = 0.0
	var is_active: bool = false
	var duration: float = 0.0
	
	func _init(id: String, n: String, cost: float, cd: float):
		skill_id = id
		name = n
		energy_cost = cost
		cooldown = cd
	
	func is_ready() -> bool:
		return current_cooldown <= 0 and not is_active
	
	func start_cooldown() -> void:
		current_cooldown = cooldown
	
	func update(delta: float) -> void:
		if current_cooldown > 0:
			current_cooldown -= delta
		if is_active and duration > 0:
			duration -= delta
			if duration <= 0:
				is_active = false

var _skills: Dictionary = {}
var _vehicle: Node = null
var _driver: Node = null
var _is_emp_active: bool = false

# ===== 接口定义 =====
## register_skill(skill_id: String, name: String, energy_cost: float, cooldown: float) -> void
##   注册技能
##
## use_skill(skill_id: String) -> bool
##   使用技能
##
## get_skill_cooldown(skill_id: String) -> float
##   获取技能冷却时间
##
## on_emp_activated() -> void
##   EMP激活时调用
##
## activate_energy_shield() -> void
##   激活能量护盾
## ===== 接口结束 =====

func _ready() -> void:
	_initialize_skills()
	_connect_signals()

func _initialize_skills() -> void:
	var config = ConfigManager.get_game_config("skills")
	for skill_id in config.keys():
		var skill_data = config[skill_id]
		var skill = Skill.new(
			skill_id,
			skill_data.get("name", ""),
			skill_data.get("energy_cost", 0.0),
			skill_data.get("cooldown", 0.0)
		)
		_skills[skill_id] = skill
	print("[VehicleSkills] Skills initialized: ", _skills.size())

func _connect_signals() -> void:
	EventBus.emp_activated.connect(_on_emp_activated)
	EventBus.emp_deactivated.connect(_on_emp_deactivated)

func _process(delta: float) -> void:
	for skill in _skills.values():
		skill.update(delta)

func use_skill(skill_id: String) -> bool:
	if _is_emp_active:
		return false
	
	var skill = _skills.get(skill_id)
	if not skill:
		push_warning("[VehicleSkills] Unknown skill: " + skill_id)
		return false
	
	if not skill.is_ready():
		return false
	
	if not _driver or not _driver.consume_energy(skill.energy_cost):
		return false
	
	skill.start_cooldown()
	_execute_skill(skill_id)
	return true

func _execute_skill(skill_id: String) -> void:
	match skill_id:
		"energy_shield":
			_activate_shield_skill()
		"nitro_boost":
			_activate_nitro()
		"emp_burst":
			_activate_emp()
		"repair_kit":
			_activate_repair()
		"ramming_attack":
			_activate_ram()
	
	print("[VehicleSkills] Executed skill: ", skill_id)

func _activate_shield_skill() -> void:
	print("[VehicleSkills] Energy shield activated")

func _activate_nitro() -> void:
	if _vehicle:
		_vehicle.sprint(true)
		await get_tree().create_timer(2.0).timeout
		_vehicle.sprint(false)

func _activate_emp() -> void:
	EventBus.emp_activated.emit()
	await get_tree().create_timer(3.0).timeout
	EventBus.emp_deactivated.emit()

func _activate_repair() -> void:
	var heal_amount = ConfigManager.get_game_config("skills").get("repair_kit", {}).get("heal_amount", 20)
	GameManager.repair_vehicle(heal_amount)

func _activate_ram() -> void:
	print("[VehicleSkills] Ramming attack!")

func _on_emp_activated() -> void:
	_is_emp_active = true
	print("[VehicleSkills] EMP activated - skills disabled")

func _on_emp_deactivated() -> void:
	_is_emp_active = false
	print("[VehicleSkills] EMP deactivated - skills enabled")

func set_vehicle(vehicle: Node) -> void:
	_vehicle = vehicle

func set_driver(driver: Node) -> void:
	_driver = driver

func get_skill_cooldown(skill_id: String) -> float:
	var skill = _skills.get(skill_id)
	return skill.current_cooldown if skill else 0.0

func get_skill_ready_percent(skill_id: String) -> float:
	var skill = _skills.get(skill_id)
	if skill and skill.cooldown > 0:
		return 1.0 - (skill.current_cooldown / skill.cooldown)
	return 1.0
