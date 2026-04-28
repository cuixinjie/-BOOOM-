## Damager — 可造成伤害的实体基类
##
## 功能说明：
## - 具有攻击力、可造成伤害的实体
## - 支持多种伤害类型
##
## 对接注意事项：
## - 被 BulletBase 继承
## - 伤害计算通过 DamageSystem
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name Damager
extends Entity

signal damage_dealt(target: Node, amount: float)

@export var damage: float = 10.0
@export var damage_type: String = "physical"
@export var armor_penetration: float = 0.0
@export var is_critical: bool = false
@export var critical_multiplier: float = 1.5

var _owner: Node = null

# ===== 接口定义 =====
## get_damage() -> float
##   获取伤害值
##
## set_damage(amount: float) -> void
##   设置伤害值
##
## get_damage_type() -> String
##   获取伤害类型
##
## get_owner() -> Node
##   获取所有者
##
## set_owner(owner: Node) -> void
##   设置所有者
##
## create_damage_info() -> DamageSystem.DamageInfo
##   创建伤害信息对象
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	add_to_group("damagers")

func get_damage() -> float:
	return damage

func set_damage(amount: float) -> void:
	damage = amount

func get_damage_type() -> String:
	return damage_type

func get_owner() -> Node:
	return _owner

func set_owner(owner: Node) -> void:
	_owner = owner

func create_damage_info() -> DamageSystem.DamageInfo:
	var info = DamageSystem.DamageInfo.new(_owner if _owner else self, damage, damage_type)
	info.armor_penetration = armor_penetration
	info.is_critical = is_critical
	info.critical_multiplier = critical_multiplier
	return info

func on_hit(target: Node) -> void:
	var damage_info = create_damage_info()
	var actual_damage = DamageSystem.apply_damage(target, damage_info)
	damage_dealt.emit(target, actual_damage)
