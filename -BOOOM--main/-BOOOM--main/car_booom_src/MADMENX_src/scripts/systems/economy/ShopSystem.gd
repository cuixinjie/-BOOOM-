## ShopSystem — 商店系统
##
## 功能说明：
## - 管理商店购买
## - 提供武器、配件、弹药购买
##
## 对接注意事项：
## - 被 UI 层调用
## - 依赖 EconomySystem
##
## 创建人：新街
## 创建日期：2026-04-28

class_name ShopSystem
extends Node

signal shop_opened()
signal shop_closed()
signal item_purchased(item_id: String)
signal purchase_failed(item_id: String, reason: String)

enum ShopCategory {
	WEAPONS,
	ATTACHMENTS,
	AMMO,
	UTILITY
}

var _is_shop_open: bool = false
var _available_items: Dictionary = {}

# ===== 接口定义 =====
## open_shop() -> void
##   打开商店
##
## close_shop() -> void
##   关闭商店
##
## purchase_item(item_id: String) -> bool
##   购买物品
##
## get_items_by_category(category: ShopCategory) -> Array
##   获取分类物品
## ===== 接口结束 =====

func _ready() -> void:
	_initialize_shop()
	_connect_signals()
	print("[ShopSystem] Initialized")

func _initialize_shop() -> void:
	_available_items = {
		"weapons": {
			"smg": {"name": "冲锋枪", "cost": 500, "owned": false},
			"shotgun": {"name": "霰弹枪", "cost": 800, "owned": false},
			"sniper": {"name": "狙击枪", "cost": 1200, "owned": false}
		},
		"attachments": {
			"stabilizer": {"name": "稳定器", "cost": 300, "level": 0, "max_level": 3},
			"extended_mag": {"name": "扩容弹匣", "cost": 400, "level": 0, "max_level": 3},
			"muzzle_brake": {"name": "炮口制退器", "cost": 350, "level": 0, "max_level": 3}
		},
		"ammo": {
			"ammo_pack_small": {"name": "小弹药包", "cost": 50, "amount": 30},
			"ammo_pack_large": {"name": "大弹药包", "cost": 150, "amount": 100}
		},
		"utility": {
			"health_kit": {"name": "医疗包", "cost": 100, "effect": 30},
			"energy_drink": {"name": "能量饮料", "cost": 75, "effect": 50}
		}
	}

func _connect_signals() -> void:
	EventBus.rest_point_entered.connect(open_shop)

func open_shop() -> void:
	_is_shop_open = true
	shop_opened.emit()
	print("[ShopSystem] Shop opened")

func close_shop() -> void:
	_is_shop_open = false
	shop_closed.emit()
	print("[ShopSystem] Shop closed")

func purchase_item(item_id: String) -> bool:
	if not _is_shop_open:
		purchase_failed.emit(item_id, "shop_closed")
		return false
	
	var item = _find_item(item_id)
	if not item:
		purchase_failed.emit(item_id, "item_not_found")
		return false
	
	var cost = item.get("cost", 0)
	if EconomySystem.attempt_purchase(item_id, cost):
		_apply_purchase(item_id, item)
		item_purchased.emit(item_id)
		return true
	
	purchase_failed.emit(item_id, "insufficient_funds")
	return false

func _find_item(item_id: String) -> Dictionary:
	for category in _available_items.values():
		if category.has(item_id):
			return category[item_id]
	return {}

func _apply_purchase(item_id: String, item: Dictionary) -> void:
	if _available_items["weapons"].has(item_id):
		_available_items["weapons"][item_id]["owned"] = true
	elif _available_items["attachments"].has(item_id):
		var current_level = _available_items["attachments"][item_id]["level"]
		_available_items["attachments"][item_id]["level"] = current_level + 1

func get_items_by_category(category: String) -> Dictionary:
	return _available_items.get(category, {})

func is_weapon_owned(weapon_id: String) -> bool:
	return _available_items["weapons"].get(weapon_id, {}).get("owned", false)

func get_attachment_level(attachment_id: String) -> int:
	return _available_items["attachments"].get(attachment_id, {}).get("level", 0)
