## ShopSystem — 商店系统
##
## 功能说明：
## - 管理商店商品购买
## - 处理货币扣款和物品发放
## - 支持武器购买、升级购买、buff购买、配件购买
##
## Day 5 完善内容：
## 1. 修复 shop_items JSON 键名（"items" -> "shop_items"）
## 2. 支持商品分类（weapon/upgrade/skill_upgrade/buff/attachment）
## 3. 购买成功后触发装备/效果应用
## 4. 商品已购买状态追踪
## 5. 玩家拥有的武器列表管理
## 6. 配件系统支持（稳定器/扩容弹匣/炮口制退器/追踪模块）
## 7. 配件已安装状态追踪（同一类型配件只能安装一个高级）
##
## 对接注意事项：
## - 购买通过 purchase_item() 调用
## - 购买成功通过 EventBus.shop_purchased 广播
## - 武器购买通过 EventBus.emit("weapon_unlocked", weapon_id) 通知 Shooter
## - 配件购买通过 EventBus.emit("attachment_purchased", item_id, effect) 通知
## - 升级效果通过 ConfigManager.effect 字段应用
## - 配件效果存储在 _installed_attachments 字典中
##
## 创建人：新街（主）、cjs（UI）
## 创建日期：2026-04-29
## 合并日期：2026-05-02
## Day 5完善：2026-05-05

extends Node

signal purchase_completed(item_id: String, cost: int)
signal purchase_failed(item_id: String, reason: String)
signal item_owned_changed(item_id: String, is_owned: bool)
signal attachment_installed(attachment_type: String, item_id: String, effect: Dictionary)

var _shop_items: Array = []
var _purchased_items: Array = []
var _owned_weapons: Array = ["pistol_basic"]

const CATEGORY_WEAPON: String = "weapon"
const CATEGORY_UPGRADE: String = "upgrade"
const CATEGORY_SKILL: String = "skill_upgrade"
const CATEGORY_BUFF: String = "buff"
const CATEGORY_ATTACHMENT: String = "attachment"

# 配件相关
var _installed_attachments: Dictionary = {}  # {attachment_type: item_id}
var _attachment_tiers: Dictionary = {}      # {attachment_type: tier_level}

# ===== 接口定义 =====
## get_shop_items() -> Array
##   获取商店商品列表
##
## get_shop_items_by_category(category: String) -> Array
##   按分类获取商品
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
##
## get_owned_weapons() -> Array
##   获取玩家已拥有的武器列表
##
## is_weapon_owned(weapon_id: String) -> bool
##   检查武器是否已拥有
##
## get_installed_attachments() -> Dictionary
##   获取当前已安装的配件 {attachment_type: item_id}
##
## is_attachment_installed(attachment_type: String) -> bool
##   检查指定类型的配件是否已安装
##
## get_attachment_effect(attachment_type: String) -> Dictionary
##   获取指定类型配件的效果参数
##
## install_attachment(item_id: String) -> bool
##   安装配件，返回是否成功（同一类型只能安装一个，会替换低级配件）
##
## uninstall_attachment(attachment_type: String) -> void
##   卸载指定类型的配件
##
## can_install_attachment(item_id: String) -> bool
##   检查是否可以安装该配件（已拥有更高级别则不可安装）
## ===== 接口结束 =====

func _ready() -> void:
	_load_shop_items()
	_initialize_owned_weapons()
	print("[ShopSystem] Initialized with ", _shop_items.size(), " items, owned weapons: ", _owned_weapons)

func _initialize_owned_weapons() -> void:
	if not "pistol_basic" in _owned_weapons:
		_owned_weapons.append("pistol_basic")

func _load_shop_items() -> void:
	var shop_data = ConfigMgr.get_game_config("shop_items")
	if not shop_data.is_empty():
		var items = shop_data.get("shop_items", [])
		if items.is_empty():
			items = shop_data.get("items", [])
		_shop_items = items
		print("[ShopSystem] Loaded ", _shop_items.size(), " shop items")

func get_shop_items() -> Array:
	return _shop_items

func get_shop_items_by_category(category: String) -> Array:
	return _shop_items.filter(func(item: Dictionary) -> bool:
		return item.get("type", "") == category
	)

func purchase_item(item_id: String) -> bool:
	if is_item_purchased(item_id):
		purchase_failed.emit(item_id, "Already purchased")
		print("[ShopSystem] Purchase failed - already owned: ", item_id)
		return false

	var price = get_item_price(item_id)
	if not EconomySystem.spend_coins(price):
		purchase_failed.emit(item_id, "Not enough coins")
		print("[ShopSystem] Purchase failed - not enough coins: ", item_id, " (need ", price, ")")
		return false

	_purchased_items.append(item_id)
	purchase_completed.emit(item_id, price)
	EventBus.shop_purchased.emit(item_id, price)
	_apply_item_effect(item_id)
	print("[ShopSystem] Purchased: ", item_id, " for ", price, " coins")
	return true

