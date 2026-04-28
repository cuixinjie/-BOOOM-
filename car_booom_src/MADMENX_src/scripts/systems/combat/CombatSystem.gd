## CombatSystem — 战斗系统
##
## 功能说明：
## - 协调战斗相关功能
## - 管理武器、弹药、战斗流程
##
## 对接注意事项：
## - 被 LevelManager 调用
## - 依赖 WeaponSystem, AmmoSystem, DamageSystem
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name CombatSystem
extends Node

var _active_weapons: Dictionary = {}
var _ammo_types: Array = ["normal", "piercing", "explosive", "homing", "freeze", "poison"]

# ===== 接口定义 =====
## register_weapon(weapon_id: String, weapon: Node) -> void
##   注册武器
##
## fire_weapon(player_id: int, direction: Vector2) -> void
##   射击
##
## reload_weapon(player_id: int) -> bool
##   换弹
##
## switch_ammo_type(player_id: int, ammo_type: String) -> void
##   切换弹药类型
## ===== 接口结束 =====

func _ready() -> void:
	print("[CombatSystem] Initialized")

func register_weapon(weapon_id: String, weapon: Node) -> void:
	_active_weapons[weapon_id] = weapon
	print("[CombatSystem] Weapon registered: ", weapon_id)

func unregister_weapon(weapon_id: String) -> void:
	_active_weapons.erase(weapon_id)

func fire_weapon(player_id: int, direction: Vector2) -> void:
	var weapon = _get_weapon_for_player(player_id)
	if weapon and weapon.can_fire():
		weapon.fire(direction)

func reload_weapon(player_id: int) -> bool:
	var weapon = _get_weapon_for_player(player_id)
	if weapon:
		return weapon.reload()
	return false

func switch_ammo_type(player_id: int, ammo_type: String) -> void:
	if ammo_type in _ammo_types:
		EventBus.ammo_type_changed.emit(ammo_type)
		print("[CombatSystem] Ammo type switched to: ", ammo_type)

func _get_weapon_for_player(player_id: int) -> Node:
	return null

func get_all_ammo_types() -> Array:
	return _ammo_types
