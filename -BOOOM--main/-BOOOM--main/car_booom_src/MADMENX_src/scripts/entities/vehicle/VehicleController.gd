## VehicleController — 载具控制器
##
## 功能说明：
## - 控制机车整体行为
## - 管理驾驶员和射击手
## - 处理机车受伤和技能
##
## 对接注意事项：
## - 被 Driver 和 Shooter 使用
## - 机车状态通过 EventBus 广播
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name VehicleController
extends LivingEntity

@export var driver_scene: PackedScene
@export var shooter_scene: PackedScene

var _driver: Node = null
var _shooter: Node = null

var _base_speed: float = 200.0
var _current_speed: float = 200.0
var _sprint_speed: float = 350.0

var _is_sprinting: bool = false
var _stamina: float = 100.0
var _max_stamina: float = 100.0

# ===== 接口定义 =====
## get_driver() -> Node
##   获取驾驶员
##
## get_shooter() -> Node
##   获取射击手
##
## get_current_speed() -> float
##   获取当前速度
##
## set_speed(speed: float) -> void
##   设置速度
##
## sprint(active: bool) -> void
##   冲刺
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	add_to_group("vehicle")
	max_health = ConfigManager.get_game_config("vehicle").get("max_health", 100.0)
	current_health = max_health
	_initialize_players()

func _initialize_players() -> void:
	if driver_scene:
		_driver = driver_scene.instantiate()
		_driver.player_id = 1
		add_child(_driver)
	
	if shooter_scene:
		_shooter = shooter_scene.instantiate()
		_shooter.player_id = 2
		add_child(_shooter)

func _process(delta: float) -> void:
	super._process(delta)
	_update_stamina(delta)

func _update_stamina(delta: float) -> void:
	if _is_sprinting:
		_stamina -= 30.0 * delta
		if _stamina <= 0:
			_stamina = 0
			sprint(false)
	else:
		_stamina = min(_max_stamina, _stamina + 15.0 * delta)

func _take_damage(amount: float, damage_info) -> void:
	super._take_damage(amount, damage_info)
	GameManager.damage_vehicle(amount)

func get_driver() -> Node:
	return _driver

func get_shooter() -> Node:
	return _shooter

func get_current_speed() -> float:
	return _current_speed

func set_speed(speed: float) -> void:
	_current_speed = speed

func sprint(active: bool) -> void:
	if active and _stamina > 0:
		_is_sprinting = true
		_current_speed = _sprint_speed
	else:
		_is_sprinting = false
		_current_speed = _base_speed

func get_stamina() -> float:
	return _stamina

func get_max_stamina() -> float:
	return _max_stamina
