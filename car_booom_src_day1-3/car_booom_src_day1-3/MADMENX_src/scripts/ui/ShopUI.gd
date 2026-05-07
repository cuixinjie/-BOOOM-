## ShopUI — 商店界面
##
## 功能说明：
## - 显示商店界面（按钮式分类标签页）
## - 处理商品购买、武器装备、配件装备
## - 展示商品名称、描述、价格、拥有状态
##
## Day 5 完善内容：
## 1. 添加分类按钮（全部/武器/升级/技能/配件）
## 2. 商品卡片显示名称、描述、价格
## 3. 已购买商品显示"已拥有"状态
## 4. 武器商品可切换装备
## 5. 配件商品可安装/替换
## 6. 购买成功后自动刷新
## 7. 添加关闭按钮
##
## Day 6 完善内容：
## 1. 添加Buff分类支持
## 2. 优化金币不足时的显示
## 3. 配件安装逻辑增强
##
## 对接注意事项：
## - ShopSystem 提供商品数据，ShopUI 只负责展示
## - 武器装备通过 EventBus.weapon_unlocked 和 weapon_switch_requested 通信
## - 配件装备通过 EventBus.attachment_purchased 和 ShopSystem.install_attachment 通信
## - 金币显示实时同步
## - 关闭商店时自动退出躲藏点
##
## 创建人：新街（主）、cjs（基础UI）
## 创建日期：2026-04-29
## Day 5完善：2026-05-05
## Day 6完善：Buff分类支持、优化显示（2026-05-05）

extends Control

const CATEGORY_ALL: String = "all"
const CATEGORY_WEAPON: String = "weapon"
const CATEGORY_UPGRADE: String = "upgrade"
const CATEGORY_SKILL: String = "skill_upgrade"
const CATEGORY_BUFF: String = "buff"
const CATEGORY_ATTACHMENT: String = "attachment"

@onready var coin_label: Label = get_node_or_null("Panel/VBox/Header/CoinsLabel")
@onready var items_container: VBoxContainer = get_node_or_null("Panel/VBox/ScrollContainer/ItemsContainer")
@onready var close_button: Button = get_node_or_null("Panel/VBox/Header/CloseButton")
@onready var tab_all: Button = get_node_or_null("Panel/VBox/CategoryTabs/TabAll")
@onready var tab_weapons: Button = get_node_or_null("Panel/VBox/CategoryTabs/TabWeapons")
@onready var tab_upgrades: Button = get_node_or_null("Panel/VBox/CategoryTabs/TabUpgrades")
@onready var tab_skills: Button = get_node_or_null("Panel/VBox/CategoryTabs/TabSkills")
@onready var tab_attachments: Button = get_node_or_null("Panel/VBox/CategoryTabs/TabAttachments")
@onready var tab_buffs: Button = get_node_or_null("Panel/VBox/CategoryTabs/TabBuffs")

var _current_category: String = CATEGORY_ALL
var _owned_weapons: Array = ["pistol_basic"]
var _installed_attachments: Dictionary = {}

func _ready() -> void:
	visible = false
	_connect_signals()
	_connect_tab_buttons()
	_connect_close_button()
	print("[ShopUI] Initialized")

func _connect_signals() -> void:
	if EventBus.has_signal("shop_purchased"):
		EventBus.shop_purchased.connect(_on_shop_purchased)
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.connect("weapon_unlocked", _on_weapon_unlocked)
	EventBus.connect("shop_refresh_requested", _on_shop_refresh_requested)
	EventBus.connect("attachment_purchased", _on_attachment_purchased)

func _connect_tab_buttons() -> void:
	if tab_all:
		tab_all.pressed.connect(func(): _switch_category(CATEGORY_ALL))
	if tab_weapons:
		tab_weapons.pressed.connect(func(): _switch_category(CATEGORY_WEAPON))
	if tab_upgrades:
		tab_upgrades.pressed.connect(func(): _switch_category(CATEGORY_UPGRADE))
	if tab_skills:
		tab_skills.pressed.connect(func(): _switch_category(CATEGORY_SKILL))
	if tab_buffs:
		tab_buffs.pressed.connect(func(): _switch_category(CATEGORY_BUFF))
	if tab_attachments:
		tab_attachments.pressed.connect(func(): _switch_category(CATEGORY_ATTACHMENT))

