## AmmoSystem — 弹药类型系统
##
## 功能说明：
## - 管理弹药类型切换
## - 应用弹药类型效果到子弹
## - 弹药类型在躲藏点切换（消耗金币）
##
## 弹药类型：
## - NORMAL: 普通弹
## - ARMOR_PIERCING: 穿甲弹（穿透1/2个目标）
## - EXPLOSIVE: 爆炸弹（范围伤害）
## - POISON: 毒弹（持续伤害）
## - ELECTROMAGNETIC: 电磁弹（目标瘫痪）
## - FRAGMENT: 子母弹（分裂）
## - SNIPER: 狙击弹（伤害+显示弹道）
##
## 对接注意事项：
## - 弹药切换消耗金币（10-20金）
## - 弹药类型效果通过 BulletFactory 应用到子弹
## - EventBus.ammo_type_changed 信号通知 UI
## - 躲藏点中切换弹药（由 RestPointManager 调用）
##
## 创建人：池言いく
## 创建日期：2026-05-06
## Day 6 任务：弹药类型系统实现

extends Node

## 当前弹药类型
var _current_ammo_type: int = 0  # 0 = AmmoTypeEnum.Type.NORMAL

## 弹药类型切换成本
const AMMO_SWITCH_COST: int = 15

## 弹药类型效果配置
var _ammo_effects: Dictionary = {
	0: {  # NORMAL
		"piercing": 0,
		"explosive_radius": 0.0,
		"poison_dps": 0.0,
		"poison_duration": 0.0,
		"electromagnetic_stun": 0.0,
		"fragment_count": 0,
		"damage_multiplier": 1.0
	},
	1: {  # ARMOR_PIERCING
		"piercing": 2,
		"explosive_radius": 0.0,
		"poison_dps": 0.0,
		"poison_duration": 0.0,
		"electromagnetic_stun": 0.0,
		"fragment_count": 0,
		"damage_multiplier": 0.8
	},
	2: {  # EXPLOSIVE
		"piercing": 0,
		"explosive_radius": 80.0,
		"poison_dps": 0.0,
		"poison_duration": 0.0,
		"electromagnetic_stun": 0.0,
		"fragment_count": 0,
		"damage_multiplier": 0.7
	},
	3: {  # POISON
		"piercing": 0,
		"explosive_radius": 0.0,
		"poison_dps": 5.0,
		"poison_duration": 3.0,
		"electromagnetic_stun": 0.0,
		"fragment_count": 0,
		"damage_multiplier": 0.6
	},
	4: {  # ELECTROMAGNETIC
		"piercing": 0,
		"explosive_radius": 0.0,
		"poison_dps": 0.0,
		"poison_duration": 0.0,
		"electromagnetic_stun": 1.5,
		"fragment_count": 0,
		"damage_multiplier": 0.5
	},
	5: {  # FRAGMENT
		"piercing": 0,
		"explosive_radius": 0.0,
		"poison_dps": 0.0,
		"poison_duration": 0.0,
		"electromagnetic_stun": 0.0,
		"fragment_count": 3,
		"damage_multiplier": 0.4
	},
	6: {  # SNIPER
		"piercing": 1,
		"explosive_radius": 0.0,
		"poison_dps": 0.0,
		"poison_duration": 0.0,
		"electromagnetic_stun": 0.0,
		"fragment_count": 0,
		"damage_multiplier": 1.5
	}
}

## 弹药无限（只有弹匣容量限制）
## 弹药效果通过 BulletFactory 应用

# ===== 接口定义 =====
## get_current_ammo_type() -> int
##   获取当前弹药类型
##
## switch_ammo_type(new_type: int) -> bool
##   切换弹药类型，消耗金币，返回是否成功
##
## get_ammo_type_name(type: int) -> String
##   获取弹药类型名称
##
## get_ammo_effects(type: int) -> Dictionary
##   获取弹药类型效果参数
##
## apply_ammo_effects_to_bullet(bullet: BulletBase, base_damage: float) -> void
##   应用当前弹药效果到子弹
##
## can_switch_to(type: int) -> bool
##   检查是否可以切换到指定弹药类型（需要足够金币）
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	print("[AmmoSystem] Initialized with ammo type: ", get_ammo_type_name(_current_ammo_type))

func _connect_signals() -> void:
	# 监听子弹发射信号，应用弹药效果
	if EventBus.has_signal("bullet_fired_with_ammo"):
		EventBus.bullet_fired_with_ammo.connect(_on_bullet_fired_with_ammo)

