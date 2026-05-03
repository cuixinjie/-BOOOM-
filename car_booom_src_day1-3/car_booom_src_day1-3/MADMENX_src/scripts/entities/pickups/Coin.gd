## Coin — 金币
##
## 功能说明：
## - 最常见的拾取物
## - 提供货币奖励
##
## 对接注意事项：
## - 通过 ObjectPool 管理，禁止直接 instance()
## - 拾取调用 EconomySystem.add_coins
##
## 创建人：cjs
## 创建日期：2026-04-28
## 修复日期：2026-05-02

class_name Coin
extends Pickupable

func _ready() -> void:
	pickup_type = PickupType.COIN
	value = 10
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D as AnimatedSprite2D
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
			sprite.play("default")
		else:
			sprite.play()

func on_pickup(picker: Node) -> void:
	EconomySystem.add_coins(value)
	AudioManager.play_coin_sound()
	EventBus.coin_collected.emit(value)
	print("[Coin] Collected ", value, " coins")
