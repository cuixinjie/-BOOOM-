## EnemyBike — 对冲摩托车
##
## 功能说明：
## - 从前方高速冲来的摩托车敌人
## - 直线冲向玩家位置
##
## 对接注意事项：
## - 冲锋伤害通过 GameManager.damage_vehicle 作用于机车
## - 冲锋后进入冷却期
##
## 创建人：长安旧梦
## 创建日期：2026-04-29

class_name EnemyBike
extends EnemyBase

var charge_speed: float = 500.0
var charge_cooldown: float = 4.0
var charge_damage: float = 25.0
var _is_charging: bool = false
var _charge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	enemy_type = "enemy_bike"
	max_health = 50.0
	current_health = max_health
	move_speed = 150.0
	chase_range = 600.0
	attack_range = 50.0
	attack_cooldown = charge_cooldown
	score_value = 25
	coin_drop_max = 8

	super._ready()

func _update_attack() -> void:
	if not _is_charging:
		if _attack_timer <= 0:
			_start_charge()
			return
		_attack_timer -= _cached_delta

	if _is_charging:
		global_position += _charge_direction * charge_speed * _cached_delta
		if _check_player_collision():
			_trigger_charge_damage()

func _start_charge() -> void:
	if not is_instance_valid(target_node):
		return

	_is_charging = true
	_charge_direction = (target_node.global_position - global_position).normalized()
	_charge_direction.x = sign(_charge_direction.x)
	_attack_timer = 1.5
	print("[EnemyBike] Charging!")

func _check_player_collision() -> bool:
	if is_instance_valid(target_node):
		var dist = global_position.distance_to(target_node.global_position)
		return dist <= attack_range
	return false

func _trigger_charge_damage() -> void:
	GameManager.damage_vehicle(charge_damage)
	_is_charging = false
	_attack_timer = charge_cooldown
	AudioManager.play_sfx("bike_charge")
