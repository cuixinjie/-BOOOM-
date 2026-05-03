## InventorySlot — 物品栏格子
##
## 功能说明：
## - 通用物品栏格子组件
## - 支持拖拽和图标显示
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name InventorySlot
extends PanelContainer

signal item_selected(item_id: String)
signal item_used(item_id: String)

var item_id: String = ""
var item_count: int = 0

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $CountLabel
@onready var selected_indicator: ColorRect = $SelectedIndicator

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_item(id: String, count: int = 1) -> void:
	item_id = id
	item_count = count
	_update_display()

func clear_slot() -> void:
	item_id = ""
	item_count = 0
	icon.texture = null
	count_label.text = ""

func _update_display() -> void:
	if item_id != "":
		count_label.text = str(item_count) if item_count > 1 else ""
		selected_indicator.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			item_selected.emit(item_id)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			item_used.emit(item_id)

func set_selected(selected: bool) -> void:
	selected_indicator.visible = selected
