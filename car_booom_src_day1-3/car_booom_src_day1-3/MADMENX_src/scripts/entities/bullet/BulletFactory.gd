## BulletFactory — 子弹工厂
##
## 功能说明：
## - 子弹创建的统一入口
## - 弹药类型（JSON ammo_*）与配件系数由池言いく侧传入 options / set_player_loadout 对接
##
## 对接注意事项：
## - Shooter 默认不调弹药接口时走 ammo_standard
## - EventBus.ammo_type_changed 可切换默认弹药（键名可为 ammo_poison 或 poison）
##
## 创建人：长安旧梦
## 创建日期：2026-04-29
## 更新日期：2026-05-05

extends Node

var _bullet_scenes: Dictionary = {}

var _player_weapon_id: String = "pistol_basic"
var _player_ammo_key: String = "ammo_standard"
var _emp_combo_counter: int = 0

# ===== 接口定义 =====
## register_bullet_type(type_name: String, scene_path: String) -> void
## create_player_bullet(type_name, dir, dmg, pierce=0, spawn_pos=ZERO, options={}) -> BulletBase
## create_enemy_bullet(type_name, dir, dmg, spawn_pos=ZERO) -> BulletBase
## apply_ammo_effect(bullet: BulletBase, ammo_key: String, weapon_category: String, weapon_id: String) -> void
## set_player_loadout(weapon_id: String, ammo_key: String) -> void
## ===== 接口结束 =====

func _ready() -> void:
	_initialize_bullet_types()
	if EventBus.has_signal("ammo_type_changed"):
		EventBus.ammo_type_changed.connect(_on_ammo_type_changed)
	print("[BulletFactory] Initialized")


func _on_ammo_type_changed(ammo_id: String) -> void:
	_player_ammo_key = _normalize_ammo_key(ammo_id)


func set_player_loadout(weapon_id: String, ammo_key: String = "") -> void:
	_player_weapon_id = weapon_id
	if ammo_key != "":
		_player_ammo_key = _normalize_ammo_key(ammo_key)


func _normalize_ammo_key(key: String) -> String:
	if key.is_empty():
		return "ammo_standard"
	if key.begins_with("ammo_"):
		return key
	return "ammo_" + key


func _initialize_bullet_types() -> void:
	_bullet_scenes["player_basic"] = "res://scenes/entities/bullets/BulletPlayer.tscn"
	_bullet_scenes["enemy_basic"] = "res://scenes/entities/bullets/BulletEnemy.tscn"
	_bullet_scenes["enemy_homing"] = "res://scenes/entities/bullets/BulletEnemy.tscn"
	_bullet_scenes["enemy_laser"] = "res://scenes/entities/bullets/BulletEnemy.tscn"


func register_bullet_type(type_name: String, scene_path: String) -> void:
	_bullet_scenes[type_name] = scene_path


func create_player_bullet(type_name: String, dir: Vector2, dmg: float, pierce: int = 0, spawn_pos: Vector2 = Vector2.ZERO, options: Dictionary = {}) -> BulletBase:
	var pool_name := "Bullet_" + type_name
	var scene_path: String = _bullet_scenes.get(type_name, "res://scenes/entities/bullets/BulletPlayer.tscn")
	var bullet := ObjectPool.get_object(pool_name, scene_path) as BulletBase

	if bullet == null:
		return null

	var weapon_id: String = String(options.get("weapon_id", _player_weapon_id))
	var weapon_stats: Dictionary = ConfigMgr.get_weapon_stats(weapon_id)
	var weapon_category: String = String(weapon_stats.get("type", "pistol"))

	var ammo_opt: String = String(options.get("ammo_type", ""))
	var ammo_key: String = _normalize_ammo_key(ammo_opt if ammo_opt != "" else _player_ammo_key)

	var spd: float = _get_bullet_speed(type_name, weapon_stats, true)
	var pierce_total: int = pierce
	if weapon_stats.has("piercing"):
		pierce_total = maxi(pierce_total, int(weapon_stats.get("piercing", 0)))

	bullet.set_pool_name(pool_name)
	bullet.fire(dir, spd, dmg, 0, pierce_total, spawn_pos)
	bullet.name = "BulletPlayer_" + type_name

	var skip_fx: bool = bool(options.get("skip_submunition_clone", false))
	apply_ammo_effect(bullet, ammo_key, weapon_category, weapon_id, skip_fx)

	var dmg_mult_attach: float = float(options.get("damage_multiplier", 1.0))
	if dmg_mult_attach != 1.0:
		bullet.damage *= dmg_mult_attach

	if not skip_fx:
		_maybe_spawn_shotgun_submunitions(type_name, dir, pierce_total, spawn_pos, ammo_key, weapon_category, weapon_stats, weapon_id, options, bullet)

	return bullet


