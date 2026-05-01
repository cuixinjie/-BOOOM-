## BulletFactory — 子弹工厂
##
## 功能说明：
## - 创建各种类型的子弹
## - 应用弹药类型效果
##
## 对接注意事项：
## - 被 WeaponSystem 调用
## - 子弹通过 ObjectPool 管理
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name BulletFactory
extends Node

# ===== 接口定义 =====
## create_player_bullet(weapon: Node, position: Vector2, direction: Vector2, ammo_type: String = "normal") -> Node
##   创建玩家子弹
##
## create_enemy_bullet(type: String, position: Vector2, direction: Vector2) -> Node
##   创建敌人子弹
##
## apply_ammo_effect(bullet: Node, ammo_type: String) -> void
##   应用弹药类型效果
## ===== 接口结束 =====

func _ready() -> void:
	_initialize_pools()

func _initialize_pools() -> void:
	ObjectPool.create_pool("player_bullet", "res://scenes/entities/bullets/BulletPlayer.tscn", 20)
	ObjectPool.create_pool("enemy_bullet", "res://scenes/entities/bullets/BulletEnemy.tscn", 30)
	ObjectPool.create_pool("explosion", "res://scenes/environment/Explosion.tscn", 10)
	print("[BulletFactory] Pools initialized")

func create_player_bullet(weapon: Node, position: Vector2, direction: Vector2, ammo_type: String = "normal") -> Node:
	var bullet = ObjectPool.get_object("player_bullet")
	if bullet:
		bullet.global_position = position
		bullet.fire(direction, weapon.damage)
		bullet.set_owner(weapon.get_parent())
		bullet.ammo_type = ammo_type
		apply_ammo_effect(bullet, ammo_type)
		AudioManager.play_shoot_sound(weapon.weapon_id)
	return bullet

func create_enemy_bullet(type: String, position: Vector2, direction: Vector2) -> Node:
	var stats = ConfigManager.get_enemy_stats(type)
	var bullet = ObjectPool.get_object("enemy_bullet")
	if bullet:
		bullet.global_position = position
		bullet.fire(direction, stats.get("damage", 10.0))
		bullet.bullet_type = type
	return bullet

func create_spread_bullets(position: Vector2, direction: Vector2, spread_count: int, spread_angle: float, damage: float) -> Array:
	var bullets: Array = []
	var base_angle = direction.angle()
	var angle_step = spread_angle / (spread_count - 1) if spread_count > 1 else 0
	
	for i in spread_count:
		var angle = base_angle - spread_angle / 2 + angle_step * i
		var bullet = ObjectPool.get_object("player_bullet")
		if bullet:
			bullet.global_position = position
			bullet.fire(Vector2.from_angle(angle), damage)
			bullets.append(bullet)
	
	return bullets

func apply_ammo_effect(bullet: Node, ammo_type: String) -> void:
	match ammo_type:
		"piercing":
			bullet.pierce_count = 3
			bullet.modulate = Color.BLUE
		"explosive":
			bullet.pierce_count = 1
			bullet.modulate = Color.ORANGE
		"homing":
			bullet.modulate = Color.MAGENTA
		"freeze":
			bullet.modulate = Color.CYAN
		"poison":
			bullet.modulate = Color.GREEN
		_:
			bullet.modulate = Color.WHITE
