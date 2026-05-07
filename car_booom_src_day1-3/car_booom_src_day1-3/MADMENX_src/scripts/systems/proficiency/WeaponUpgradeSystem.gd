## WeaponUpgradeSystem — 武器升级效果系统
##
## 功能说明：
## - 管理每种武器的升级效果
## - 将升级效果应用到Shooter
## - 处理霰弹枪弹丸数、狙击枪穿透等特殊效果
##
## 对接注意事项：
## - 需要WeaponProficiencySystem提供升级数据
## - 需要Shooter提供效果应用接口
## - 通过EventBus监听升级事件
##
## 创建人：池言いく
## 创建日期：2026-05-06
## Day 5 任务：熟练度积累 + 升级系统

extends Node

## 升级效果加成存储
var _proficiency_damage_bonus: float = 0.0      # 熟练度伤害加成
var _proficiency_fire_rate_bonus: float = 0.0   # 熟练度射速加成
var _proficiency_accuracy_bonus: float = 0.0    # 熟练度精准加成
var _proficiency_spread_reduction: float = 0.0  # 熟练度散布减少（霰弹枪）
var _proficiency_pellet_bonus: int = 0         # 熟练度弹丸加成（霰弹枪）
var _proficiency_piercing_bonus: int = 0        # 熟练度穿透加成（狙击枪）

## 记录当前武器类型
var _current_weapon_type: String = "pistol"

## Shooter引用
var _shooter: Node = null

func _ready() -> void:
	_connect_signals()
	print("[WeaponUpgradeSystem] Initialized")

## 连接信号
func _connect_signals() -> void:
	if EventBus.has_signal("weapon_proficiency_level_up"):
		EventBus.weapon_proficiency_level_up.connect(_on_weapon_proficiency_level_up)
	if EventBus.has_signal("weapon_switch_requested"):
		EventBus.weapon_switch_requested.connect(_on_weapon_switch_requested)

## 初始化Shooter引用
func initialize(shooter: Node) -> void:
	_shooter = shooter
	print("[WeaponUpgradeSystem] Shooter initialized")

## 武器熟练度升级回调
func _on_weapon_proficiency_level_up(weapon_type: String, new_level: int, effects: Dictionary) -> void:
	print("[WeaponUpgradeSystem] Level up: ", weapon_type, " -> Lv.", new_level)
	_apply_upgrade_effects(weapon_type, effects)

## 武器切换回调
func _on_weapon_switch_requested(weapon_id: String) -> void:
	var weapon_type = _get_weapon_type_from_id(weapon_id)
	update_for_weapon_type(weapon_type)

## 获取武器类型
func _get_weapon_type_from_id(weapon_id: String) -> String:
	var weapon_stats = ConfigMgr.get_weapon_stats(weapon_id) if ConfigMgr else {}
	return weapon_stats.get("type", "pistol")

## 根据武器类型更新效果
func update_for_weapon_type(weapon_type: String) -> void:
	if _current_weapon_type == weapon_type:
		return

	_current_weapon_type = weapon_type

	# 获取该武器的当前效果
	var effects = _get_weapon_current_effects(weapon_type)
	_apply_upgrade_effects(weapon_type, effects)

	# 应用到Shooter
	if _shooter:
		_apply_effects_to_shooter(weapon_type, effects)

	print("[WeaponUpgradeSystem] Updated for weapon type: ", weapon_type)

## 获取武器当前所有效果
func _get_weapon_current_effects(weapon_type: String) -> Dictionary:
	if not has_node("/root/WeaponProficiencySystem"):
		return {}
	
	var effects = {}
	var prof_system = get_node("/root/WeaponProficiencySystem")
	var unlocked_upgrades = prof_system.get_unlocked_upgrades(weapon_type)
	
	for upgrade in unlocked_upgrades:
		var upgrade_effects = upgrade.get("effects", {})
		_merge_effects(effects, upgrade_effects)
	
	return effects

## 合并效果
func _merge_effects(base: Dictionary, addition: Dictionary) -> void:
	for key in addition.keys():
		var value = addition[key]
		if key == "piercing_bonus" or key == "pellet_bonus":
			# 整数加成
			base[key] = base.get(key, 0) + value
		else:
			# 百分比加成
			base[key] = base.get(key, 0.0) + value

## 应用升级效果
func _apply_upgrade_effects(weapon_type: String, effects: Dictionary) -> void:
	# 更新加成变量
	_proficiency_damage_bonus = effects.get("damage_bonus", 0.0)
	_proficiency_fire_rate_bonus = effects.get("fire_rate_bonus", 0.0)
	_proficiency_accuracy_bonus = effects.get("accuracy_bonus", 0.0)
	_proficiency_spread_reduction = effects.get("spread_reduction", 0.0)
	_proficiency_pellet_bonus = effects.get("pellet_bonus", 0)
	_proficiency_piercing_bonus = effects.get("piercing_bonus", 0)
	
	print("[WeaponUpgradeSystem] Applied effects: ", effects)
	
	# 应用到Shooter
	if _shooter:
		_apply_effects_to_shooter(weapon_type, effects)

## 应用效果到Shooter
func _apply_effects_to_shooter(weapon_type: String, _effects: Dictionary) -> void:
	if not _shooter or not _shooter.has_method("apply_proficiency_effect"):
		return
	
	# 计算最终加成值
	var final_damage_bonus = _proficiency_damage_bonus
	var final_fire_rate_bonus = _proficiency_fire_rate_bonus
	var final_accuracy_bonus = _proficiency_accuracy_bonus
	var final_spread_reduction = _proficiency_spread_reduction
	var final_pellet_bonus = _proficiency_pellet_bonus
	var final_piercing_bonus = _proficiency_piercing_bonus
	
	_shooter.apply_proficiency_effect(
		weapon_type,
		final_damage_bonus,
		final_fire_rate_bonus,
		final_accuracy_bonus,
		final_spread_reduction,
		final_pellet_bonus,
		final_piercing_bonus
	)
	
	print("[WeaponUpgradeSystem] Effects applied to Shooter")

## 获取当前熟练度伤害加成
func get_proficiency_damage_bonus() -> float:
	return _proficiency_damage_bonus

## 获取当前熟练度射速加成
func get_proficiency_fire_rate_bonus() -> float:
	return _proficiency_fire_rate_bonus

## 获取当前熟练度精准加成
func get_proficiency_accuracy_bonus() -> float:
	return _proficiency_accuracy_bonus

## 获取霰弹枪散布减少
func get_spread_reduction() -> float:
	return _proficiency_spread_reduction

## 获取霰弹枪弹丸加成
func get_pellet_bonus() -> int:
	return _proficiency_pellet_bonus

## 获取狙击枪穿透加成
func get_piercing_bonus() -> int:
	return _proficiency_piercing_bonus

## 重置所有加成
func reset() -> void:
	_proficiency_damage_bonus = 0.0
	_proficiency_fire_rate_bonus = 0.0
	_proficiency_accuracy_bonus = 0.0
	_proficiency_spread_reduction = 0.0
	_proficiency_pellet_bonus = 0
	_proficiency_piercing_bonus = 0
	print("[WeaponUpgradeSystem] Reset")
