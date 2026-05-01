## EconomySystem — 经济系统
##
## 功能说明：
## - 管理金币和消费
## - 处理经济事件
##
## 对接注意事项：
## - 被 ShopSystem、DropSystem 调用
## - 通过 EventBus.coin_collected 监听
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name EconomySystem
extends Node

signal coins_changed(amount: int)
signal purchase_completed(item_id: String, cost: int)
signal purchase_failed(item_id: String, reason: String)

var _coins: int = 0
var _lifetime_earned: int = 0
var _lifetime_spent: int = 0

# ===== 接口定义 =====
## add_coins(amount: int) -> void
##   添加金币
##
## spend_coins(amount: int) -> bool
##   花费金币，成功返回 true
##
## get_coins() -> int
##   获取当前金币
##
## can_afford(cost: int) -> bool
##   是否买得起
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	_coins = 0
	print("[EconomySystem] Initialized")

func _connect_signals() -> void:
	EventBus.coin_collected.connect(_on_coin_collected)

func _on_coin_collected(amount: int) -> void:
	add_coins(amount)

func add_coins(amount: int) -> void:
	_coins += amount
	_lifetime_earned += amount
	coins_changed.emit(_coins)
	print("[EconomySystem] Coins: ", _coins)

func spend_coins(amount: int) -> bool:
	if _coins >= amount:
		_coins -= amount
		_lifetime_spent += amount
		coins_changed.emit(_coins)
		return true
	return false

func get_coins() -> int:
	return _coins

func can_afford(cost: int) -> bool:
	return _coins >= cost

func attempt_purchase(item_id: String, cost: int) -> bool:
	if can_afford(cost):
		spend_coins(cost)
		purchase_completed.emit(item_id, cost)
		EventBus.shop_purchased.emit(item_id, cost)
		print("[EconomySystem] Purchase completed: ", item_id)
		return true
	else:
		purchase_failed.emit(item_id, "insufficient_funds")
		print("[EconomySystem] Purchase failed: insufficient funds for ", item_id)
		return false

func get_lifetime_stats() -> Dictionary:
	return {
		"earned": _lifetime_earned,
		"spent": _lifetime_spent
	}