func _connect_close_button() -> void:
	if close_button:
		close_button.pressed.connect(hide_shop)

func _switch_category(category: String) -> void:
	_current_category = category
	_highlight_active_tab()
	refresh_items()

func _highlight_active_tab() -> void:
	var tabs = [tab_all, tab_weapons, tab_upgrades, tab_skills, tab_buffs, tab_attachments]
	var categories = [CATEGORY_ALL, CATEGORY_WEAPON, CATEGORY_UPGRADE, CATEGORY_SKILL, CATEGORY_BUFF, CATEGORY_ATTACHMENT]
	for i in range(tabs.size()):
		if tabs[i]:
			var is_active = categories[i] == _current_category
			var prefix = "[*] " if is_active else "[  ] "
			tabs[i].text = prefix + tabs[i].text.replace("[*] ", "").replace("[  ] ", "")

func show_shop() -> void:
	visible = true
	_current_category = CATEGORY_ALL
	_update_coin_display()
	_update_attachment_status()
	refresh_items()
	print("[ShopUI] Shop shown")

func hide_shop() -> void:
	visible = false
	EventBus.rest_point_exit_requested.emit()
	print("[ShopUI] Shop hidden")

func _update_attachment_status() -> void:
	if ShopSystem:
		_installed_attachments = ShopSystem.get_installed_attachments()
		print("[ShopUI] Updated attachments: ", _installed_attachments)

func refresh_items() -> void:
	if not items_container:
		return
	for child in items_container.get_children():
		child.queue_free()

	var all_items = ShopSystem.get_shop_items()
	var items_to_show: Array = []

	match _current_category:
		CATEGORY_ALL:
			items_to_show = all_items
		CATEGORY_WEAPON:
			items_to_show = ShopSystem.get_shop_items_by_category(CATEGORY_WEAPON)
		CATEGORY_UPGRADE:
			items_to_show = ShopSystem.get_shop_items_by_category(CATEGORY_UPGRADE)
		CATEGORY_SKILL:
			items_to_show = ShopSystem.get_shop_items_by_category(CATEGORY_SKILL)
		CATEGORY_BUFF:
			items_to_show = ShopSystem.get_shop_items_by_category(CATEGORY_BUFF)
		CATEGORY_ATTACHMENT:
			items_to_show = ShopSystem.get_shop_items_by_category(CATEGORY_ATTACHMENT)
		_:
			items_to_show = all_items

	for item in items_to_show:
		var card = _create_item_card(item)
		items_container.add_child(card)

	_update_coin_display()
	_owned_weapons = ShopSystem.get_owned_weapons()
	_update_attachment_status()

