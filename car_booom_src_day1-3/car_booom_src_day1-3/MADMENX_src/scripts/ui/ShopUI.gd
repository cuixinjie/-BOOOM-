## ShopUI — 商店界面
##
## 功能说明：
## - 显示商店界面
## - 处理商品购买
##
## 创建人：cjs
## 创建日期：2026-04-29

extends Control

@onready var shop_items_container: VBoxContainer = get_node_or_null("Panel/VBox/ScrollContainer/ShopItems")
@onready var coin_label: Label = get_node_or_null("Panel/VBox/CoinLabel")

var _item_buttons: Array = []

func _ready() -> void:
	visible = false
	if has_node("Panel/VBox/CloseButton"):
		$Panel/VBox/CloseButton.pressed.connect(hide_shop)

func show_shop() -> void:
	visible = true
	refresh_items()

func hide_shop() -> void:
	visible = false
	EventBus.rest_point_exit_requested.emit()

func refresh_items() -> void:
	if shop_items_container:
		for child in shop_items_container.get_children():
			child.queue_free()

	var items = ShopSystem.get_shop_items()
	for item in items:
		var button = _create_item_button(item)
		if shop_items_container:
			shop_items_container.add_child(button)

	if coin_label:
		coin_label.text = "Coins: %d" % EconomySystem.get_coins()

func _create_item_button(item: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = "%s - %d coins" % [item.get("name", "Unknown"), item.get("price", 0)]
	btn.pressed.connect(func(): _on_item_clicked(item.get("id", "")))
	return btn

func _on_item_clicked(item_id: String) -> void:
	if ShopSystem.purchase_item(item_id):
		refresh_items()
