## BulletPlayer — 玩家子弹
##
## 功能说明：
## - 玩家发射的子弹
## - 继承 BulletBase
##
## 对接注意事项：
## - 场景文件：scenes/entities/bullets/BulletPlayer.tscn
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name BulletPlayer
extends BulletBase

@export var ammo_type: String = "normal"

func _ready() -> void:
	super._ready()
	add_to_group("player_bullets")

func on_hit(target: Node) -> void:
	AudioManager.play_hit_sound()
	super.on_hit(target)

func _get_pool_name() -> String:
	return "player_bullet"

func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	
	if collider.is_in_group("enemies") or collider.has_method("_take_damage"):
		_apply_ammo_effect(collider)
	
	super._handle_collision(collision)

func _apply_ammo_effect(target: Node) -> void:
	match ammo_type:
		"piercing":
			pierce_count = 3
		"explosive":
			_create_explosion()
		"homing":
			print("[BulletPlayer] Homing bullet tracking target")

func _create_explosion() -> void:
	var explosion = ObjectPool.get_object("explosion", "res://scenes/environment/Explosion.tscn")
	if explosion:
		explosion.global_position = global_position
