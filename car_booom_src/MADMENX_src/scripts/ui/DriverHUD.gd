## DriverHUD — 驾驶员HUD
##
## 功能说明：
## - 显示驾驶员相关信息
## - 血量、能量、耐力、追兵距离
##
## 对接注意事项：
## - 被 HUDController 管理
## - 数据通过 EventBus 更新
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name DriverHUD
extends Control

@onready var health_bar: Node = $VBox/HealthContainer/HealthBar
@onready var energy_bar: Node = $VBox/EnergyContainer/EnergyBar
@onready var stamina_bar: Node = $VBox/StaminaContainer/StaminaBar
@onready var coin_label: Label = $VBox/CoinContainer/CoinLabel
@onready var chase_indicator: Node = $ChaseIndicator
@onready var skill_indicators: Node = $SkillIndicators

var _current_health: float = 100.0
var _max_health: float = 100.0
var _current_energy: float = 100.0
var _max_energy: float = 100.0
var _current_stamina: float = 100.0
var _max_stamina: float = 100.0

func _ready() -> void:
	_connect_signals()
	print("[DriverHUD] Initialized")

func _connect_signals() -> void:
	EventBus.vehicle_damaged.connect(_on_vehicle_damaged)
	EventBus.vehicle_repaired.connect(_on_vehicle_repaired)
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.chase_distance_changed.connect(_on_chase_distance_changed)

func _on_vehicle_damaged(damage: float) -> void:
	_ current_health = GameManager.get_vehicle_health()
	_update_health_bar()

func _on_vehicle_repaired(amount: float) -> void:
	_current_health = GameManager.get_vehicle_health()
	_update_health_bar()

func _on_coin_collected(amount: int) -> void:
	update_coins(GameManager.get_coins())

func _on_chase_distance_changed(distance: float) -> void:
	if chase_indicator:
		chase_indicator.update_distance(distance)

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
	_update_stamina_bar()

func update_coins(coins: int) -> void:
	if coin_label:
		coin_label.text = str(coins)

func _update_health_bar() -> void:
	if health_bar:
		var percent = _current_health / _max_health if _max_health > 0 else 0
		health_bar.value = percent * 100

func _update_energy_bar() -> void:
	if energy_bar:
		var percent = _current_energy / _max_energy if _max_energy > 0 else 0
		energy_bar.value = percent * 100

func _update_stamina_bar() -> void:
	if stamina_bar:
		var percent = _current_stamina / _max_stamina if _max_stamina > 0 else 0
		stamina_bar.value = percent * 100
