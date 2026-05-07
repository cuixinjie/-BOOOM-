## DriverHUD — 驾驶员HUD
##
## 功能说明：
## - 显示驾驶员相关数据（血量、速度、氮气、技能等）
##
## 创建人：cjs（主）、池言いく（扩展）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

extends Control

@onready var health_bar: ProgressBar = $VBox/HealthBar if has_node("VBox/HealthBar") else null
@onready var speed_label: Label = $VBox/SpeedLabel if has_node("VBox/SpeedLabel") else null
@onready var nitro_bar: ProgressBar = $VBox/NitroBar if has_node("VBox/NitroBar") else null
@onready var coin_label: Label = $VBox/CoinLabel if has_node("VBox/CoinLabel") else null
@onready var level_label: Label = $VBox/LevelLabel if has_node("VBox/LevelLabel") else null
@onready var prof_bar: ProgressBar = $VBox/ProfBar if has_node("VBox/ProfBar") else null
@onready var prof_label: Label = $VBox/ProfLabel if has_node("VBox/ProfLabel") else null

func _ready() -> void:
	_update_display()

func _process(_delta: float) -> void:
	_update_realtime()

func _update_display() -> void:
	if health_bar and GameManager:
		health_bar.max_value = GameManager.get_max_vehicle_health()
		health_bar.value = GameManager.get_vehicle_health()

func _update_realtime() -> void:
	if coin_label and has_node("/root"):
		var eco = get_node_or_null("/root/EconomySystem")
		if eco:
			coin_label.text = "Coins: %d" % eco.coins
	if level_label and has_node("/root"):
		var eco = get_node_or_null("/root/EconomySystem")
		if eco:
			level_label.text = "Lv.%d" % eco.current_level
	if speed_label and GameManager:
		speed_label.text = "Speed: %.0f" % GameManager.get_vehicle_speed()

func update_health_bar(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

func update_speed(speed: float) -> void:
	if speed_label:
		speed_label.text = "Speed: %.0f" % speed

func update_nitro(ratio: float) -> void:
	if nitro_bar:
		nitro_bar.value = ratio * 100.0

func update_coins(amount: int) -> void:
	if coin_label:
		coin_label.text = "Coins: %d" % amount

func update_energy(amount: float) -> void:
	pass

func update_level(level: int) -> void:
	if level_label:
		level_label.text = "Lv.%d" % level

## 更新当前武器熟练度进度（Day 5）
func update_proficiency_bar(weapon_type: String, proficiency: float, level: int, progress: float) -> void:
	if prof_bar:
		prof_bar.max_value = 100.0
		prof_bar.value = progress * 100.0
	if prof_label:
		# 获取武器类型中文名
		var type_name = _get_weapon_type_name(weapon_type)
		prof_label.text = "%s Lv.%d (%.0f%%)" % [type_name, level, progress * 100.0]

## 直接更新熟练度进度条（Day 4 - EconomySystem熟练度）
func update_economy_proficiency(proficiency: float, max_proficiency: float) -> void:
	if prof_bar:
		prof_bar.max_value = max_proficiency
		prof_bar.value = proficiency
	if prof_label:
		var percent = (proficiency / max_proficiency) * 100.0 if max_proficiency > 0 else 0.0
		prof_label.text = "熟练度 %.0f/%.0f (%.0f%%)" % [proficiency, max_proficiency, percent]

## 获取武器类型中文名
func _get_weapon_type_name(weapon_type: String) -> String:
	var names = {
		"pistol": "手枪",
		"smg": "冲锋枪",
		"shotgun": "霰弹枪",
		"rifle": "狙击枪",
		"laser": "激光枪"
	}
	return names.get(weapon_type, weapon_type)

func update_skill_cooldown(slot: int, progress: float) -> void:
	pass
