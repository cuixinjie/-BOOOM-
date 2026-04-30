## DriverHUD — 驾驶员HUD
##
## 功能说明：
## - 显示驾驶员相关信息
## - 血量、能量、耐力、追兵距离、技能冷却
## - 金币、熟练度/等级
## - 路段进度、修车进度
##
## 对接注意事项：
## - 被 HUDController 管理
## - 数据通过 EventBus 更新
## - EventBus.vehicle_damaged / vehicle_repaired → 更新血量条
## - EventBus.energy_collected → 更新能量条
## - EventBus.skill_used → 更新技能冷却
## - EventBus.chase_distance_changed → 更新追兵距离指示器颜色
## - EventBus.world_state_changed → 更新里世界状态指示
## - EventBus.segment_completed → 更新路段进度
## - EventBus.proficiency_gained → 更新熟练度
## - EventBus.repair_progress_changed → 显示修车进度条
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name DriverHUD
extends Control

## HUD 布局（左半屏）
## [追兵距离箭头]          [路段进度条]
## [血量条]                [能量条]
## [耐力图标 x1]           [技能图标 x5]
## [金币] [熟练度]

@onready var health_bar: ProgressBar = $VBox/HealthContainer/HealthBar
@onready var energy_bar: ProgressBar = $VBox/EnergyContainer/EnergyBar
@onready var stamina_container: HBoxContainer = $VBox/StaminaContainer
@onready var coin_label: Label = $CoinDisplay/CoinLabel
@onready var level_label: Label = $ProficiencyDisplay/LevelLabel
@onready var proficiency_bar: ProgressBar = $ProficiencyDisplay/ProficiencyBar
@onready var chase_indicator: Control = $ChaseIndicator
@onready var chase_arrow: TextureRect = $ChaseIndicator/ChaseArrow
@onready var chase_distance_label: Label = $ChaseIndicator/DistanceLabel
@onready var skill_grid: GridContainer = $SkillGrid
@onready var segment_progress: ProgressBar = $SegmentProgress/SegmentBar
@onready var segment_label: Label = $SegmentProgress/SegmentLabel
@onready var repair_overlay: Control = $RepairOverlay
@onready var repair_progress: ProgressBar = $RepairOverlay/RepairProgress
@onready var repair_label: Label = $RepairOverlay/RepairLabel

const STAMINA_ICON_COUNT: int = 3
const SKILL_ICON_COUNT: int = 5

var _stamina_icons: Array[TextureRect] = []
var _skill_icons: Array[Control] = []
var _current_stamina: float = 100.0
var _max_stamina: float = 100.0
var _current_chase_distance: float = 100.0

var _current_health: float = 100.0
var _max_health: float = 100.0
var _current_energy: float = 100.0
var _max_energy: float = 100.0
var _coins: int = 0
var _current_level: int = 1
var _current_proficiency: float = 0.0

func _ready() -> void:
	_initialize_stamina_icons()
	_initialize_skill_icons()
	_connect_signals()
	_reset_display()
	print("[DriverHUD] Initialized")

func _initialize_stamina_icons() -> void:
	for i in range(STAMINA_ICON_COUNT):
		var icon = stamina_container.get_node_or_null("StaminaIcon" + str(i))
		if icon:
			_stamina_icons.append(icon)

func _initialize_skill_icons() -> void:
	for i in range(SKILL_ICON_COUNT):
		var icon = skill_grid.get_node_or_null("SkillIcon" + str(i))
		if icon:
			_skill_icons.append(icon)

func _reset_display() -> void:
	update_health(100.0, 100.0)
	update_energy(100.0, 100.0)
	update_stamina(100.0, 100.0)
	update_coins(0)
	update_progression(1, 0.0)
	update_segment_progress(0, 100)

func _connect_signals() -> void:
	EventBus.vehicle_damaged.connect(_on_vehicle_damaged)
	EventBus.vehicle_repaired.connect(_on_vehicle_repaired)
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.chase_distance_changed.connect(_on_chase_distance_changed)
	EventBus.world_state_changed.connect(_on_world_state_changed)
	EventBus.segment_completed.connect(_on_segment_completed)
	EventBus.proficiency_gained.connect(_on_proficiency_gained)
	EventBus.level_up.connect(_on_level_up)
	EventBus.repair_progress_changed.connect(_on_repair_progress_changed)
	EventBus.repair_completed.connect(_on_repair_completed)
	EventBus.skill_used.connect(_on_skill_used)

func _on_vehicle_damaged(damage: float) -> void:
	_current_health = _get_vehicle_health()
	_update_health_bar()
	_play_damage_feedback()

func _on_vehicle_repaired(amount: float) -> void:
	_current_health = _get_vehicle_health()
	_update_health_bar()

func _on_coin_collected(amount: int) -> void:
	update_coins(_get_coins())

func _on_chase_distance_changed(distance: float) -> void:
	_current_chase_distance = distance
	_update_chase_indicator()

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	pass

