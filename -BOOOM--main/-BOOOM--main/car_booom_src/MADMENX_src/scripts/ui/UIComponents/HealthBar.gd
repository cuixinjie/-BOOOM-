## HealthBar — 血条组件
##
## 功能说明：
## - 可复用的血条 UI 组件
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name HealthBar
extends ProgressBar

@export var low_health_threshold: float = 0.3
@export var critical_health_threshold: float = 0.15

@export var normal_color: Color = Color.GREEN
@export var low_color: Color = Color.YELLOW
@export var critical_color: Color = Color.RED

func _ready() -> void:
	_update_color()

func update_health(current: float, maximum: float) -> void:
	if maximum > 0:
		value = (current / maximum) * 100
		_update_color()

func _update_color() -> void:
	var percent = value / 100.0
	if percent <= critical_health_threshold:
		add_theme_color_override("fg_color", critical_color)
	elif percent <= low_health_threshold:
		add_theme_color_override("fg_color", low_color)
	else:
		add_theme_color_override("fg_color", normal_color)
