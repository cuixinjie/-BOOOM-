## ShopUI — 商店界面
##
## 功能说明：
## - 显示商店界面
## - 处理购买逻辑
##
## 对接注意事项：
## - 被 ShopSystem 调用
## - 显示在躲藏点
##
## 创建人：新街
## 创建日期：2026-04-28

class_name ShopUI
extends CanvasLayer

@onready var shop_container: Node = $ShopContainer
@onready var coin_display: Node = $ShopContainer/Header/CoinDisplay
@onready var weapon_list: Node = $ShopContainer/Content/WeaponList
@onready var close_button: Node = $ShopContainer/Header/CloseButton

var _is_open: bool = false

func _ready() -> void:
	_connect_signals()
	shop_container.visible = false
	print("[ShopUI] Initialized")

func _connect_signals() -> void:
	EventBus.rest_point_entered.connect(_on_rest_point_entered)
	ShopSystem.shop_opened.connect(_on_shop_opened)
	ShopSystem.shop_closed.connect(_on_shop_closed)
	ShopSystem.item_purchased.connect(_on_item_purchased)

func _on_rest_point_entered() -> void:
	if ShopSystem._is_shop_open:
		open_shop()

func _on_shop_opened() -> void:
	open_shop()

func _on_shop_closed() -> void:
	close_shop()

func _on_item_purchased(item_id: String) -> void:
	update_coin_display()
	_refresh_item_list()

func open_shop() -> void:
	_is_open = true
	shop_container.visible = true
	update_coin_display()
	_refresh_item_list()
	get_tree().paused = true

func close_shop() -> void:
	_is_open = false
	shop_container.visible = false
	get_tree().paused = false

func update_coin_display() -> void:
	if coin_display:
		coin_display.text = str(GameManager.get_coins())

func _refresh_item_list() -> void:
	pass

func _on_close_pressed() -> void:
	ShopSystem.close_shop()