## 子弹发射时应用弹药效果回调（Day 5长安旧梦）
func _on_bullet_fired_with_ammo(bullet: Node, base_damage: float) -> void:
	if not is_instance_valid(bullet):
		return
	apply_ammo_effects_to_bullet(bullet, base_damage)
	print("[AmmoSystem] Applied ammo effects to bullet: type=", get_ammo_type_name(_current_ammo_type))

## 获取弹药类型名称
func get_ammo_type_name(type: int) -> String:
	if type == 0: return "普通弹"
	elif type == 1: return "穿甲弹"
	elif type == 2: return "爆炸弹"
	elif type == 3: return "毒弹"
	elif type == 4: return "电磁弹"
	elif type == 5: return "子母弹"
	elif type == 6: return "狙击弹"
	return "普通弹"

## 获取弹药切换成本
func _get_ammo_cost(type: int) -> int:
	if type == 0: return 0
	elif type == 1: return 15
	elif type == 2: return 20
	elif type == 3: return 15
	elif type == 4: return 20
	elif type == 5: return 18
	elif type == 6: return 15
	return 0

## 获取当前弹药类型
func get_current_ammo_type() -> int:
	return _current_ammo_type

## 切换弹药类型
func switch_ammo_type(new_type: int) -> bool:
	if new_type < 0 or new_type > 6:
		push_warning("[AmmoSystem] Invalid ammo type: ", new_type)
		return false

	if new_type == _current_ammo_type:
		return true

	var cost = _get_ammo_cost(new_type)
	if not EconomySystem or not EconomySystem.has_method("spend_coins"):
		push_warning("[AmmoSystem] EconomySystem not available")
		return false
	if not EconomySystem.spend_coins(cost):
		print("[AmmoSystem] Cannot switch - not enough coins: need ", cost)
		return false

	var old_type = _current_ammo_type
	_current_ammo_type = new_type
	print("[AmmoSystem] Switched ammo type: ", get_ammo_type_name(old_type), " -> ", get_ammo_type_name(new_type))

	# 广播切换信号
	EventBus.ammo_type_changed.emit(get_ammo_type_name(new_type))
	return true

## 获取弹药类型效果参数
func get_ammo_effects(type: int) -> Dictionary:
	return _ammo_effects.get(type, _ammo_effects[0])

## 获取当前弹药效果参数
func get_current_ammo_effects() -> Dictionary:
	return get_ammo_effects(_current_ammo_type)

## 应用弹药效果到子弹
func apply_ammo_effects_to_bullet(bullet: Node, _base_damage: float) -> void:
	if not bullet or not bullet.has_method("set_damage_multiplier"):
		return

	var effects = get_current_ammo_effects()

	# 应用伤害倍率
	bullet.set_damage_multiplier(effects["damage_multiplier"])

	# 应用穿透加成
	if effects["piercing"] > 0 and bullet.has_method("add_piercing"):
		bullet.add_piercing(effects["piercing"])

	# 应用爆炸效果
	if effects["explosive_radius"] > 0.0 and bullet.has_method("set_explosive"):
		bullet.set_explosive(effects["explosive_radius"])

	# 应用毒弹效果
	if effects["poison_dps"] > 0.0 and bullet.has_method("set_poison"):
		bullet.set_poison(effects["poison_dps"], effects["poison_duration"])

	# 应用电磁弹效果
	if effects["electromagnetic_stun"] > 0.0 and bullet.has_method("set_electromagnetic"):
		bullet.set_electromagnetic(effects["electromagnetic_stun"])

	# 应用子母弹效果
	if effects["fragment_count"] > 0 and bullet.has_method("set_fragment"):
		bullet.set_fragment(effects["fragment_count"])

## 检查是否可以切换到指定弹药类型
func can_switch_to(type: int) -> bool:
	var cost = _get_ammo_cost(type)
	if EconomySystem and EconomySystem.has_method("get_coins"):
		return EconomySystem.get_coins() >= cost
	return cost == 0  # 只有免费弹药类型可以在没有EconomySystem时切换

## 获取弹药切换成本
func get_switch_cost(type: int) -> int:
	return _get_ammo_cost(type)

## 获取弹药类型列表（用于 UI 显示）
func get_all_ammo_types() -> Array:
	var types = []
	for i in range(7):
		types.append({
			"type": i,
			"name": get_ammo_type_name(i),
			"cost": _get_ammo_cost(i),
			"effects": get_ammo_effects(i),
			"is_current": i == _current_ammo_type
		})
	return types

## 重置弹药类型为普通弹
func reset() -> void:
	_current_ammo_type = 0
	EventBus.ammo_type_changed.emit(get_ammo_type_name(_current_ammo_type))
	print("[AmmoSystem] Reset to normal ammo")
