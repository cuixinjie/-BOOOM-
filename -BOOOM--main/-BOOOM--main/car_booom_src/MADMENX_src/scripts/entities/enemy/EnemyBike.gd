## EnemyBike — 对冲摩托车
##
## 功能说明：
## - 高速接近并攻击
## - 对玩家造成较大威胁
##
## 对接注意事项：
## - 场景文件：scenes/entities/enemies/EnemyBike.tscn
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name EnemyBike
extends EnemyBase

@export var approach_time: float = 4.0
@export var bullet_count: int = 3

var _approach_timer: float = 0.0
var _is_approaching: bool = true
var _approach_speed: float = 150.0

func _ready() -> void:
	super._ready()
	enemy_type = "enemy_bike"
	move_speed = 100.0
	print("[EnemyBike] Initialized")

func _update_ai(delta: float) -> void:
	if _is_approaching:
		_approach(delta)
	else:
		_attack_behavior(delta)

func _approach(delta: float) -> void:
	_approach_timer += delta
	
	if _target:
		var direction = (_target.global_position - global_position).normalized()
		_velocity = direction * _approach_speed
	
	if _approach_timer >= approach_time:
		_is_approaching = false
		_execute_attack()

func _attack_behavior(delta: float) -> void:
	_velocity = Vector2.ZERO
	_attack_timer -= delta
	if _attack_timer <= 0:
		_execute_attack()
		_attack_timer = attack_interval

func _execute_attack() -> void:
	for i in bullet_count:
		var spread_angle = (i - bullet_count / 2.0) * 0.3
		var bullet = ObjectPool.get_object("enemy_bullet", "res://scenes/entities/bullets/BulletEnemy.tscn")
		if bullet and _target:
			bullet.global_position = global_position
			var direction = (_target.global_position - global_position).normalized().rotated(spread_angle)
			bullet.fire(direction, damage * 0.5)
	print("[EnemyBike] Executed attack!")
