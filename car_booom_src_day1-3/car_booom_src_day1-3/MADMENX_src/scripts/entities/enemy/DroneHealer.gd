## DroneHealer — 治疗无人机
##
## 功能说明：
## - 不会攻击
## - 追踪其他敌人并治疗它们
##
## 对接注意事项：
## - 治疗目标通过 _find_heal_target 动态查找血量最低的友方
## - 治愈量由 heal_amount 和 heal_cooldown 控制
##
## 创建人：长安旧梦
## 创建日期：2026-04-29

class_name DroneHealer
extends EnemyBase

signal healed_target(target: Node, amount: float)

var heal_amount: float = 10.0
var heal_range: float = 150.0
var heal_cooldown: float = 5.0
var _heal_timer: float = 0.0

var _heal_target: Node = null

func _ready() -> void:
	enemy_type = "drone_healer"
	max_health = 25.0
	current_health = max_health
	move_speed = 50.0
	chase_range = 300.0
	attack_range = 0.0
	attack_cooldown = 999.0
	score_value = 15
	coin_drop_max = 3

	super._ready()

func _process(delta: float) -> void:
	if is_dead:
		return

	if _heal_timer > 0:
		_heal_timer -= delta

	_find_heal_target()
	_update_healer_behavior(delta)

func _find_heal_target() -> void:
	_heal_target = null
	var best_target: Node = null
	var lowest_health_ratio: float = 1.0

	var parent = get_parent()
	if parent and parent.has_method("get_active_enemies"):
		for enemy in parent.get_active_enemies():
			if enemy == self or enemy.is_dead:
				continue
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= heal_range:
				var ratio = enemy.current_health / enemy.max_health
				if ratio < lowest_health_ratio and ratio < 1.0:
					lowest_health_ratio = ratio
					best_target = enemy

	_heal_target = best_target

func _update_healer_behavior(delta: float) -> void:
	if _heal_target:
		var dist = global_position.distance_to(_heal_target.global_position)
		if dist > heal_range * 0.8:
			var dir = (_heal_target.global_position - global_position).normalized()
			global_position += dir * move_speed * delta
		elif _heal_timer <= 0:
			_perform_heal()
	else:
		super._process(delta)

func _perform_heal() -> void:
	if not is_instance_valid(_heal_target):
		return

	_heal_target.heal(heal_amount)
	healed_target.emit(_heal_target, heal_amount)
	_heal_timer = heal_cooldown
	AudioManager.play_sfx("heal")

func perform_attack() -> void:
	pass
