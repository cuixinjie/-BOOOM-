## Entity — 实体基类
##
## 功能说明：
## - 所有游戏实体的基类
## - 包含血量管理和玩家角色逻辑（已合并 LivingEntity 和 APlayerBase）
##
## 创建人：cjs（主）、长安旧梦（LivingEntity）、池言いく（PlayerBase）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

class_name Entity
extends Node2D

enum PlayerRole {
	DRIVER,
	SHOOTER
}

signal health_changed(current: float, maximum: float)
signal died(killer: Node)

var entity_id: String = ""
var entity_name: String = ""
var is_active: bool = true

var max_health: float = 100.0
var current_health: float = 100.0
var armor: float = 0.0
var elemental_resistances: Dictionary = {}

var is_dead: bool = false
var is_invulnerable: bool = false

var player_role: PlayerRole = PlayerRole.DRIVER
var player_id: int = 1

var move_speed: float = 200.0
var max_speed: float = 300.0

var current_weapon = null
var weapon_list: Array = []

var _input_data: Dictionary = {}
var shield_active: bool = false

var _is_player_entity: bool = false

# ===== 接口定义 =====
## activate() -> void
##   激活实体
##
## deactivate() -> void
##   停用实体
##
## get_entity_info() -> Dictionary
##   获取实体信息
##
## take_damage(amount: float, source: Node = null) -> void
##   承受伤害
##
## heal(amount: float) -> void
##   治疗
##
## get_health_ratio() -> float
##   获取血量百分比
##
## get_armor() -> float
##   获取护甲值
##
## is_in_invulnerable_state() -> bool
##   检查是否处于无敌状态
##
## is_player() -> bool
##   是否为玩家
## ===== 接口结束 =====

func _ready() -> void:
	_connect_event_signals()

func _connect_event_signals() -> void:
	if not EventBus.world_state_changed.is_connected(_on_world_state_changed):
		EventBus.world_state_changed.connect(_on_world_state_changed)

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	if to_state == 1:
		shield_active = not shield_active

func activate() -> void:
	is_active = true
	if is_instance_valid(self):
		visible = true
	set_process(true)
	set_physics_process(true)

func deactivate() -> void:
	is_active = false
	if is_instance_valid(self):
		visible = false
	set_process(false)
	set_physics_process(false)

func get_entity_info() -> Dictionary:
	return {
		"id": entity_id,
		"name": entity_name,
		"active": is_active
	}

func _to_string() -> String:
	return "[Entity: %s (%s)]" % [entity_name, entity_id]

func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or is_invulnerable:
		return

	var final_damage = max(0, amount - armor * 0.1)
	current_health = max(0, current_health - final_damage)

	health_changed.emit(current_health, max_health)
	if _is_player_entity:
		EventBus.player_damaged.emit(self, final_damage)
	else:
		EventBus.bullet_hit.emit(self, source, final_damage)

	if current_health <= 0:
		die(source)

func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func die(killer: Node = null) -> void:
	is_dead = true
	died.emit(killer)
	deactivate()
	print("[Entity] ", entity_name, " died")

func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return current_health / max_health

func get_armor() -> float:
	return armor

func is_in_invulnerable_state() -> bool:
	return is_invulnerable

func set_invulnerable(state: bool, duration: float = -1.0) -> void:
	is_invulnerable = state
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		is_invulnerable = false

func get_elemental_resistance(element: String) -> float:
	return elemental_resistances.get(element, 0.0)

func set_elemental_resistance(element: String, value: float) -> void:
	elemental_resistances[element] = clamp(value, 0.0, 1.0)

func set_input_data(data: Dictionary) -> void:
	_input_data = data

func equip_weapon(weapon) -> void:
	current_weapon = weapon
	weapon.weapon_owner = self

func is_player() -> bool:
	return true

func get_role_name() -> String:
	return "Driver" if player_role == PlayerRole.DRIVER else "Shooter"

func swap_role() -> void:
	player_role = PlayerRole.SHOOTER if player_role == PlayerRole.DRIVER else PlayerRole.DRIVER
	if EventBus.has_signal("role_swap_triggered"):
		EventBus.role_swap_triggered.emit(player_id, player_id)

func _process(delta: float) -> void:
	if not is_active:
		return
	_update_movement(delta)

func _update_movement(delta: float) -> void:
	pass
