## AmmoDisplay — 弹药显示组件
##
## 功能说明：
## - 显示当前弹药数量
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name AmmoDisplay
extends Control

@onready var ammo_label: Label = $AmmoLabel
@onready var reserve_label: Label = $ReserveLabel

var _current_ammo: int = 0
var _max_ammo: int = 0
var _reserve_ammo: int = 0

func _ready() -> void:
	update(0, 0)

func update(current: int, maximum: int, reserve: int = -1) -> void:
	_current_ammo = current
	_max_ammo = maximum
	
	if reserve >= 0:
		_reserve_ammo = reserve
		if reserve_label:
			reserve_label.text = "/" + str(_reserve_ammo)
	
	if ammo_label:
		ammo_label.text = str(current)
	
	_update_visual_state()

func _update_visual_state() -> void:
	if ammo_label:
		if _current_ammo == 0:
			ammo_label.add_theme_color_override("font_color", Color.RED)
		elif _current_ammo <= _max_ammo * 0.3:
			ammo_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			ammo_label.add_theme_color_override("font_color", Color.WHITE)

func show_reload() -> void:
	if ammo_label:
		ammo_label.text = "RELOAD"
		ammo_label.add_theme_color_override("font_color", Color.ORANGE)