func _create_item_card(item: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.set("custom_minimum_size", Vector2(0, 72))

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.set("size_flags_horizontal", Control.SIZE_EXPAND_FILL)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = item.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
	info_vbox.add_child(desc_label)

	var btn_vbox = VBoxContainer.new()
	hbox.add_child(btn_vbox)

	var price_label = Label.new()
	price_label.text = "%d coins" % item.get("price", 0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.add_theme_font_size_override("font_size", 12)
	btn_vbox.add_child(price_label)

	var item_id = item.get("id", "")
	var item_type = item.get("type", "")
	var is_owned = ShopSystem.is_item_purchased(item_id)
	var can_buy = ShopSystem.can_afford(item_id)

	var action_btn = Button.new()
	action_btn.set("custom_minimum_size", Vector2(80, 28))
	btn_vbox.add_child(action_btn)

	match item_type:
		CATEGORY_WEAPON:
			_setup_weapon_card(item, name_label, action_btn, price_label, can_buy)
		CATEGORY_ATTACHMENT:
			_setup_attachment_card(item, name_label, action_btn, price_label, can_buy, is_owned)
		_:
			_setup_normal_card(item, name_label, action_btn, price_label, can_buy, is_owned)

	return panel

func _setup_weapon_card(item: Dictionary, name_label: Label, action_btn: Button, price_label: Label, can_buy: bool) -> void:
	var item_id = item.get("id", "")
	var unlocks = item.get("unlocks", "")
	var is_owned = ShopSystem.is_item_purchased(item_id)

	if is_owned:
		if _owned_weapons.has(unlocks):
			action_btn.text = "已装备"
			action_btn.disabled = true
			name_label.modulate = Color(0.6, 1.0, 0.6, 1.0)
		else:
			action_btn.text = "装备"
			action_btn.pressed.connect(func(): _equip_weapon(unlocks))
	else:
		if can_buy:
			action_btn.text = "购买"
			action_btn.pressed.connect(func(): _on_item_purchased(item_id))
		else:
			action_btn.text = "金币不足"
			action_btn.disabled = true
			price_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _setup_attachment_card(item: Dictionary, name_label: Label, action_btn: Button, price_label: Label, can_buy: bool, is_owned: bool) -> void:
	var item_id = item.get("id", "")
	var attachment_type = item.get("attachment_type", "")
	var tier = item.get("tier", 1)
	var installed_item_id = _installed_attachments.get(attachment_type, "")
	var current_tier = 0
	
	if installed_item_id != "":
		var installed_data = ShopSystem.get_item_data(installed_item_id)
		current_tier = installed_data.get("tier", 0)
	
	var is_installed = installed_item_id == item_id

	if is_installed:
		action_btn.text = "已安装"
		action_btn.disabled = true
		name_label.modulate = Color(0.6, 1.0, 0.6, 1.0)
	elif is_owned:
		if tier > current_tier or current_tier == 0:
			action_btn.text = "安装"
			action_btn.pressed.connect(func(): _install_attachment(item_id))
		else:
			action_btn.text = "已拥有更高级"
			action_btn.disabled = true
			name_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
	elif can_buy:
		action_btn.text = "购买"
		action_btn.pressed.connect(func(): _on_item_purchased(item_id))
	else:
		action_btn.text = "金币不足"
		action_btn.disabled = true
		price_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _setup_normal_card(item: Dictionary, name_label: Label, action_btn: Button, price_label: Label, can_buy: bool, is_owned: bool) -> void:
	var item_id = item.get("id", "")

	if is_owned:
		action_btn.text = "已拥有"
		action_btn.disabled = true
		name_label.modulate = Color(0.6, 1.0, 0.6, 1.0)
	elif can_buy:
		action_btn.text = "购买"
		action_btn.pressed.connect(func(): _on_item_purchased(item_id))
	else:
		action_btn.text = "金币不足"
		action_btn.disabled = true
		price_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _on_item_purchased(item_id: String) -> void:
	if ShopSystem.purchase_item(item_id):
		refresh_items()

func _equip_weapon(weapon_id: String) -> void:
	if not weapon_id in _owned_weapons:
		_owned_weapons.append(weapon_id)
	EventBus.emit_signal("weapon_switch_requested", weapon_id)
	refresh_items()
	print("[ShopUI] Equipped weapon: ", weapon_id)

func _install_attachment(item_id: String) -> void:
	if ShopSystem.install_attachment(item_id):
		_update_attachment_status()
		refresh_items()
		print("[ShopUI] Installed attachment: ", item_id)

func _update_coin_display() -> void:
	if coin_label:
		coin_label.text = "Coins: %d" % EconomySystem.get_coins()

func _on_shop_purchased(_item_id: String, _cost: int) -> void:
	refresh_items()

func _on_coin_collected(_amount: int) -> void:
	_update_coin_display()
	refresh_items()

func _on_weapon_unlocked(weapon_id: String) -> void:
	if not weapon_id in _owned_weapons:
		_owned_weapons.append(weapon_id)
	refresh_items()

func _on_attachment_purchased(_attachment_type: String, _item_id: String, _effect: Dictionary) -> void:
	_update_attachment_status()
	refresh_items()

func _on_shop_refresh_requested() -> void:
	refresh_items()
