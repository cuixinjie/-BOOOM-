## ShopUI — 商店界面
##
## 功能说明：
## - 显示商店界面（躲藏点访问）
## - 显示商品列表（武器升级、弹药、道具）
## - 处理购买逻辑和反馈
## - 显示金币余额
##
## 对接注意事项：
## - ShopSystem（新街维护）提供商品数据
## - ShopSystem 调用 open_shop() / close_shop()
## - EventBus.rest_point_entered → 显示商店入口
## - EventBus.shop_purchased → 更新购买状态
## - EconomySystem 提供金币数据
## - 在躲藏点（RestPoint）显示
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name ShopUI
extends CanvasLayer

enum ShopCategory {
	WEAPONS,
	AMMO,
	UPGRADES,
	ITEMS
}

const ITEM_SLOT_COUNT: int = 12

var _is_open: bool = false
var _current_category: ShopCategory = ShopCategory.WEAPONS
var _shop_items: Array[Dictionary] = []
var _purchased_items: Array[String] = []

@onready var shop_panel: PanelContainer = $ShopPanel
@onready var header: HBoxContainer = $ShopPanel/VBox/Header
@onready var coin_display: Label = $ShopPanel/VBox/Header/CoinDisplay/CoinLabel
@onready var content: Control = $ShopPanel/VBox/Content
@onready var category_tabs: HBoxContainer = $ShopPanel/VBox/CategoryTabs
@onready var item_grid: GridContainer = $ShopPanel/VBox/Content/ItemGrid
@onready var close_button: Button = $ShopPanel/VBox/Header/CloseButton
@onready var confirm_panel: Control = $ConfirmPanel
@onready var confirm_item_name: Label = $ConfirmPanel/VBox/ItemName
@onready var confirm_item_price: Label = $ConfirmPanel/VBox/ItemPrice
@onready var confirm_buy_button: Button = $ConfirmPanel/VBox/BuyButton
@onready var confirm_cancel_button: Button = $ConfirmPanel/VBox/CancelButton
@onready var message_label: Label = $ShopPanel/VBox/MessageLabel

var _selected_item_index: int = -1
var _item_slots: Array[Control] = []

func _ready() -> void:
	_initialize_item_slots()
	_connect_signals()
	_hide_shop()
	print("[ShopUI] Initialized")

func _initialize_item_slots() -> void:
	for i in range(ITEM_SLOT_COUNT):
		var slot = item_grid.get_node_or_null("ItemSlot" + str(i))
		if slot:
			slot.slot_index = i
			slot.slot_clicked.connect(_on_item_slot_clicked)
			_item_slots.append(slot)
		else:
			_item_slots.append(null)

func _connect_signals() -> void:
	EventBus.rest_point_entered.connect(_on_rest_point_entered)
	EventBus.shop_opened.connect(_on_shop_opened)
	EventBus.shop_closed.connect(_on_shop_closed)
	EventBus.shop_purchased.connect(_on_shop_purchased)
	EventBus.coin_collected.connect(_on_coin_changed)

func _on_rest_point_entered() -> void:
	_show_shop_entry_prompt()

func _show_shop_entry_prompt() -> void:
	print("[ShopUI] Rest point entered - shop available")

func _on_shop_opened() -> void:
	open_shop()

func _on_shop_closed() -> void:
	close_shop()

func _on_shop_purchased(item_id: String, cost: int) -> void:
	_purchased_items.append(item_id)
	_update_coin_display()
	_refresh_item_list()
	_show_message("购买成功！")

func _on_coin_changed(amount: int) -> void:
	_update_coin_display()

func open_shop() -> void:
	_is_open = true
	_update_coin_display()
	_load_shop_items()
	_refresh_item_list()
	_show_shop()
	get_tree().paused = true
	print("[ShopUI] Shop opened")

func close_shop() -> void:
	_is_open = false
	_hide_shop()
	_hide_confirm_panel()
	get_tree().paused = false
	print("[ShopUI] Shop closed")

func _show_shop() -> void:
	if shop_panel:
		shop_panel.visible = true

func _hide_shop() -> void:
	if shop_panel:
		shop_panel.visible = false

func _load_shop_items() -> void:
	_shop_items.clear()
	
	if ShopSystem and ShopSystem.has_method("get_shop_items"):
		_shop_items = ShopSystem.get_shop_items()
	else:
		_shop_items = _get_default_shop_items()

