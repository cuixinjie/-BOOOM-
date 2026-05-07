## WeaponProficiencySystem — 武器熟练度系统
##
## 功能说明：
## - 按武器类型追踪熟练度
## - 击杀敌人/造成伤害时增加熟练度
## - 触发升级时解锁武器强化效果
## - 每种武器最多3级
##
## 对接注意事项：
## - 需要ConfigMgr加载proficiency_config.json
## - 熟练度变动通过EventBus广播
## - 升级效果通过WeaponUpgradeSystem应用到Shooter
##
## 创建人：池言いく
## 创建日期：2026-05-06
## Day 5 任务：熟练度积累 + 升级系统

extends Node

## 信号定义
signal weapon_proficiency_changed(weapon_type: String, proficiency: float, level: int)
signal weapon_proficiency_level_up(weapon_type: String, new_level: int, unlocked_effects: Dictionary)
signal weapon_mastered(weapon_type: String)

## 熟练度数据
var _weapon_proficiency: Dictionary = {}  # {weapon_type: {proficiency: float, level: int}}
var _weapon_config: Dictionary = {}

## 常量
const MAX_PROFICIENCY_LEVEL: int = 3

func _ready() -> void:
	_load_proficiency_config()
	_initialize_all_weapons()
	_connect_signals()
	print("[WeaponProficiencySystem] Initialized")

func _connect_signals() -> void:
	# 监听敌人死亡信号，增加熟练度
	if EventBus.has_signal("enemy_killed"):
		EventBus.enemy_killed.connect(_on_enemy_killed)
	# 监听武器切换信号
	if EventBus.has_signal("weapon_switch_requested"):
		EventBus.weapon_switch_requested.connect(_on_weapon_switch_requested)

## 敌人死亡回调（增加熟练度）
func _on_enemy_killed(_enemy: Node, killer: Node) -> void:
	# 找到击杀者的武器类型
	var weapon_type = _get_killer_weapon_type(killer)
	if weapon_type.is_empty():
		return
	
	# 获取配置中的熟练度加成
	var prof_per_kill = _get_proficiency_per_kill(weapon_type)
	
	# 增加熟练度
	add_proficiency_for_weapon(weapon_type, prof_per_kill)
	print("[WeaponProficiencySystem] Enemy killed! Weapon: ", weapon_type, " +", prof_per_kill, " proficiency")

## 获取击杀者的武器类型
func _get_killer_weapon_type(killer: Node) -> String:
	if killer == null:
		return ""
	
	# 检查killer是否是Shooter或其子节点
	var shooter = _find_shooter_in_node(killer)
	if shooter and shooter.has_method("_get_current_weapon_type"):
		return shooter._get_current_weapon_type()
	
	# 使用 get() 安全获取属性（避免调用不存在的 has() 方法）
	var weapon_id = killer.get("current_weapon_id")
	if weapon_id != null and weapon_id is String and not weapon_id.is_empty():
		return get_weapon_type_from_id(weapon_id)
	
	return ""

## 在节点树中查找Shooter
func _find_shooter_in_node(node: Node) -> Node:
	if node is Shooter:
		return node
	for child in node.get_children():
		var result = _find_shooter_in_node(child)
		if result:
			return result
	return null

## 获取武器类型对应的击杀熟练度
func _get_proficiency_per_kill(weapon_type: String) -> float:
	var config = _weapon_config.get(weapon_type, {})
	return config.get("proficiency_per_kill", 5.0)

## 武器切换回调
func _on_weapon_switch_requested(weapon_id: String) -> void:
	# 通知UI更新
	var weapon_type = get_weapon_type_from_id(weapon_id)
	EventBus.weapon_proficiency_changed.emit(
		weapon_type,
		get_proficiency(weapon_type),
		get_proficiency_level(weapon_type)
	)

## 加载熟练度配置
func _load_proficiency_config() -> void:
	# 优先尝试直接加载 JSON 文件
	_weapon_config = _load_json_direct("res://assets/configs/proficiency_config.json")
	if not _weapon_config.is_empty():
		print("[WeaponProficiencySystem] Loaded config from file")
		return

	# 尝试通过 ConfigManager 获取
	if ConfigMgr and ConfigMgr.has_method("get_config"):
		_weapon_config = ConfigMgr.get_config("proficiency_config")
		if not _weapon_config.is_empty():
			print("[WeaponProficiencySystem] Loaded config from ConfigManager")
			return

	# 使用默认配置
	if _weapon_config.is_empty():
		push_warning("[WeaponProficiencySystem] Using default config")
		_weapon_config = _get_default_config()

## 直接加载JSON文件
func _load_json_direct(path: String) -> Dictionary:
	if ResourceLoader.exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			if parse_result == OK:
				return json.get_data()
			else:
				push_error("[WeaponProficiencySystem] JSON parse error in: " + path)
	else:
		push_warning("[WeaponProficiencySystem] Config file not found: " + path)
	return {}