func _on_segment_completed(segment_id: int) -> void:
	print("[DriverHUD] Segment completed: ", segment_id)

func _on_proficiency_gained(amount: float) -> void:
	var prof = _get_proficiency()
	var level = _get_current_level()
	update_progression(level, prof)

func _on_level_up(new_level: int) -> void:
	update_progression(new_level, 0.0)

func _on_repair_progress_changed(progress: float) -> void:
	_show_repair_overlay(progress)

func _on_repair_completed() -> void:
	_hide_repair_overlay()

func _on_skill_used(skill_id: String) -> void:
	print("[DriverHUD] Skill used: ", skill_id)

func _get_vehicle_health() -> float:
	if GameManager and GameManager.has_method("get_vehicle_health"):
		return GameManager.get_vehicle_health()
	return _current_health

func _get_coins() -> int:
	if EconomySystem and EconomySystem.has_method("get_coins"):
		return EconomySystem.get_coins()
	return _coins

func _get_proficiency() -> float:
	if ProgressionSystem and ProgressionSystem.has_method("get_proficiency"):
		return ProgressionSystem.get_proficiency()
	return _current_proficiency

func _get_current_level() -> int:
	if ProgressionSystem and ProgressionSystem.has_method("get_current_level"):
		return ProgressionSystem.get_current_level()
	return _current_level

func _play_damage_feedback() -> void:
	if _current_health / _max_health <= 0.3:
		modulate = Color(1.0, 0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func update_health(health: float, max_health: float) -> void:
	_current_health = health
	_max_health = max_health
	_update_health_bar()

func update_energy(energy: float, max_energy: float) -> void:
	_current_energy = energy
	_max_energy = max_energy
	_update_energy_bar()

func update_stamina(stamina: float, max_stamina: float) -> void:
	_current_stamina = stamina
	_max_stamina = max_stamina
	_update_stamina_display()

func update_coins(coins: int) -> void:
	_coins = coins
	if coin_label:
		coin_label.text = str(coins)

func update_progression(level: int, proficiency: float) -> void:
	_current_level = level
	_current_proficiency = proficiency
	
	if level_label:
		level_label.text = "Lv.%d" % level
	
	if proficiency_bar:
		proficiency_bar.value = proficiency * 100

func update_segment_progress(current: int, total: int) -> void:
	if segment_progress:
		segment_progress.max_value = total
		segment_progress.value = current
	
	if segment_label:
		segment_label.text = "%d / %d" % [current, total]

func update_chase_distance(distance: float) -> void:
	_current_chase_distance = distance
	_update_chase_indicator()

func _update_health_bar() -> void:
	if health_bar:
		var percent = _current_health / _max_health if _max_health > 0 else 0
		health_bar.value = percent * 100
		
		if percent <= 0.3:
			health_bar.add_theme_color_override("fg_color", Color.RED)
			health_bar.add_theme_color_override("fg_color", Color.YELLOW)
		elif percent <= 0.6:
			health_bar.add_theme_color_override("fg_color", Color.YELLOW)
		else:
			health_bar.add_theme_color_override("fg_color", Color.GREEN)

func _update_energy_bar() -> void:
	if energy_bar:
		var percent = _current_energy / _max_energy if _max_energy > 0 else 0
		energy_bar.value = percent * 100

func _update_stamina_display() -> void:
	var filled_icons = int(_current_stamina / _max_stamina * STAMINA_ICON_COUNT)
	filled_icons = clamp(filled_icons, 0, STAMINA_ICON_COUNT)
	
	for i in range(STAMINA_ICON_COUNT):
		if i < _stamina_icons.size():
			var icon = _stamina_icons[i]
			icon.modulate = Color.WHITE if i < filled_icons else Color.GRAY

func _update_chase_indicator() -> void:
	if not chase_arrow or not chase_distance_label:
		return
	
	chase_distance_label.text = "%.0f" % _current_chase_distance
	
	if _current_chase_distance <= 20.0:
		chase_arrow.modulate = Color.RED
		chase_distance_label.add_theme_color_override("font_color", Color.RED)
	elif _current_chase_distance <= 50.0:
		chase_arrow.modulate = Color.YELLOW
		chase_distance_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		chase_arrow.modulate = Color.GREEN
		chase_distance_label.add_theme_color_override("font_color", Color.GREEN)

func _show_repair_overlay(progress: float) -> void:
	if repair_overlay:
		repair_overlay.visible = true
	
	if repair_progress:
		repair_progress.value = progress * 100
	
	if repair_label:
		repair_label.text = "修车中... %.0f%%" % (progress * 100)

func _hide_repair_overlay() -> void:
	if repair_overlay:
		repair_overlay.visible = false

func show_game_over_screen(victory: bool) -> void:
	hide_hud()

func hide_hud() -> void:
	visible = false

func show_hud() -> void:
	visible = true
