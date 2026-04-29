## InventorySlot — 背包格子组件
##
## 功能说明：
## - 显示物品格子
## - 空格子：灰色边框
## - 有物品：显示图标
## - 选中状态：金色边框
## - 数量标签（用于显示堆叠数量）
##
## 对接注意事项：
## - 被 ShopUI 或背包系统使用
## - 可拖拽接口（预留）
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name InventorySlot
extends Control

enum SlotState {
	EMPTY,
	HAS_ITEM,
	SELECTED,
	DISABLED,
}

signal slot_clicked(slot_index: int)
signal slot_right_clicked(slot_index: int)
signal item_dropped(slot_index: int, item_data: Dictionary)

@export var slot_index: int = 0
@export var slot_size: Vector2 = Vector2(64, 64)

## 空格子颜色
@export var empty_border_color: Color = Color(0.3, 0.3, 0.3, 0.5)
## 有物品时边框颜色
@export var normal_border_color: Color = Color(0.5, 0.5, 0.5, 1.0)
## 选中状态边框颜色
@export var selected_border_color: Color = Color(1.0, 0.84, 0.0, 1.0)
## 禁用状态边框颜色
@export var disabled_border_color: Color = Color(0.2, 0.2, 0.2, 0.3)

@onready var border_rect: ColorRect = $BorderRect
@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $QuantityLabel
@onready var selection_glow: ColorRect = $SelectionGlow

var _slot_state: SlotState = SlotState.EMPTY
var _item_data: Dictionary = {}
var _quantity: int = 1
var _is_hovered: bool = false

func _ready() -> void:
	custom_minimum_size = slot_size
	_update_visual()
	print("[InventorySlot] Initialized with index: ", slot_index)

func _gui_input(event: InputEvent) -> void:
	if _slot_state == SlotState.DISABLED:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_slot_clicked()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_on_slot_right_clicked()
	elif event is InputEventMouseMotion:
		_is_hovered = true
		_update_hover_visual()

func _on_slot_clicked() -> void:
	slot_clicked.emit(slot_index)
	print("[InventorySlot] Slot clicked: ", slot_index)

func _on_slot_right_clicked() -> void:
	slot_right_clicked.emit(slot_index)

func set_item(item_data: Dictionary, quantity: int = 1) -> void:
	_item_data = item_data
	_quantity = quantity
	
	if item_data.is_empty():
		set_empty()
	else:
		_slot_state = SlotState.HAS_ITEM
		_update_item_display()

func set_empty() -> void:
	_slot_state = SlotState.EMPTY
	_item_data = {}
	_quantity = 0
	_update_visual()

func set_selected(selected: bool) -> void:
	if selected:
		_slot_state = SlotState.SELECTED
	else:
		_slot_state = SlotState.HAS_ITEM if not _item_data.is_empty() else SlotState.EMPTY
	
	_update_visual()

func set_disabled(disabled: bool) -> void:
	if disabled:
		_slot_state = SlotState.DISABLED
	else:
		_slot_state = SlotState.HAS_ITEM if not _item_data.is_empty() else SlotState.EMPTY
	
	_update_visual()

func get_item_data() -> Dictionary:
	return _item_data

func get_quantity() -> int:
	return _quantity

func get_slot_state() -> SlotState:
	return _slot_state

func has_item() -> bool:
	return _slot_state == SlotState.HAS_ITEM or _slot_state == SlotState.SELECTED

func _update_visual() -> void:
	if not border_rect:
		return
	
	match _slot_state:
		SlotState.EMPTY:
			border_rect.color = empty_border_color
			_show_item(false)
			_show_quantity(false)
			_show_selection(false)
		
		SlotState.HAS_ITEM:
			border_rect.color = normal_border_color
			_show_item(true)
			_show_quantity(_quantity > 1)
			_show_selection(false)
		
		SlotState.SELECTED:
			border_rect.color = selected_border_color
			_show_item(true)
			_show_quantity(_quantity > 1)
			_show_selection(true)
		
		SlotState.DISABLED:
			border_rect.color = disabled_border_color
			_show_item(_item_data.size() > 0)
			_show_quantity(false)
			_show_selection(false)

func _update_item_display() -> void:
	if not item_icon:
		return
	
	if _item_data.has("icon_path"):
		var icon_path = _item_data["icon_path"]
		if icon_path != "":
			item_icon.texture = load(icon_path)
			return
	
	item_icon.texture = null

func _update_hover_visual() -> void:
	if _slot_state == SlotState.DISABLED:
		return
	
	if _is_hovered and border_rect:
		var hover_color = border_rect.color.lightened(0.1)
		border_rect.color = hover_color
		_is_hovered = false

func _show_item(show: bool) -> void:
	if item_icon:
		item_icon.visible = show

func _show_quantity(show: bool) -> void:
	if quantity_label:
		quantity_label.visible = show
		if show:
			quantity_label.text = str(_quantity)

func _show_selection(show: bool) -> void:
	if selection_glow:
		selection_glow.visible = show
	
	if show:
		_play_selection_animation()

func _play_selection_animation() -> void:
	if not selection_glow:
		return
	
	var tween = create_tween().set_loops()
	tween.tween_property(selection_glow, "modulate:a", 0.3, 0.5)
	tween.tween_property(selection_glow, "modulate:a", 0.6, 0.5)
