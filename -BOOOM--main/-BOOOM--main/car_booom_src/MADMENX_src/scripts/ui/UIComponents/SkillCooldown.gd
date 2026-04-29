## SkillCooldown — 技能冷却指示器
##
## 功能说明：
## - 显示技能冷却状态
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name SkillCooldown
extends Control

@onready var icon: TextureRect = $Icon
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var cooldown_label: Label = $CooldownLabel

@export var skill_id: String = ""

var _max_cooldown: float = 0.0
var _current_cooldown: float = 0.0
var _is_ready: bool = true

func _ready() -> void:
	if cooldown_overlay:
		cooldown_overlay.visible = false
	if cooldown_label:
		cooldown_label.visible = false

func set_skill(skill_name: String, icon_path: String, cooldown: float) -> void:
	skill_id = skill_name
	_max_cooldown = cooldown
	
	if icon and icon_path != "":
		icon.texture = load(icon_path)

func update_cooldown(remaining: float) -> void:
	_current_cooldown = remaining
	
	if _max_cooldown > 0:
		var progress = remaining / _max_cooldown
		
		if cooldown_overlay:
			cooldown_overlay.visible = progress > 0
			cooldown_overlay.size.y = size.y * progress
		
		if cooldown_label:
			cooldown_label.visible = progress > 0
			cooldown_label.text = str(ceil(remaining))
		
		_is_ready = progress <= 0
		modulate = Color.WHITE if _is_ready else Color.GRAY

func is_ready() -> bool:
	return _is_ready
