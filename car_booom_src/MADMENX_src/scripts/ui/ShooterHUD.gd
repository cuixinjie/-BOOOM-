## ShooterHUD — 射击手HUD
##
## 功能说明：
## - 显示射击手相关信息
## - 武器、弹药、弹药类型、换弹进度
## - 瞄准方向指示、狙击枪预判线、霰弹枪扇形覆盖
##
## 对接注意事项：
## - 被 HUDController 管理
## - 数据通过 EventBus 更新
## - EventBus.weapon_fired → 播放射击动画
## - EventBus.weapon_reloaded → 播放换弹动画 + 更新弹药显示
## - EventBus.ammo_type_changed → 更新弹药类型图标
## - EventBus.repair_progress_changed → 修车进度条（在驾驶员 HUD 显示）
## - Shooter（池言いく）提供瞄准方向用于绘制瞄准指示
##
## HUD 布局（右半屏）
## [武器图标]              [弹药类型图标]
## [弹药数量: 6 / 6]      [换弹进度条]
## [瞄准指示]              [扇形覆盖（霰弹枪）]
## [预判线（狙击枪）]
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name ShooterHUD
extends Control

@onready var weapon_icon: TextureRect = $VBox/WeaponContainer/WeaponIcon
@onready var weapon_name_label: Label = $VBox/WeaponContainer/WeaponNameLabel
@onready var ammo_label: Label = $VBox/AmmoContainer/AmmoLabel
@onready var ammo_slash: Label = $VBox/AmmoContainer/AmmoSlash
@onready var ammo_max_label: Label = $VBox/AmmoContainer/AmmoMaxLabel
@onready var ammo_type_icon: TextureRect = $VBox/AmmoTypeContainer/AmmoTypeIcon
@onready var ammo_type_label: Label = $VBox/AmmoTypeContainer/AmmoTypeLabel
@onready var reload_progress: ProgressBar = $VBox/ReloadProgress
@onready var reload_label: Label = $VBox/ReloadLabel
@onready var aim_indicator: Control = $AimIndicator
@onready var aim_crosshair: TextureRect = $AimIndicator/Crosshair
@onready var aim_line: Line2D = $AimIndicator/AimLine
@onready var sniper_predict_line: Line2D = $AimIndicator/SniperPredictLine
@onready var shotgun_fan: ColorRect = $AimIndicator/ShotgunFan
@onready var shotgun_fan_outline: Line2D = $AimIndicator/ShotgunFanOutline

var _current_weapon: String = "pistol"
var _ammo_current: int = 6
var _ammo_max: int = 6
var _ammo_type: String = "normal"
var _is_reloading: bool = false
var _reload_duration: float = 1.5
var _aim_direction: Vector2 = Vector2.RIGHT
var _current_weapon_type: String = "pistol"

const WEAPON_ICONS_PATH: String = "res://assets/art/ui/weapon_"
const AMMO_TYPE_ICONS_PATH: String = "res://assets/art/ui/ammo_type_"

func _ready() -> void:
	_connect_signals()
	_reset_display()
	print("[ShooterHUD] Initialized")

func _reset_display() -> void:
	update_weapon("pistol")
	update_ammo(6, 6)
	update_ammo_type("normal")

func _connect_signals() -> void:
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(_on_weapon_reloaded)
	EventBus.ammo_type_changed.connect(_on_ammo_type_changed)
	EventBus.repair_progress_changed.connect(_on_repair_progress_changed)

func _on_weapon_fired(weapon_id: String) -> void:
	_current_weapon = weapon_id
	_ammo_current -= 1
	update_ammo(_ammo_current, _ammo_max)
	_play_fire_feedback()

func _on_weapon_reloaded(weapon_id: String) -> void:
	_is_reloading = false
	_hide_reload_ui()
	if weapon_id == _current_weapon:
		_ammo_current = _ammo_max
		update_ammo(_ammo_current, _ammo_max)

func _on_ammo_type_changed(ammo_type: String) -> void:
	update_ammo_type(ammo_type)

func _on_repair_progress_changed(progress: float) -> void:
	pass

func _play_fire_feedback() -> void:
	if aim_crosshair:
		var original_pos = aim_crosshair.position
		aim_crosshair.position += _aim_direction * 5
		var tween = create_tween()
		tween.tween_property(aim_crosshair, "position", original_pos, 0.1)

func update_weapon(weapon_id: String) -> void:
	_current_weapon = weapon_id
	_current_weapon_type = _get_weapon_type(weapon_id)
	
	if weapon_icon:
		var icon_path = WEAPON_ICONS_PATH + weapon_id + ".png"
		var texture = load(icon_path)
		if texture:
			weapon_icon.texture = texture
		else:
			weapon_icon.texture = null
	
	if weapon_name_label:
		weapon_name_label.text = _get_weapon_display_name(weapon_id)
	
	_update_aim_indicator_for_weapon()

func update_ammo(current: int, max_ammo: int) -> void:
	_ammo_current = current
	_ammo_max = max_ammo
	
	if ammo_label:
		ammo_label.text = str(current)
		_update_ammo_color()
	
	if ammo_max_label:
		ammo_max_label.text = str(max_ammo)

