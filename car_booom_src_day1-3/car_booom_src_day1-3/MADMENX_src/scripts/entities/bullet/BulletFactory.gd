## BulletFactory — 子弹工厂
##
## 功能说明：
## - 子弹创建的统一入口
## - 管理子弹类型和参数
##
## 对接注意事项：
## - 所有子弹创建必须通过此工厂
## - 池名由工厂统一管理（Bullet_{type_name} / BulletEnemy_{type_name}）
##
## 创建人：长安旧梦
## 创建日期：2026-04-29

extends Node

var _bullet_scenes: Dictionary = {}

# ===== 接口定义 =====
## register_bullet_type(type_name: String, scene_path: String) -> void
##   注册子弹类型
##
## create_player_bullet(type_name: String, dir: Vector2, dmg: float, pierce: int = 0) -> BulletBase
##   创建玩家子弹
##
## create_enemy_bullet(type_name: String, dir: Vector2, dmg: float) -> BulletBase
##   创建敌人子弹
## ===== 接口结束 =====

func _ready() -> void:
	_initialize_bullet_types()
	print("[BulletFactory] Initialized")

func _initialize_bullet_types() -> void:
	_bullet_scenes["player_basic"] = "res://scenes/entities/bullets/BulletPlayer.tscn"
	_bullet_scenes["enemy_basic"] = "res://scenes/entities/bullets/BulletEnemy.tscn"
	_bullet_scenes["enemy_homing"] = "res://scenes/entities/bullets/BulletEnemy.tscn"
	_bullet_scenes["enemy_laser"] = "res://scenes/entities/bullets/BulletEnemy.tscn"

func register_bullet_type(type_name: String, scene_path: String) -> void:
	_bullet_scenes[type_name] = scene_path

func create_player_bullet(type_name: String, dir: Vector2, dmg: float, pierce: int = 0, spawn_pos: Vector2 = Vector2.ZERO) -> BulletBase:
	var pool_name = "Bullet_" + type_name
	var scene_path = _bullet_scenes.get(type_name, "res://scenes/entities/bullets/BulletPlayer.tscn")
	var bullet = ObjectPool.get_object(pool_name, scene_path)

	if bullet:
		var spd = _get_bullet_speed(type_name, true)
		bullet.set_pool_name(pool_name)
		bullet.fire(dir, spd, dmg, 0, pierce, spawn_pos)  # owner=0 for PLAYER
		bullet.name = "BulletPlayer_" + type_name

	return bullet as BulletBase

func create_enemy_bullet(type_name: String, dir: Vector2, dmg: float, spawn_pos: Vector2 = Vector2.ZERO) -> BulletBase:
	var pool_name = "BulletEnemy_" + type_name
	var scene_path = _bullet_scenes.get(type_name, "res://scenes/entities/bullets/BulletEnemy.tscn")
	var bullet = ObjectPool.get_object(pool_name, scene_path)

	if bullet:
		var spd = _get_bullet_speed(type_name, false)
		bullet.set_pool_name(pool_name)
		bullet.fire(dir, spd, dmg, 1, 0, spawn_pos)  # owner=1 for ENEMY

	return bullet as BulletBase

func _get_bullet_speed(type_name: String, is_player: bool) -> float:
	var base_speed = 400.0 if is_player else 300.0
	match type_name:
		"player_basic": return 500.0
		"enemy_basic": return 300.0
		"enemy_homing": return 250.0
		"enemy_laser": return 600.0
	return base_speed
