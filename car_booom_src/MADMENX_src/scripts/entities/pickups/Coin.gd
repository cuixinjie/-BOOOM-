## Coin — 金币拾取物
##
## 功能说明：
## - 玩家可拾取的金币
##
## 对接注意事项：
## - 场景文件：scenes/entities/pickups/Coin.tscn
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name Coin
extends Pickupable

func _ready() -> void:
	super._ready()
	pickup_value = 10
	despawn_time = 15.0

func on_pickup_effect(picker: Node) -> void:
	GameManager.add_coins(pickup_value)
	AudioManager.play_coin_sound()
	print("[Coin] Collected ", pickup_value, " coins")