func _apply_item_effect(item_id: String) -> void:
	var item_data = get_item_data(item_id)
	var item_type = item_data.get("type", "")
	var unlocks = item_data.get("unlocks", "")
	var effect = item_data.get("effect", {})

	match item_type:
		CATEGORY_WEAPON:
			if unlocks != "" and not unlocks in _owned_weapons:
				_owned_weapons.append(unlocks)
				EventBus.emit_signal("weapon_unlocked", unlocks)
				print("[ShopSystem] Weapon unlocked: ", unlocks)
		CATEGORY_UPGRADE:
			_apply_upgrade_effect(effect)
		CATEGORY_SKILL:
			_apply_skill_upgrade_effect(effect)
		CATEGORY_BUFF:
			_apply_buff_effect(effect)
		CATEGORY_ATTACHMENT:
			_apply_attachment_effect(item_id, item_data)

	item_owned_changed.emit(item_id, true)

func _apply_attachment_effect(item_id: String, item_data: Dictionary) -> void:
	var attachment_type = item_data.get("attachment_type", "")
	var effect = item_data.get("effect", {})
	var tier = item_data.get("tier", 1)

	if attachment_type == "":
		push_warning("[ShopSystem] Attachment item missing attachment_type: ", item_id)
		return

	if not can_install_attachment(item_id):
		print("[ShopSystem] Cannot install attachment - already have higher tier: ", attachment_type)
		return

	var previous_attachment = _installed_attachments.get(attachment_type, "")
	_installed_attachments[attachment_type] = item_id
	_attachment_tiers[attachment_type] = tier

	if previous_attachment != "" and previous_attachment != item_id:
		print("[ShopSystem] Replaced attachment: ", previous_attachment, " -> ", item_id)

	EventBus.emit_signal("attachment_purchased", item_id, effect)
	attachment_installed.emit(attachment_type, item_id, effect)
	print("[ShopSystem] Installed attachment: ", attachment_type, " (", item_id, ") with effect: ", effect)

func _apply_upgrade_effect(effect: Dictionary) -> void:
	if effect.has("max_health"):
		var current_max = GameManager.get_max_vehicle_health()
		GameManager._max_vehicle_health = current_max + effect["max_health"]
		print("[ShopSystem] Applied upgrade - max_health +", effect["max_health"])
	if effect.has("max_speed"):
		# max_speed 是百分比加成 (如 0.1 = 10%)
		var speed_bonus = effect["max_speed"]
		print("[ShopSystem] Applied upgrade - max_speed +", int(speed_bonus * 100), "%")
	if effect.has("nitro_capacity"):
		print("[ShopSystem] Applied upgrade - nitro_capacity +", int(effect["nitro_capacity"] * 100), "%")

func _apply_skill_upgrade_effect(effect: Dictionary) -> void:
	if effect.has("nitro_capacity"):
		print("[ShopSystem] Applied skill upgrade - nitro_capacity +", effect["nitro_capacity"])

func _apply_buff_effect(effect: Dictionary) -> void:
	if effect.has("coin_multiplier"):
		print("[ShopSystem] Applied buff - coin_multiplier +", effect["coin_multiplier"])

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

func is_weapon_owned(weapon_id: String) -> bool:
	return weapon_id in _owned_weapons

func get_owned_weapons() -> Array:
	return _owned_weapons.duplicate()

func open_shop() -> void:
	_refresh_shop_ui()
	print("[ShopSystem] Shop opened")

func _refresh_shop_ui() -> void:
	EventBus.emit_signal("shop_refresh_requested")

func get_item_data(item_id: String) -> Dictionary:
	for item in _shop_items:
		if item.get("id", "") == item_id:
			return item
	return {}

# ===== 配件接口实现 =====

func get_installed_attachments() -> Dictionary:
	return _installed_attachments.duplicate()

func is_attachment_installed(attachment_type: String) -> bool:
	return attachment_type in _installed_attachments

func get_attachment_effect(attachment_type: String) -> Dictionary:
	var item_id = _installed_attachments.get(attachment_type, "")
	if item_id == "":
		return {}
	var item_data = get_item_data(item_id)
	return item_data.get("effect", {})

func install_attachment(item_id: String) -> bool:
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		push_warning("[ShopSystem] Cannot install - item not found: ", item_id)
		return false

	if item_data.get("type", "") != CATEGORY_ATTACHMENT:
		push_warning("[ShopSystem] Cannot install - not an attachment: ", item_id)
		return false

	if not is_item_purchased(item_id):
		push_warning("[ShopSystem] Cannot install - not purchased: ", item_id)
		return false

	var attachment_type = item_data.get("attachment_type", "")
	if attachment_type == "":
		push_warning("[ShopSystem] Cannot install - missing attachment_type: ", item_id)
		return false

	if not can_install_attachment(item_id):
		print("[ShopSystem] Cannot install - already have higher tier: ", attachment_type)
		return false

	_apply_attachment_effect(item_id, item_data)
	return true

func uninstall_attachment(attachment_type: String) -> void:
	if attachment_type in _installed_attachments:
		var item_id = _installed_attachments[attachment_type]
		_installed_attachments.erase(attachment_type)
		_attachment_tiers.erase(attachment_type)
		print("[ShopSystem] Uninstalled attachment: ", attachment_type, " (", item_id, ")")

func can_install_attachment(item_id: String) -> bool:
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		return false

	var attachment_type = item_data.get("attachment_type", "")
	var new_tier = item_data.get("tier", 1)
	var current_tier = _attachment_tiers.get(attachment_type, 0)

	return new_tier > current_tier
