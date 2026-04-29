## DroneHealer — 治疗无人机
##
## 功能说明：
## - 为其他敌人提供治疗
## - 自身攻击力低
##
## 对接注意事项：
## - 场景文件：scenes/entities/enemies/DroneHealer.tscn
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name DroneHealer
extends EnemyBase

@export var heal_amount: float = 3.0
@export var heal_interval: float = 1.0
@export var heal_range: float = 200.0

var _heal_timer: float = 0.0
var _heal_target: Node = null

func _ready() -> void:
	super._ready()
	enemy_type = "drone_healer"
	damage = 0
	print("[DroneHealer] Initialized")

func _update_ai(delta: float) -> void:
	super._update_ai(delta)
	
	_find_heal_target()
	_heal_timer -= delta
	if _heal_timer <= 0 and _heal_target:
		_heal()
		_heal_timer = heal_interval

func _find_heal_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node = null
	var closest_dist = heal_range
	
	for enemy in enemies:
		if enemy == self or enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest = enemy
			closest_dist = dist
	
	_heal_target = closest

func _heal() -> void:
	if _heal_target and is_instance_valid(_heal_target):
		var target_living = _heal_target as LivingEntity
		if target_living:
			target_living.heal(heal_amount)
			print("[DroneHealer] Healed target for ", heal_amount)