func _get_default_shop_items() -> Array[Dictionary]:
	return [
		{"id": "weapon_pistol_upgrade", "name": "手枪强化", "category": ShopCategory.WEAPONS, "price": 100, "description": "提升手枪伤害 +10%"},
		{"id": "weapon_smg", "name": "冲锋枪", "category": ShopCategory.WEAPONS, "price": 500, "description": "解锁冲锋枪"},
		{"id": "weapon_shotgun", "name": "霰弹枪", "category": ShopCategory.WEAPONS, "price": 800, "description": "解锁霰弹枪"},
		{"id": "weapon_sniper", "name": "狙击枪", "category": ShopCategory.WEAPONS, "price": 1200, "description": "解锁狙击枪"},
		{"id": "ammo_normal", "name": "普通弹药", "category": ShopCategory.AMMO, "price": 50, "description": "补给 30 发普通弹药"},
		{"id": "ammo_piercing", "name": "穿甲弹药", "category": ShopCategory.AMMO, "price": 100, "description": "补给 15 发穿甲弹药"},
		{"id": "ammo_explosive", "name": "爆炸弹药", "category": ShopCategory.AMMO, "price": 150, "description": "补给 10 发爆炸弹药"},
		{"id": "upgrade_health", "name": "生命强化", "category": ShopCategory.UPGRADES, "price": 300, "description": "最大生命 +20"},
		{"id": "upgrade_energy", "name": "能量强化", "category": ShopCategory.UPGRADES, "price": 300, "description": "最大能量 +15"},
		{"id": "upgrade_speed", "name": "速度强化", "category": ShopCategory.UPGRADES, "price": 400, "description": "移动速度 +10%"},
		{"id": "item_health_pack", "name": "急救包", "category": ShopCategory.ITEMS, "price": 80, "description": "恢复 50 生命值"},
		{"id": "item_energy_drink", "name": "能量饮料", "category": ShopCategory.ITEMS, "price": 60, "description": "恢复 30 能量值"},
	]

func _refresh_item_list() -> void:
	var category_items = _shop_items.filter(func(item): return item.get("category", 0) == _current_category)
	
	for i in range(_item_slots.size()):
		var slot = _item_slots[i]
		if not slot:
			continue
		
		if i < category_items.size():
			var item = category_items[i]
			slot.set_item({"icon_path": _get_item_icon_path(item)})
			slot.set_selected(false)
			slot.set_disabled(_purchased_items.has(item["id"]))
		else:
			slot.set_empty()
			slot.set_selected(false)
			slot.set_disabled(false)

func _get_item_icon_path(item: Dictionary) -> String:
	match item.get("category", 0):
		ShopCategory.WEAPONS:
			return "res://assets/art/ui/icon_weapon.png"
		ShopCategory.AMMO:
			return "res://assets/art/ui/icon_ammo.png"
		ShopCategory.UPGRADES:
			return "res://assets/art/ui/icon_upgrade.png"
		ShopCategory.ITEMS:
			return "res://assets/art/ui/icon_item.png"
		_:
			return ""

func _on_item_slot_clicked(slot_index: int) -> void:
	var category_items = _shop_items.filter(func(item): return item.get("category", 0) == _current_category)
	
	if slot_index >= category_items.size():
		return
	
	var item = category_items[slot_index]
	
	if _purchased_items.has(item["id"]):
		_show_message("已购买此物品")
		return
	
	_selected_item_index = slot_index
	
	for i in range(_item_slots.size()):
		if _item_slots[i]:
			_item_slots[i].set_selected(i == slot_index)
	
	_show_confirm_panel(item)

func _show_confirm_panel(item: Dictionary) -> void:
	if not confirm_panel:
		return
	
	confirm_panel.visible = true
	confirm_item_name.text = item.get("name", "未知物品")
	confirm_item_price.text = "价格: %d 金币" % item.get("price", 0)
	
	var current_coins = _get_current_coins()
	var price = item.get("price", 0)
	confirm_buy_button.disabled = current_coins < price

func _hide_confirm_panel() -> void:
	if confirm_panel:
		confirm_panel.visible = false
	_selected_item_index = -1

func _on_buy_confirmed() -> void:
	var category_items = _shop_items.filter(func(item): return item.get("category", 0) == _current_category)
	
	if _selected_item_index < 0 or _selected_item_index >= category_items.size():
		return
	
	var item = category_items[_selected_item_index]
	var price = item.get("price", 0)
	
	if _try_purchase(item["id"], price):
		_purchased_items.append(item["id"])
		_refresh_item_list()
		_hide_confirm_panel()
		_show_message("购买成功！")
	else:
		_show_message("金币不足！")

func _try_purchase(item_id: String, price: int) -> bool:
	if EconomySystem and EconomySystem.has_method("deduct_coins"):
		return EconomySystem.deduct_coins(price)
	return false

func _on_buy_canceled() -> void:
	_hide_confirm_panel()
	for slot in _item_slots:
		if slot:
			slot.set_selected(false)

func _update_coin_display() -> void:
	if coin_display:
		coin_display.text = str(_get_current_coins())

func _get_current_coins() -> int:
	if EconomySystem and EconomySystem.has_method("get_coins"):
		return EconomySystem.get_coins()
	return 0

func _show_message(text: String) -> void:
	if message_label:
		message_label.text = text
		message_label.visible = true
		
		await get_tree().create_timer(2.0).timeout
		
		if message_label:
			message_label.visible = false

func _on_category_weapons() -> void:
	_current_category = ShopCategory.WEAPONS
	_refresh_item_list()

func _on_category_ammo() -> void:
	_current_category = ShopCategory.AMMO
	_refresh_item_list()

func _on_category_upgrades() -> void:
	_current_category = ShopCategory.UPGRADES
	_refresh_item_list()

func _on_category_items() -> void:
	_current_category = ShopCategory.ITEMS
	_refresh_item_list()

func _on_close_pressed() -> void:
	if ShopSystem and ShopSystem.has_method("close_shop"):
		ShopSystem.close_shop()
	else:
		close_shop()
