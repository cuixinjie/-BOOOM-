## AmmoDisplay — 弹药显示组件
##
## 功能说明：
## - 显示当前弹药数和备弹
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name AmmoDisplay
extends HBoxContainer

@onready var current_label: Label = $CurrentLabel
@onready var reserve_label: Label = $ReserveLabel

func _ready() -> void:
	current_label.text = "0"
	reserve_label.text = "/ 0"

func set_ammo(current: int, reserve: int) -> void:
	current_label.text = str(current)
	reserve_label.text = "/ %d" % reserve

func set_ammo_color(color: Color) -> void:
	current_label.modulate = color
