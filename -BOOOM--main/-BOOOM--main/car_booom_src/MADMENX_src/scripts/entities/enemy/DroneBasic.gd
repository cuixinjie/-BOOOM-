## DroneBasic — 弹幕无人机
##
## 功能说明：
## - 最基础的敌人
## - 定期发射弹幕攻击
##
## 对接注意事项：
## - 场景文件：scenes/entities/enemies/DroneBasic.tscn
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name DroneBasic
extends EnemyBase

@export var bullet_scene: PackedScene

var _attack_cooldown: float = 0.0

func _ready() -> void:
	super._ready()
	enemy_type = "drone_basic"
	print("[DroneBasic] Initialized")

func _update_ai(delta: float) -> void:
	super._update_ai(delta)
	
	_attack_cooldown -= delta
	if _attack_cooldown <= 0:
		_attack()
		_attack_cooldown = attack_interval

func _attack() -> void:
	if _target and is_instance_valid(_target):
		var bullet = ObjectPool.get_object("enemy_bullet", "res://scenes/entities/bullets/BulletEnemy.tscn")
		if bullet:
			bullet.global_position = global_position
			var direction = (_target.global_position - global_position).normalized()
			bullet.fire(direction, damage)
			print("[DroneBasic] Fired bullet at target")
