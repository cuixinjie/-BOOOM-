## WeaponBase — 武器基类
##
## 功能说明：
## - 所有武器的基类
## - 管理射击、换弹、弹药
##
## 对接注意事项：
## - 被具体武器类继承
## - 射击通过 BulletFactory 创建子弹
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name WeaponBase
extends Node

@export var weapon_id: String = "pistol"
@export var weapon_name: String = "手枪"

@export var damage: float = 10.0
@export var fire_rate: float = 2.5
@export var magazine_size: int = 6
@export var reload_time: float = 1.5
@export var spread: float = 0.05
@export var bullet_speed: float = 800.0

var _ammo_in_magazine: int = 0
var _is_reloading: bool = false
var _fire_cooldown: float = 0.0
var _owner: Node = null

var _bullet_factory: Node = null

# ===== 接口定义 =====
## fire(direction: Vector2) -> void
##   射击
##
## reload() -> void
##   换弹
##
## can_fire() -> bool
##   是否可以射击
##
## get_ammo_status() -> Dictionary
##   获取弹药状态
## ===== 接口结束 =====

func _ready() -> void:
	_load_weapon_stats()
	_ammo_in_magazine = magazine_size
	_bullet_factory = get_node("/root/BulletFactory")
	if not _bullet_factory:
		_bullet_factory = BulletFactory.new()
		add_child(_bullet_factory)

func _load_weapon_stats() -> void:
	var stats = ConfigManager.get_weapon_stats(weapon_id)
	if stats:
		damage = stats.get("damage", damage)
		fire_rate = stats.get("fire_rate", fire_rate)
		magazine_size = stats.get("magazine_size", magazine_size)
		reload_time = stats.get("reload_time", reload_time)
		spread = stats.get("spread", spread)
		bullet_speed = stats.get("bullet_speed", bullet_speed)

func _process(delta: float) -> void:
	if _fire_cooldown > 0:
		_fire_cooldown -= delta

func fire(direction: Vector2) -> void:
	if not can_fire():
		return
	
	if _is_reloading:
		return
	
	_fire_cooldown = 1.0 / fire_rate
	
	_apply_spread(direction)
	_create_bullet(direction)
	_ammo_in_magazine -= 1
	
	EventBus.weapon_fired.emit(weapon_id)
	
	if _ammo_in_magazine <= 0:
		reload()

func _apply_spread(direction: Vector2) -> Vector2:
	var spread_rad = deg_to_rad(spread * 100)
	return direction.rotated(randf_range(-spread_rad, spread_rad))

func _create_bullet(direction: Vector2) -> void:
	if _bullet_factory and _owner:
		var position = _owner.global_position + direction * 50
		_bullet_factory.create_player_bullet(self, position, direction, "normal")

func reload() -> void:
	if _is_reloading:
		return
	
	_is_reloading = true
	EventBus.weapon_reloaded.emit(weapon_id)
	
	var tween = create_tween()
	tween.tween_interval(reload_time)
	await tween.finished
	
	_ammo_in_magazine = magazine_size
	_is_reloading = false
	print("[WeaponBase] Reload complete")

func can_fire() -> bool:
	return _fire_cooldown <= 0 and _ammo_in_magazine > 0 and not _is_reloading

func get_ammo_status() -> Dictionary:
	return {
		"current": _ammo_in_magazine,
		"max": magazine_size,
		"is_reloading": _is_reloading
	}

func set_owner(owner: Node) -> void:
	_owner = owner

func get_owner() -> Node:
	return _owner
