## ShopSystem — 商店系统
##
## 功能说明：
## - 管理商店商品购买
## - 处理货币扣款和物品发放
##
## 对接注意事项：
## - 购买通过 EventBus.shop_purchase_requested 请求
## - 购买成功通过 EventBus.shop_purchased 广播
##
## 创建人：新街（主）、cjs（UI）
## 创建日期：2026-04-29
## 合并日期：2026-05-02

extends Node

signal purchase_completed(item_id: String, cost: int)
signal purchase_failed(item_id: String, reason: String)

var _shop_items: Array = []
var _purchased_items: Array = []

# ===== 接口定义 =====
## get_shop_items() -> Array
##   获取商店商品列表
##
## purchase_item(item_id: String) -> bool
##   购买商品，返回是否成功
##
## can_afford(item_id: String) -> bool
##   检查是否能购买
##
## get_item_price(item_id: String) -> int
##   获取商品价格
##
## is_item_purchased(item_id: String) -> bool
##   检查商品是否已购买
## ===== 接口结束 =====

func _ready() -> void:
	_load_shop_items()
	print("[ShopSystem] Initialized with ", _shop_items.size(), " items")

func _load_shop_items() -> void:
	var shop_data = ConfigMgr.get_game_config("shop_items")
	if shop_data:
		_shop_items = shop_data.get("items", [])

func get_shop_items() -> Array:
	return _shop_items

func purchase_item(item_id: String) -> bool:
	if is_item_purchased(item_id):
		purchase_failed.emit(item_id, "Already purchased")
		return false

	var price = get_item_price(item_id)
	if not EconomySystem.spend_coins(price):
		purchase_failed.emit(item_id, "Not enough coins")
		return false

	_purchased_items.append(item_id)
	purchase_completed.emit(item_id, price)
	EventBus.shop_purchased.emit(item_id, price)

	print("[ShopSystem] Purchased: ", item_id, " for ", price, " coins")
	return true

func can_afford(item_id: String) -> bool:
	var price = get_item_price(item_id)
	return EconomySystem.get_coins() >= price

func get_item_price(item_id: String) -> int:
	for item in _shop_items:
		if item.get("id", "") == item_id:
			return item.get("price", 0)
	return 0

func is_item_purchased(item_id: String) -> bool:
	return item_id in _purchased_items

func open_shop() -> void:
	EventBus.rest_point_exited.emit()
	print("[ShopSystem] Shop opened")

func get_item_data(item_id: String) -> Dictionary:
	for item in _shop_items:
		if item.get("id", "") == item_id:
			return item
	return {}
