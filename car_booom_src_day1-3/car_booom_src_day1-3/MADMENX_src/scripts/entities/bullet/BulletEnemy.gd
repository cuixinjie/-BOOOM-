## BulletEnemy — 敌人弹幕
##
## 功能说明：
## - 敌人发射的弹幕
## - 支持跟踪弹机制
##
## 对接注意事项：
## - homing_strength > 0 时启用跟踪
## - 跟踪目标通过 homing_target 设置
##
## 创建人：长安旧梦
## 创建日期：2026-04-29

class_name BulletEnemy
extends BulletBase

var homing_strength: float = 0.0
var homing_target: Node = null

func _ready() -> void:
	super._ready()
	bullet_owner = 1  # ENEMY

func fire(dir: Vector2, spd: float, dmg: float, blt_owner: int = 1, pierce: int = 0, spawn_pos: Vector2 = Vector2.ZERO) -> void:
	super.fire(dir, spd, dmg, blt_owner, pierce, spawn_pos)

func _process(delta: float) -> void:
	if homing_strength > 0 and is_instance_valid(homing_target):
		var to_target = (homing_target.global_position - global_position).normalized()
		bullet_direction = bullet_direction.lerp(to_target, homing_strength * delta).normalized()

	super._process(delta)
