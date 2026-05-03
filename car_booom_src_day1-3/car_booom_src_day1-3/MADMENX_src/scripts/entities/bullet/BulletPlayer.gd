## BulletPlayer — 玩家子弹
##
## 功能说明：
## - 玩家射击的子弹
## - 支持穿透机制（穿透逻辑由 BulletBase 处理）
##
## 对接注意事项：
## - 穿透逻辑由 piercing_count 控制（继承自 BulletBase）
##
## 创建人：长安旧梦
## 创建日期：2026-04-29

class_name BulletPlayer
extends BulletBase

func _ready() -> void:
	super._ready()
	bullet_owner = 0  # PLAYER
