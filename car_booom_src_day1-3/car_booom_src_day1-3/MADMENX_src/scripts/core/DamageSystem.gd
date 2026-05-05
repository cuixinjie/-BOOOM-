## DamageSystem — 伤害计算系统
##
## 功能说明：
## - 统一的伤害计算逻辑
## - 支持暴击、伤害减免、元素伤害
## - 与护甲、护盾系统集成
##
## 对接注意事项：
## - 所有伤害计算必须通过此系统
## - 通过 EventBus.bullet_hit 和 player_damaged 广播伤害事件
##
## 创建人：长安旧梦（主）、cjs（扩展）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

extends Node

class DamageInfo:
	var source: Node
	var base_damage: float
	var damage_type: String = "physical"
	var is_critical: bool = false
	var critical_multiplier: float = 1.5
	var modifiers: Array = []
	var armor_penetration: float = 0.0

	func _init(src: Node = null, dmg: float = 0.0, type: String = "physical"):
		source = src
		base_damage = dmg
		damage_type = type

var _critical_multiplier: float = 1.5
var _base_armor_reduction: float = 0.0

# ===== 接口定义 =====
## calculate_damage(base: float, modifiers: Array = []) -> float
##   计算最终伤害值
##
## apply_damage(target: Node, damage_info: DamageInfo) -> float
##   对目标应用伤害，返回实际受到的伤害
##
## is_invulnerable(target: Node) -> bool
##   检查目标是否无敌
##
## calculate_elemental_damage(source: Node, target: Node, element: String) -> float
##   计算元素伤害
##
## register_damage_modifier(modifier_id: String, modifier_func: Callable) -> void
##   注册自定义伤害修正函数
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	print("[DamageSystem] Initialized")

func _connect_signals() -> void:
	EventBus.world_state_changed.connect(_on_world_state_changed)

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	print("[DamageSystem] World state changed, shield states inverted")

func calculate_damage(base: float, modifiers: Array = []) -> float:
	var final_damage = base

	for modifier in modifiers:
		if modifier is Callable:
			final_damage = modifier.call(final_damage)
		elif modifier is Dictionary:
			if modifier.has("multiplier"):
				final_damage *= modifier["multiplier"]
			if modifier.has("flat"):
				final_damage += modifier["flat"]

	return max(0, final_damage)

func apply_damage(target: Node, damage_info: DamageInfo) -> float:
	if not is_instance_valid(target):
		return 0.0

	if is_invulnerable(target):
		return 0.0

	var final_damage = _calculate_final_damage(damage_info)

	if target.has_method("take_damage"):
		target.take_damage(final_damage, damage_info.source if damage_info.source else self)

	EventBus.bullet_hit.emit(target, damage_info.source if damage_info.source else self, final_damage)

	return final_damage

func _calculate_final_damage(damage_info: DamageInfo) -> float:
	var damage = damage_info.base_damage

	if damage_info.is_critical:
		damage *= damage_info.critical_multiplier

	var armor = _get_target_armor(damage_info.source)
	var armor_reduction = min(armor * (1.0 - damage_info.armor_penetration), damage * 0.8)
	damage -= armor_reduction

	return max(0, damage)

func _get_target_armor(target: Node) -> float:
	if target and target.has_method("get_armor"):
		return target.get_armor()
	return _base_armor_reduction

func is_invulnerable(target: Node) -> bool:
	if not is_instance_valid(target):
		return true

	if target.has_method("is_in_invulnerable_state"):
		return target.is_in_invulnerable_state()

	if target.has_method("is_invulnerable"):
		return target.is_invulnerable()

	return false

func calculate_elemental_damage(source: Node, target: Node, element: String) -> float:
	var element_multipliers = {
		"fire": 1.2,
		"ice": 0.9,
		"lightning": 1.1,
		"poison": 0.8
	}

	var base_damage = 10.0
	var multiplier = element_multipliers.get(element, 1.0)

	if target and target.has_method("get_elemental_resistance"):
		multiplier *= (1.0 - target.get_elemental_resistance(element))

	return calculate_damage(base_damage * multiplier)

func calculate_critical_chance(base_chance: float, luck_modifier: float = 0.0) -> bool:
	var final_chance = min(base_chance + luck_modifier, 0.95)
	return randf() < final_chance

func register_damage_modifier(modifier_id: String, modifier_func: Callable) -> void:
	pass

func calculate_dot_damage(base_dps: float, duration: float, tick_rate: float) -> Array:
	var ticks = int(duration / tick_rate)
	var damage_per_tick = base_dps * tick_rate
	var result: Array = []

	for i in ticks:
		result.append(damage_per_tick)

	return result


## 爆炸溅射（主目标可排除，避免与直击叠加双重满额）
func apply_explosion_aoe(center: Vector2, radius: float, damage_amount: float, source: Node, exclude: Node = null, dmg_type: String = "explosion") -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var amount: float = maxf(0.0, damage_amount)
	if amount <= 0.0:
		return
	for node in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		if exclude != null and node == exclude:
			continue
		if not node.has_method("take_damage"):
			continue
		if "global_position" in node and node.global_position.distance_to(center) > radius:
			continue
		apply_damage(node, DamageInfo.new(source, amount, dmg_type))
