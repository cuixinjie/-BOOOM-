## BulletEnemy — 敌人子弹/弹幕
##
## 功能说明：
## - 敌人发射的子弹
## - 继承 BulletBase
##
## 对接注意事项：
## - 场景文件：scenes/entities/bullets/BulletEnemy.tscn
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name BulletEnemy
extends BulletBase

@export var bullet_type: String = "normal"

func _ready() -> void:
	super._ready()
	add_to_group("enemy_bullets")

func on_hit(target: Node) -> void:
	AudioManager.play_hit_sound()
	super.on_hit(target)

func _get_pool_name() -> String:
	return "enemy_bullet"

func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	
	if collider.is_in_group("vehicle") or collider.is_in_group("players"):
		super._handle_collision(collision)
	elif collider.has_method("_take_damage"):
		super._handle_collision(collision)