## 默认配置（配置加载失败时使用）
func _get_default_config() -> Dictionary:
	return {
		"pistol": {
			"proficiency_per_kill": 5.0,
			"levels": [
				{"level": 1, "threshold": 0, "effects": {}},
				{"level": 2, "threshold": 100, "effects": {"damage_bonus": 0.08}},
				{"level": 3, "threshold": 300, "effects": {"damage_bonus": 0.15}}
			]
		},
		"smg": {
			"proficiency_per_kill": 4.0,
			"levels": [
				{"level": 1, "threshold": 0, "effects": {}},
				{"level": 2, "threshold": 120, "effects": {"damage_bonus": 0.06}},
				{"level": 3, "threshold": 350, "effects": {"damage_bonus": 0.12}}
			]
		},
		"shotgun": {
			"proficiency_per_kill": 8.0,
			"levels": [
				{"level": 1, "threshold": 0, "effects": {}},
				{"level": 2, "threshold": 150, "effects": {"damage_bonus": 0.10}},
				{"level": 3, "threshold": 400, "effects": {"damage_bonus": 0.20}}
			]
		},
		"rifle": {
			"proficiency_per_kill": 10.0,
			"levels": [
				{"level": 1, "threshold": 0, "effects": {}},
				{"level": 2, "threshold": 200, "effects": {"damage_bonus": 0.12}},
				{"level": 3, "threshold": 500, "effects": {"damage_bonus": 0.25}}
			]
		},
		"laser": {
			"proficiency_per_kill": 6.0,
			"levels": [
				{"level": 1, "threshold": 0, "effects": {}},
				{"level": 2, "threshold": 180, "effects": {"damage_bonus": 0.10}},
				{"level": 3, "threshold": 450, "effects": {"damage_bonus": 0.18}}
			]
		}
	}

## 初始化所有武器的熟练度数据
func _initialize_all_weapons() -> void:
	for weapon_type in _weapon_config.keys():
		if weapon_type.begins_with("_"):
			continue
		_initialize_weapon(weapon_type)

## 初始化单个武器的熟练度
func _initialize_weapon(weapon_type: String) -> void:
	if not _weapon_proficiency.has(weapon_type):
		_weapon_proficiency[weapon_type] = {
			"proficiency": 0.0,
			"level": 1
		}
	print("[WeaponProficiencySystem] Initialized weapon: ", weapon_type)

## 获取武器类型对应的熟练度数据
func get_proficiency_data(weapon_type: String) -> Dictionary:
	return _weapon_proficiency.get(weapon_type, {"proficiency": 0.0, "level": 1})

## 获取武器熟练度等级
func get_proficiency_level(weapon_type: String) -> int:
	var data = get_proficiency_data(weapon_type)
	return data.get("level", 1)

## 获取当前熟练度
func get_proficiency(weapon_type: String) -> float:
	var data = get_proficiency_data(weapon_type)
	return data.get("proficiency", 0.0)

## 获取熟练度进度（0.0-1.0）
func get_proficiency_progress(weapon_type: String) -> float:
	var level = get_proficiency_level(weapon_type)
	if level >= MAX_PROFICIENCY_LEVEL:
		return 1.0
	
	var config = _weapon_config.get(weapon_type, {})
	var levels = config.get("levels", [])
	
	# 找到当前等级和下一等级的阈值
	var current_threshold = 0
	var next_threshold = 100
	
	for i in range(levels.size()):
		var lvl = levels[i]
		if lvl.get("level") == level:
			current_threshold = lvl.get("threshold", 0)
			if i + 1 < levels.size():
				next_threshold = levels[i + 1].get("threshold", current_threshold + 100)
			break
	
	var current_prof = get_proficiency(weapon_type)
	var range_size = next_threshold - current_threshold
	var progress = (current_prof - current_threshold) / range_size if range_size > 0 else 1.0
	
	return clamp(progress, 0.0, 1.0)

## 获取升级进度（距离下一级还需要多少熟练度）
func get_upgrade_remaining(weapon_type: String) -> float:
	var level = get_proficiency_level(weapon_type)
	if level >= MAX_PROFICIENCY_LEVEL:
		return 0.0
	
	var config = _weapon_config.get(weapon_type, {})
	var levels = config.get("levels", [])
	var current_prof = get_proficiency(weapon_type)
	
	for i in range(levels.size()):
		var lvl = levels[i]
		if lvl.get("level") == level + 1:
			return max(0.0, lvl.get("threshold", 100) - current_prof)
	
	return 100.0 - current_prof