func update_ammo_type(ammo_type: String) -> void:
	_ammo_type = ammo_type
	
	if ammo_type_icon:
		var icon_path = AMMO_TYPE_ICONS_PATH + ammo_type + ".png"
		var texture = load(icon_path)
		if texture:
			ammo_type_icon.texture = texture
	
	if ammo_type_label:
		ammo_type_label.text = _get_ammo_type_display_name(ammo_type)

func show_reload_progress(duration: float) -> void:
	_is_reloading = true
	_reload_duration = duration
	
	if reload_progress:
		reload_progress.visible = true
		reload_progress.max_value = duration
		reload_progress.value = 0
	
	if reload_label:
		reload_label.visible = true
		reload_label.text = "换弹中..."

func update_aim_direction(direction: Vector2) -> void:
	_aim_direction = direction
	_update_aim_indicator()

func update_aim_direction_with_target(direction: Vector2, target_position: Vector2) -> void:
	_aim_direction = direction
	_update_aim_indicator()
	
	if _current_weapon_type == "sniper" and sniper_predict_line:
		sniper_predict_line.visible = true
		_draw_sniper_predict_line(target_position)

func _update_aim_indicator() -> void:
	if not aim_indicator:
		return
	
	match _current_weapon_type:
		"pistol", "smg":
			if aim_crosshair:
				aim_crosshair.visible = true
			if aim_line:
				aim_line.visible = true
				aim_line.points = PackedVector2Array([Vector2.ZERO, _aim_direction * 50])
			if sniper_predict_line:
				sniper_predict_line.visible = false
			if shotgun_fan:
				shotgun_fan.visible = false
			if shotgun_fan_outline:
				shotgun_fan_outline.visible = false
		
		"sniper":
			if aim_crosshair:
				aim_crosshair.visible = true
			if aim_line:
				aim_line.visible = true
				aim_line.points = PackedVector2Array([Vector2.ZERO, _aim_direction * 100])
				aim_line.default_color = Color.RED
			if sniper_predict_line:
				sniper_predict_line.visible = true
			if shotgun_fan:
				shotgun_fan.visible = false
			if shotgun_fan_outline:
				shotgun_fan_outline.visible = false
		
		"shotgun":
			if aim_crosshair:
				aim_crosshair.visible = true
			if aim_line:
				aim_line.visible = false
			if sniper_predict_line:
				sniper_predict_line.visible = false
			if shotgun_fan:
				shotgun_fan.visible = true
				_draw_shotgun_fan()
			if shotgun_fan_outline:
				shotgun_fan_outline.visible = true
				_draw_shotgun_fan_outline()

func _update_aim_indicator_for_weapon() -> void:
	_update_aim_indicator()

func _draw_sniper_predict_line(target_position: Vector2) -> void:
	if sniper_predict_line and aim_line:
		var start_pos = aim_line.global_position
		sniper_predict_line.clear_points()
		sniper_predict_line.add_point(start_pos)
		sniper_predict_line.add_point(target_position)

func _draw_shotgun_fan() -> void:
	var fan_angle = deg_to_rad(22.5)
	var fan_distance = 200.0
	var center_pos = Vector2.ZERO
	
	var points = PackedVector2Array()
	points.append(center_pos)
	
	var steps = 8
	for i in range(steps + 1):
		var angle = -fan_angle / 2 + fan_angle * i / steps
		var point = center_pos + Vector2.from_angle(_aim_direction.angle() + angle) * fan_distance
		points.append(point)
	
	shotgun_fan.visible = true

func _draw_shotgun_fan_outline() -> void:
	var fan_angle = deg_to_rad(22.5)
	var fan_distance = 200.0
	
	var points = PackedVector2Array()
	
	var steps = 8
	for i in range(steps + 1):
		var angle = -fan_angle / 2 + fan_angle * i / steps
		var point = Vector2.from_angle(_aim_direction.angle() + angle) * fan_distance
		points.append(point)
	
	shotgun_fan_outline.clear_points()
	for p in points:
		shotgun_fan_outline.add_point(p)

func _update_ammo_color() -> void:
	if not ammo_label:
		return
	
	var ratio = float(_ammo_current) / float(_ammo_max) if _ammo_max > 0 else 0
	
	if _ammo_current == 0:
		ammo_label.add_theme_color_override("font_color", Color.RED)
	elif ratio <= 0.3:
		ammo_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		ammo_label.add_theme_color_override("font_color", Color.WHITE)

func _hide_reload_ui() -> void:
	if reload_progress:
		reload_progress.visible = false
	if reload_label:
		reload_label.visible = false

func _get_weapon_type(weapon_id: String) -> String:
	match weapon_id:
		"pistol":
			return "pistol"
		"smg":
			return "smg"
		"shotgun":
			return "shotgun"
		"sniper":
			return "sniper"
		_:
			return "pistol"

func _get_weapon_display_name(weapon_id: String) -> String:
	match weapon_id:
		"pistol":
			return "手枪"
		"smg":
			return "冲锋枪"
		"shotgun":
			return "霰弹枪"
		"sniper":
			return "狙击枪"
		_:
			return weapon_id

func _get_ammo_type_display_name(ammo_type: String) -> String:
	match ammo_type:
		"normal":
			return "普通"
		"piercing":
			return "穿甲"
		"explosive":
			return "爆炸"
		"electric":
			return "电击"
		_:
			return ammo_type

func hide_hud() -> void:
	visible = false

func show_hud() -> void:
	visible = true
