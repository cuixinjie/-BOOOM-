## SkillCooldown — 技能冷却组件
##
## 功能说明：
## - 显示技能冷却状态
## - 支持遮罩动画
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name SkillCooldown
extends TextureProgressBar

@export var skill_key: String = "Q"

var _is_ready: bool = true

func _ready() -> void:
	value = 100.0
	_is_ready = true

func start_cooldown(duration: float) -> void:
	_is_ready = false
	value = 0.0
	var tween = create_tween()
	tween.tween_property(self, "value", 100.0, duration)

	await get_tree().create_timer(duration).timeout
	_is_ready = true

func is_ready() -> bool:
	return _is_ready

func force_ready() -> void:
	_is_ready = true
	value = 100.0