## 增加武器熟练度（击杀敌人时调用）
func add_proficiency_for_weapon(weapon_type: String, amount: float) -> void:
	if weapon_type.is_empty():
		return
	
	_initialize_weapon(weapon_type)
	
	var data = _weapon_proficiency[weapon_type]
	var old_level = data["level"]
	var new_proficiency = data["proficiency"] + amount
	
	# 检查是否升级
	var next_threshold = _get_next_level_threshold(weapon_type, old_level)
	
	while new_proficiency >= next_threshold and old_level < MAX_PROFICIENCY_LEVEL:
		# 触发升级
		new_proficiency -= next_threshold
		data["level"] += 1
		old_level += 1
		
		# 获取升级效果
		var effects = _get_level_effects(weapon_type, old_level)
		
		# 广播升级信号
		weapon_proficiency_level_up.emit(weapon_type, old_level, effects)
		EventBus.weapon_proficiency_level_up.emit(weapon_type, old_level, effects)
		print("[WeaponProficiencySystem] Level up! ", weapon_type, " -> Lv.", old_level)
		
		# 检查是否已满级
		if old_level >= MAX_PROFICIENCY_LEVEL:
			new_proficiency = _get_level_threshold(weapon_type, MAX_PROFICIENCY_LEVEL)
			weapon_mastered.emit(weapon_type)
			EventBus.weapon_mastered.emit(weapon_type)
			print("[WeaponProficiencySystem] Weapon mastered: ", weapon_type)
			break
		
		next_threshold = _get_next_level_threshold(weapon_type, old_level)
	
	data["proficiency"] = new_proficiency
	
	# 广播熟练度变化
	weapon_proficiency_changed.emit(weapon_type, new_proficiency, data["level"])
	EventBus.weapon_proficiency_changed.emit(weapon_type, new_proficiency, data["level"])

## 获取当前武器类型的熟练度配置
func _get_weapon_config_for_level(weapon_type: String, level: int) -> Dictionary:
	var config = _weapon_config.get(weapon_type, {})
	var levels = config.get("levels", [])
	for lvl in levels:
		if lvl.get("level") == level:
			return lvl
	return {}

## 获取指定等级的熟练度阈值
func _get_level_threshold(weapon_type: String, level: int) -> float:
	var lvl = _get_weapon_config_for_level(weapon_type, level)
	return lvl.get("threshold", 0.0)

## 获取下一等级的阈值
func _get_next_level_threshold(weapon_type: String, current_level: int) -> float:
	if current_level >= MAX_PROFICIENCY_LEVEL:
		return INF
	return _get_level_threshold(weapon_type, current_level + 1)

## 获取指定等级的效果
func _get_level_effects(weapon_type: String, level: int) -> Dictionary:
	var lvl = _get_weapon_config_for_level(weapon_type, level)
	return lvl.get("effects", {})

## 获取武器当前等级的效果
func get_current_effects(weapon_type: String) -> Dictionary:
	var level = get_proficiency_level(weapon_type)
	return _get_level_effects(weapon_type, level)

## 获取武器所有已解锁升级效果
func get_unlocked_upgrades(weapon_type: String) -> Array:
	var level = get_proficiency_level(weapon_type)
	var upgrades = []
	
	for lvl in range(2, level + 1):
		var effects = _get_level_effects(weapon_type, lvl)
		if not effects.is_empty():
			upgrades.append({
				"level": lvl,
				"effects": effects
			})
	
	return upgrades

## 获取武器显示名称
func get_weapon_display_name(weapon_type: String) -> String:
	var config = _weapon_config.get(weapon_type, {})
	var type_name = config.get("type_name", weapon_type)
	var level = get_proficiency_level(weapon_type)
	return "%s Lv.%d" % [type_name, level]

## 获取武器类型的中文名
func get_weapon_type_name(weapon_type: String) -> String:
	var config = _weapon_config.get(weapon_type, {})
	return config.get("type_name", weapon_type)

## 根据武器ID获取武器类型
func get_weapon_type_from_id(weapon_id: String) -> String:
	# 从weapon_stats.json获取武器类型
	var weapon_stats = ConfigMgr.get_weapon_stats(weapon_id) if ConfigMgr else {}
	return weapon_stats.get("type", "pistol")

## 获取升级描述
func get_upgrade_description(weapon_type: String, level: int) -> String:
	var config = _weapon_config.get(weapon_type, {})
	var levels = config.get("levels", [])
	
	for lvl in levels:
		if lvl.get("level") == level:
			return lvl.get("description", "")
	
	return ""

## 获取下一级升级描述
func get_next_upgrade_description(weapon_type: String) -> String:
	var current_level = get_proficiency_level(weapon_type)
	if current_level >= MAX_PROFICIENCY_LEVEL:
		return "已满级"
	return get_upgrade_description(weapon_type, current_level + 1)

## 重置所有武器熟练度
func reset_all() -> void:
	_weapon_proficiency.clear()
	_initialize_all_weapons()
	print("[WeaponProficiencySystem] All proficiency reset")

## 获取武器类型列表
func get_all_weapon_types() -> Array:
	var types = []
	for weapon_type in _weapon_config.keys():
		if not weapon_type.begins_with("_"):
			types.append(weapon_type)
	return types

## 获取所有武器熟练度摘要
func get_proficiency_summary() -> Dictionary:
	var summary = {}
	for weapon_type in get_all_weapon_types():
		summary[weapon_type] = {
			"level": get_proficiency_level(weapon_type),
			"proficiency": get_proficiency(weapon_type),
			"progress": get_proficiency_progress(weapon_type),
			"display_name": get_weapon_display_name(weapon_type)
		}
	return summary

## 检查武器是否已精通（3级满）
func is_mastered(weapon_type: String) -> bool:
	return get_proficiency_level(weapon_type) >= MAX_PROFICIENCY_LEVEL