func _maybe_spawn_shotgun_submunitions(type_name: String, dir: Vector2, pierce: int, spawn_pos: Vector2, ammo_key: String, weapon_category: String, weapon_stats: Dictionary, weapon_id: String, options: Dictionary, bullet: BulletBase) -> void:
	if weapon_category != "shotgun" or bullet == null:
		return
	var astats: Dictionary = ConfigMgr.get_weapon_stats(ammo_key)
	var split_n: int = int(astats.get("shotgun_split_count", 0))
	if split_n <= 1:
		return
	var spread: float = float(weapon_stats.get("spread", 0.35))
	var base_a := dir.angle()
	var child_dmg: float = bullet.damage
	var skip_idx: int = int(round(float(split_n - 1) / 2.0))
	for k in split_n:
		if k == skip_idx:
			continue
		var ang_off: float = (float(k) - float(skip_idx)) * spread * 0.35
		var ndir := Vector2.from_angle(base_a + ang_off)
		var child_opts := options.duplicate()
		child_opts["skip_submunition_clone"] = true
		create_player_bullet(type_name, ndir, child_dmg, pierce, spawn_pos, child_opts)


func create_enemy_bullet(type_name: String, dir: Vector2, dmg: float, spawn_pos: Vector2 = Vector2.ZERO) -> BulletBase:
	var pool_name := "BulletEnemy_" + type_name
	var scene_path: String = _bullet_scenes.get(type_name, "res://scenes/entities/bullets/BulletEnemy.tscn")
	var bullet := ObjectPool.get_object(pool_name, scene_path) as BulletBase

	if bullet:
		var spd := _get_bullet_speed(type_name, {}, false)
		bullet.set_pool_name(pool_name)
		bullet.fire(dir, spd, dmg, 1, 0, spawn_pos)

	return bullet


func apply_ammo_effect(bullet: BulletBase, ammo_key: String, weapon_category: String, weapon_id: String, skip_recursive_fx: bool = false) -> void:
	if bullet == null:
		return
	var astats: Dictionary = ConfigMgr.get_weapon_stats(ammo_key)
	if astats.is_empty():
		astats = ConfigMgr.get_weapon_stats("ammo_standard")

	var allowed: Array = astats.get("allowed_weapon_types", []) as Array
	if allowed.size() > 0:
		var ok := false
		for a in allowed:
			if String(a) == weapon_category:
				ok = true
				break
		if not ok:
			return

	var dm: float = float(astats.get("damage_multiplier", 1.0))
	bullet.damage *= dm

	if weapon_category == "shotgun" and int(astats.get("shotgun_split_count", 0)) > 1:
		bullet.damage *= float(astats.get("shotgun_split_damage_scale", 0.3))

	var extra_pierce: int = int(astats.get("extra_pierce", 0))
	if extra_pierce > 0:
		bullet.piercing_count += extra_pierce

	bullet.speed_mult_after_pierce *= float(astats.get("speed_mult_after_pierce", 1.0))

	var ex_r: float = float(astats.get("explosion_radius", 0.0))
	if ex_r > 0.0:
		bullet.explosion_radius = ex_r
		bullet.explosion_damage_ratio = float(astats.get("explosion_damage_multiplier", 0.5))

	var p_pct: float = float(astats.get("poison_max_hp_percent_per_sec", 0.0))
	if p_pct > 0.0:
		bullet.poison_max_hp_pct = p_pct
		bullet.poison_duration = float(astats.get("poison_duration", 3.0))
		bullet.poison_stack_cap = int(astats.get("poison_max_stacks", 3))

	var emp_every: int = int(astats.get("emp_every_n_shots", 0))
	var emp_dur: float = float(astats.get("emp_duration", 0.0))
	if emp_every > 0 and emp_dur > 0.0:
		_emp_combo_counter += 1
		if _emp_combo_counter % emp_every == 0:
			bullet.emp_duration = emp_dur

	var split_delay: float = float(astats.get("smg_split_delay", -1.0))
	if not skip_recursive_fx and split_delay > 0.0 and weapon_category == "smg":
		var sc: int = int(astats.get("smg_split_count", 2))
		if sc > 0:
			bullet.submunition_split_delay = split_delay
			bullet.submunition_count = sc
			bullet.submunition_damage_scale = float(astats.get("smg_split_damage_scale", 1.0))
			bullet.submunition_angle_deg = float(astats.get("smg_split_angle_deg", 15.0))


func _get_bullet_speed(type_name: String, weapon_stats: Dictionary, is_player: bool) -> float:
	if weapon_stats.has("bullet_speed"):
		return float(weapon_stats.get("bullet_speed", 500.0))
	var base_speed := 400.0 if is_player else 300.0
	match type_name:
		"player_basic":
			return 500.0
		"enemy_basic":
			return 300.0
		"enemy_homing":
			return 250.0
		"enemy_laser":
			return 600.0
	return base_speed
