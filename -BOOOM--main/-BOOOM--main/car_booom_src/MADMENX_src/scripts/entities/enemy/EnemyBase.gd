## EnemyBase — 敌人基类
##
## 功能说明：
## - 所有敌人的基类
## - 提供AI、攻击、移动等基础功能
##
## 对接注意事项：
## - 被各种具体敌人继承
## - 死亡通过 EventBus.enemy_killed 广播
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name EnemyBase
extends LivingEntity

@export var enemy_type: String = "basic"
@export var tier: int = 1
@export var score_value: int = 10

@export var move_speed: float = 50.0
@export var damage: float = 10.0
@export var attack_interval: float = 2.0

var _is_shielded: bool = false
var _shield_inverted: bool = false
var _attack_timer: float = 0.0

var _target: Node = null

# ===== 接口定义 =====
## get_damage() -> float
##   获取攻击力
##
## is_shielded() -> bool
##   返回是否处于护盾状态
##
## set_shield_state(shielded: bool) -> void
##   设置护盾状态
##
## invert_shield() -> void
##   反转护盾状态
##
## get_score_value() -> int
##   获取分数值
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	_load_stats()

func _load_stats() -> void:
	var stats = ConfigManager.get_enemy_stats(enemy_type)
	if stats:
		max_health = stats.get("hp", max_health)
		current_health = max_health
		damage = stats.get("damage", damage)
		move_speed = stats.get("move_speed", move_speed)
		tier = stats.get("tier", tier)
		score_value = stats.get("score", score_value)
		_is_shielded = stats.get("shield", false)

func _process(delta: float) -> void:
	super._process(delta)
	_update_ai(delta)

func _update_ai(delta: float) -> void:
	if _target and is_instance_valid(_target):
		var direction = (_target.global_position - global_position).normalized()
		_velocity = direction * move_speed

func _take_damage(amount: float, damage_info) -> void:
	if _is_shielded and not _shield_inverted:
		return
	
	super._take_damage(amount, damage_info)

func die() -> void:
	GameManager.add_score(score_value)
	EventBus.enemy_killed.emit(self, damage_info.source if damage_info and "source" in damage_info else null)
	super.die()

func get_damage() -> float:
	return damage

func is_shielded() -> bool:
	return _is_shielded

func set_shield_state(shielded: bool) -> void:
	_is_shielded = shielded

func invert_shield() -> void:
	_shield_inverted = !_shield_inverted
	if _shield_inverted:
		_is_shielded = !_is_shielded
	print("[EnemyBase] Shield inverted: ", _is_shielded)

func get_score_value() -> int:
	return score_value

func set_target(target: Node) -> void:
	_target = target
