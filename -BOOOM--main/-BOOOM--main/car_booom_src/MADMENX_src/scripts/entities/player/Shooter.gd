## Shooter — 射击手
##
## 功能说明：
## - 负责控制射击
## - 管理武器、弹药、瞄准
##
## 对接注意事项：
## - 输入通过 InputManager 获取
## - 射击通过 WeaponSystem
## - 被 VehicleController 管理
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name Shooter
extends PlayerBase

@export var aim_sensitivity: float = 1.0
@export var max_aim_angle: float = 135.0

var _current_weapon: Node = null
var _weapon_list: Array = []
var _current_weapon_index: int = 0

var _aim_direction: Vector2 = Vector2.UP
var _is_firing: bool = false
var _is_reloading: bool = false

var _ammo_in_magazine: int = 0
var _ammo_reserve: int = 0
var _total_reserve_ammo: int = 0

var _is_shield_deployed: bool = false
var _shield_node: Node = null

# ===== 接口定义 =====
## fire(direction: Vector2) -> void
##   射击
##
## reload() -> bool
##   换弹
##
## switch_weapon(index: int) -> void
##   切换武器
##
## get_ammo_in_magazine() -> int
##   获取弹夹弹药数
##
## deploy_shield() -> void
##   展开护盾
##
## retract_shield() -> void
##   收回护盾
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	_initialize_weapons()

func _process_input(delta: float) -> void:
	if not _input_enabled:
		return
	
	var input_data = InputManager.get_shooter_input()
	
	_update_aim(input_data.aim_direction)
	_update_firing(input_data.is_firing)
	
	if input_data.is_reloading and not _is_reloading:
		reload()

func _update_aim(aim_vec: Vector2) -> void:
	if aim_vec.length() > 0.1:
		_aim_direction = aim_vec.normalized()

func _update_firing(is_firing: bool) -> void:
	if is_firing and not _is_firing and not _is_reloading:
		_is_firing = true
		if _current_weapon:
			_current_weapon.fire(_aim_direction)
	elif not is_firing:
		_is_firing = false

func _initialize_weapons() -> void:
	print("[Shooter] Initializing weapons")

func fire(direction: Vector2) -> void:
	if _is_reloading:
		return
	
	if _ammo_in_magazine > 0 and _current_weapon:
		_current_weapon.fire(direction)
		_ammo_in_magazine -= 1
	else:
		reload()

func reload() -> bool:
	if _is_reloading:
		return false
	
	if _ammo_reserve > 0 and _ammo_in_magazine < get_magazine_size():
		_is_reloading = true
		var reload_time = _current_weapon.reload_time if _current_weapon else 1.5
		await get_tree().create_timer(reload_time).timeout
		_complete_reload()
		return true
	return false

func _complete_reload() -> void:
	var needed = get_magazine_size() - _ammo_in_magazine
	var available = min(needed, _ammo_reserve)
	_ammo_in_magazine += available
	_ammo_reserve -= available
	_is_reloading = false
	EventBus.weapon_reloaded.emit("current_weapon")

func get_ammo_in_magazine() -> int:
	return _ammo_in_magazine

func get_magazine_size() -> int:
	if _current_weapon:
		return _current_weapon.magazine_size
	return 6

func switch_weapon(index: int) -> void:
	if index >= 0 and index < _weapon_list.size():
		_current_weapon_index = index
		_current_weapon = _weapon_list[index]
		EventBus.weapon_fired.emit("weapon_switched")

func deploy_shield() -> void:
	if not _is_shield_deployed:
		_is_shield_deployed = true
		print("[Shooter] Shield deployed")

func retract_shield() -> void:
	if _is_shield_deployed:
		_is_shield_deployed = false
		print("[Shooter] Shield retracted")
