## Shooter — 射击者角色
##
## 功能说明：
## - 玩家射击控制器
## - 负责武器切换、弹药管理、开火
##
## 对接注意事项：
## - 继承自 Entity 基类
## - 输入通过 EventBus.shooter_input_changed 接收
## - 子弹通过 BulletFactory 创建
##
## 创建人：长安旧梦
## 创建日期：2026-04-29
## 修复日期：2026-05-02

class_name Shooter
extends Entity

var current_ammo: int = 30
var max_ammo: int = 30
var ammo_reserve: int = 90
var fire_rate: float = 0.15
var _fire_timer: float = 0.0

var is_firing: bool = false
var aim_direction: Vector2 = Vector2.RIGHT

var current_weapon_id: String = "pistol_basic"
var weapon_stats: Dictionary = {}

var reload_speed: float = 2.0
var _is_reloading: bool = false
var _reload_timer: float = 0.0

func _ready() -> void:
	super._ready()
	player_role = PlayerRole.SHOOTER
	player_id = 2
	max_health = 80.0
	current_health = max_health
	move_speed = 150.0
	is_active = true
	is_dead = false
	is_invulnerable = false
	visible = true
	_is_player_entity = true
	set_process(true)
	set_physics_process(false)
	EventBus.shooter_input_changed.connect(_on_shooter_input_changed)
	_load_weapon_stats()

func _on_shooter_input_changed(data: Dictionary) -> void:
	_input_data = data

func _process(delta: float) -> void:
	if not is_active or is_dead:
		return
	if _fire_timer > 0:
		_fire_timer -= delta
	if _is_reloading:
		_update_reload(delta)
		return
	is_firing = _input_data.get("is_firing", false)
	aim_direction = _input_data.get("aim_direction", Vector2.RIGHT)
	if is_firing:
		fire()
	if _input_data.get("is_reloading", false):
		reload()

func _load_weapon_stats() -> void:
	weapon_stats = ConfigMgr.get_weapon_stats(current_weapon_id)
	if not weapon_stats.is_empty():
		fire_rate = weapon_stats.get("fire_rate", 0.15)
		max_ammo = weapon_stats.get("magazine_size", 30)
		current_ammo = max_ammo
		reload_speed = weapon_stats.get("reload_speed", 2.0)

func _update_reload(delta: float) -> void:
	_reload_timer -= delta
	if _reload_timer <= 0:
		_complete_reload()

func fire() -> void:
	if _fire_timer > 0 or current_ammo <= 0 or _is_reloading:
		return
	_fire_timer = fire_rate
	current_ammo -= 1
	var dir = aim_direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	BulletFactory.create_player_bullet(
		weapon_stats.get("bullet_type", "player_basic"),
		dir,
		weapon_stats.get("damage", 10.0),
		weapon_stats.get("piercing", 0),
		global_position
	)
	EventBus.weapon_fired.emit(current_weapon_id)
	AudioManager.play_shoot_sound(weapon_stats.get("sound_type", "basic"))
	if current_ammo <= 0:
		reload()

func reload() -> void:
	if _is_reloading or ammo_reserve <= 0:
		return
	_is_reloading = true
	_reload_timer = reload_speed
	AudioManager.play_sfx("reload")
	print("[Shooter] Reloading...")

func _complete_reload() -> void:
	_is_reloading = false
	var needed = max_ammo - current_ammo
	var to_reload = mini(needed, ammo_reserve)
	current_ammo += to_reload
	ammo_reserve -= to_reload
	EventBus.weapon_reloaded.emit(current_weapon_id)
	print("[Shooter] Reloaded! Ammo: ", current_ammo, "/", ammo_reserve)

func switch_weapon(weapon_id: String) -> void:
	if _is_reloading:
		return
	current_weapon_id = weapon_id
	weapon_stats = ConfigMgr.get_weapon_stats(weapon_id)
	if not weapon_stats.is_empty():
		max_ammo = weapon_stats.get("magazine_size", 30)
		current_ammo = mini(current_ammo, max_ammo)
		fire_rate = weapon_stats.get("fire_rate", 0.15)
		reload_speed = weapon_stats.get("reload_speed", 2.0)
	print("[Shooter] Switched to: ", weapon_id)

func aim_at(world_position: Vector2) -> void:
	aim_direction = (world_position - global_position).normalized()

func add_ammo(amount: int) -> void:
	ammo_reserve += amount
	print("[Shooter] Added ammo: ", amount, " | Reserve: ", ammo_reserve)

func get_ammo_ratio() -> float:
	return float(current_ammo) / float(max_ammo) if max_ammo > 0 else 0.0

func get_reload_progress() -> float:
	if not _is_reloading:
		return 0.0
	return 1.0 - (_reload_timer / reload_speed)

func is_player() -> bool:
	return true

func set_player_role(role: Entity.PlayerRole) -> void:
	player_role = role
	var role_name = "DRIVER" if role == 0 else "SHOOTER"
	print("[Shooter] Role set to: ", role_name)
