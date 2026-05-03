## Damager — 可造成伤害实体基类
##
## 功能说明：
## - 能够造成伤害的实体基类
## - 定义伤害属性和伤害方法
##
## 对接注意事项：
## - 伤害计算最终通过 DamageSystem.apply_damage
## - 暴击判定在 deal_damage 中完成
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name Damager
extends Entity

signal damage_dealt(target: Node, amount: float)

var damage: float = 10.0
var damage_type: String = "physical"
var critical_chance: float = 0.05
var critical_multiplier: float = 1.5
var armor_penetration: float = 0.0
var knockback_force: float = 0.0

# ===== 接口定义 =====
## deal_damage(target: Node) -> float
##   对目标造成伤害，返回实际伤害值
##
## get_damage_info() -> Dictionary
##   获取伤害信息
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()

func deal_damage(target: Node) -> float:
	if not is_instance_valid(target):
		return 0.0

	var is_crit = randf() < critical_chance
	var final_damage = damage

	if is_crit:
		final_damage *= critical_multiplier

	var damage_info = DamageSystem.DamageInfo.new(self, final_damage, damage_type)
	damage_info.is_critical = is_crit
	damage_info.critical_multiplier = critical_multiplier
	damage_info.armor_penetration = armor_penetration

	var actual_damage = DamageSystem.apply_damage(target, damage_info)
	damage_dealt.emit(target, actual_damage)

	if knockback_force > 0 and target.has_method("apply_knockback"):
		var direction = (target.global_position - global_position).normalized()
		target.apply_knockback(direction, knockback_force)

	return actual_damage

func get_damage_info() -> Dictionary:
	return {
		"damage": damage,
		"type": damage_type,
		"critical_chance": critical_chance,
		"critical_multiplier": critical_multiplier,
		"armor_penetration": armor_penetration,
		"knockback": knockback_force
	}

func modify_damage(modifier: float) -> void:
	damage *= modifier

func set_damage(new_damage: float) -> void:
	damage = max(0, new_damage)
