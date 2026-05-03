## HealthBar — 血条组件
##
## 功能说明：
## - 通用的血条UI组件
## - 支持颜色渐变
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name HealthBar
extends ProgressBar

@export var max_color: Color = Color.GREEN
@export var mid_color: Color = Color.YELLOW
@export var min_color: Color = Color.RED

func _ready() -> void:
	_update_color()

func _process(delta: float) -> void:
	_update_color()

func _update_color() -> void:
	var ratio = value / max_value if max_value > 0 else 0.0
	if ratio > 0.6:
		modulate = max_color
	elif ratio > 0.3:
		modulate = mid_color
	else:
		modulate = min_color

func set_health(current: float, maximum: float) -> void:
	max_value = maximum
	value = current
	_update_color()
