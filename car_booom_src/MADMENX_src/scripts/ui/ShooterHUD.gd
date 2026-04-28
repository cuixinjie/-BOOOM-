## ShooterHUD — 射击手HUD
##
## 功能说明：
## - 显示射击手相关信息
## - 武器、弹药、瞄准指示
##
## 对接注意事项：
## - 被 HUDController 管理
## - 数据通过 EventBus 更新
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name ShooterHUD
extends Control

@onready var weapon_icon: Node = $VBox/WeaponContainer/WeaponIcon
@onready var ammo_display: Node = $VBox/AmmoContainer/AmmoDisplay
@onready var reload_progress: Node = $VBox/ReloadProgress
@onready var aim_indicator: Node = $AimIndicator

var _current_weapon: String = "pistol"
var _ammo_current: int = 6
var _ammo_max: int = 6
var _is_reloading: bool = false

func _ready() -> void:
	_connect_signals()
	print("[ShooterHUD] Initialized")

func _connect_signals() -> void:
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(_on_weapon_reloaded)
	EventBus.ammo_type_changed.connect(_on_ammo_type_changed)

func _on_weapon_fired(weapon_id: String) -> void:
	_current_weapon = weapon_id
	_ammo_current -= 1
	update_ammo(_ammo_current, _ammo_max)

func _on_weapon_reloaded(weapon_id: String) -> void:
	_is_reloading = false
	if reload_progress:
		reload_progress.visible = false

func _on_ammo_type_changed(ammo_type: String) -> void:
	print("[ShooterHUD] Ammo type changed to: ", ammo_type)

func update_weapon(weapon_id: String) -> void:
	_current_weapon = weapon_id
	if weapon_icon:
		weapon_icon.texture = load("res://assets/art/ui/weapon_" + weapon_id + ".png")

func update_ammo(current: int, max_ammo: int) -> void:
	_ammo_current = current
	_ammo_max = max_ammo
	if ammo_display:
		ammo_display.update(current, max_ammo)

func show_reload_progress(duration: float) -> void:
	_is_reloading = true
	if reload_progress:
		reload_progress.visible = true
		reload_progress.max_value = duration
		reload_progress.value = 0

func update_aim_direction(direction: Vector2) -> void:
	if aim_indicator:
		aim_indicator.rotation = direction.angle()
