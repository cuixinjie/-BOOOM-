## ShooterHUD — 射击手HUD
##
## 功能说明：
## - 显示射击手相关数据（准星、弹药、技能等）
##
## 创建人：cjs
## 创建日期：2026-04-28

extends Control

@onready var ammo_display: Label = $AmmoDisplay if has_node("AmmoDisplay") else null
@onready var reload_progress: ProgressBar = $ReloadProgress if has_node("ReloadProgress") else null

var _shooter_ref: Node = null

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func set_shooter_reference(shooter: Node) -> void:
	_shooter_ref = shooter

func update_ammo(current: int, reserve: int) -> void:
	if ammo_display:
		ammo_display.text = "%d / %d" % [current, reserve]

func show_reload_progress(progress: float) -> void:
	if reload_progress:
		reload_progress.visible = progress < 1.0
		reload_progress.value = progress * 100.0
