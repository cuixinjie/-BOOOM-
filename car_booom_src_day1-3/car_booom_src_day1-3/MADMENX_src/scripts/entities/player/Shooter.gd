## Shooter — 射击者角色
##
## 功能说明：
## - 玩家射击控制器
## - 负责武器切换、弹药管理、开火
## - 配件效果应用（稳定器/炮口制退器/扩容弹匣/追踪模块）
## - 霰弹枪扇形散射（5发独立判定）
## - 狙击枪瞄准红线
##
## 对接注意事项：
## - 继承自 Entity 基类
## - 输入通过 EventBus.shooter_input_changed 接收
## - 子弹通过 BulletFactory 创建
## - 配件效果通过 EventBus.attachment_purchased 接收
##
## 创建人：长安旧梦
## 创建日期：2026-04-29
## 修复日期：2026-05-02
## Day 4完善：霰弹枪散射逻辑 + 狙击枪瞄准线（2026-05-06）

class_name Shooter
extends Entity

var current_ammo: int = 30
var max_ammo: int = 30
var base_max_ammo: int = 30  # 基础弹匣容量（不含配件加成）
var ammo_reserve: int = 90
var fire_rate: float = 0.15
var base_fire_rate: float = 0.15  # 基础射速
var _fire_timer: float = 0.0

var is_firing: bool = false
# 垂直追尾视角：默认向上瞄准（朝向敌人）
var aim_direction: Vector2 = Vector2.UP

var current_weapon_id: String = "pistol_basic"
var weapon_stats: Dictionary = {}

var reload_speed: float = 2.0
var _is_reloading: bool = false
var _reload_timer: float = 0.0

# ===== 配件效果加成 =====
var _accuracy_bonus: float = 0.0      # 精度加成（0.0-1.0）
var _recoil_reduction: float = 0.0    # 后坐力减少（0.0-1.0）
var _fire_rate_bonus: float = 0.0    # 射速加成（0.0-1.0）
var _magazine_size_bonus: float = 0.0 # 弹匣容量加成（0.0-1.0）
var _tracking_strength: float = 0.0   # 追踪强度（0.0-1.0）
var _hit_chance_bonus: float = 0.0    # 命中率加成（0.0-1.0）
var _installed_attachments: Dictionary = {}  # 已安装的配件

# ===== 狙击枪瞄准线 =====
var _aim_line: Line2D = null
var _is_sniper_aiming: bool = false
const SNIPER_AIM_LENGTH: float = 1500.0  # 瞄准线最大长度

## WeaponUpgradeSystem 引用（作为 Autoload 可直接访问）
var _weapon_upgrade_system: Node = null

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
	# 创建瞄准线节点
	_create_aim_line()
	EventBus.shooter_input_changed.connect(_on_shooter_input_changed)
	EventBus.weapon_switch_requested.connect(_on_weapon_switch_requested)
	EventBus.weapon_unlocked.connect(_on_weapon_unlocked)
	_connect_attachment_signals()
	_load_weapon_stats()
	_init_attachment_effects()
	# 初始化瞄准线状态
	_update_aim_line_visibility()
	# 初始化熟练度升级系统
	_init_proficiency_system()

func _connect_attachment_signals() -> void:
	if EventBus.has_signal("attachment_purchased"):
		EventBus.attachment_purchased.connect(_on_attachment_purchased)
	if EventBus.has_signal("attachment_installed"):
		EventBus.attachment_installed.connect(_on_attachment_installed)
	# 初始化已安装的配件
	_initialize_installed_attachments()

func _initialize_installed_attachments() -> void:
	if ShopSystem:
		_installed_attachments = ShopSystem.get_installed_attachments()
		_apply_all_attachment_effects()
		print("[Shooter] Initialized with attachments: ", _installed_attachments)

func _on_shooter_input_changed(data: Dictionary) -> void:
	_input_data = data

func _on_weapon_switch_requested(weapon_id: String) -> void:
	print("[Shooter] Switch requested to: ", weapon_id)
	switch_weapon(weapon_id)

func _on_weapon_unlocked(weapon_id: String) -> void:
	print("[Shooter] Weapon unlocked: ", weapon_id)

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
	# 更新狙击枪瞄准线
	_update_aim_line()
	if is_firing:
		fire()
	if _input_data.get("is_reloading", false):
		reload()

func _load_weapon_stats() -> void:
	weapon_stats = ConfigMgr.get_weapon_stats(current_weapon_id) if ConfigMgr else {}
	if not weapon_stats.is_empty():
		base_fire_rate = weapon_stats.get("fire_rate", 0.15)
		base_max_ammo = weapon_stats.get("magazine_size", 30)
		reload_speed = weapon_stats.get("reload_speed", 2.0)
		# 应用弹匣容量加成
		_apply_magazine_size_bonus()
		current_ammo = max_ammo
		# 应用射速加成
		_apply_fire_rate_bonus()

func _apply_magazine_size_bonus() -> void:
	max_ammo = int(float(base_max_ammo) * (1.0 + _magazine_size_bonus))
	print("[Shooter] Magazine size: ", base_max_ammo, " -> ", max_ammo, " (bonus: ", (_magazine_size_bonus * 100), "%)")

func _apply_fire_rate_bonus() -> void:
	# 射速加成：实际射速 = 基础射速 * (1 - 加成比例)
	fire_rate = base_fire_rate * (1.0 - _fire_rate_bonus)
	print("[Shooter] Fire rate: ", base_fire_rate, " -> ", fire_rate, " (bonus: ", (_fire_rate_bonus * 100), "%)")

func _update_reload(delta: float) -> void:
	_reload_timer -= delta
	if _reload_timer <= 0:
		_complete_reload()

func fire() -> void:
	if _fire_timer > 0 or current_ammo <= 0 or _is_reloading:
		return
	_fire_timer = fire_rate
	current_ammo -= 1
	# 垂直追尾视角：向上发射（朝向敌人）
	var dir = aim_direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP  # 默认向上发射
	
	# 检测是否为霰弹枪
	var weapon_type = weapon_stats.get("type", "")
	if weapon_type == "shotgun":
		_fire_shotgun(dir)
	else:
		_fire_normal_bullet(dir)
	
	EventBus.weapon_fired.emit(current_weapon_id)
	AudioManager.play_shoot_sound(weapon_stats.get("sound_type", "basic"))
	if current_ammo <= 0:
		reload()

## 霰弹枪扇形散射射击
func _fire_shotgun(dir: Vector2) -> void:
	var pellets = weapon_stats.get("pellets", 5)
	var spread_angle = weapon_stats.get("spread", 0.3)  # 散射角度（弧度）
	var damage = weapon_stats.get("damage", 8.0)
	var piercing = weapon_stats.get("piercing", 0)
	var bullet_type = weapon_stats.get("bullet_type", "player_basic")
	
	# 应用熟练度加成
	var final_damage = get_final_damage(damage)
	var final_pellets = get_pellet_count(pellets)
	var final_piercing = get_piercing_count(piercing)
	
	# 计算每发子弹的散射角度
	var angle_step = spread_angle / max(1, final_pellets - 1)  # 均匀分布
	var start_angle = -spread_angle / 2  # 从中心向左开始
	
	for i in range(final_pellets):
		var pellet_angle = start_angle + angle_step * i
		var pellet_dir = dir.rotated(pellet_angle)
		# 应用精度加成（对霰弹枪影响散布范围）
		var spread = _calculate_spread()
		pellet_dir = _apply_spread(pellet_dir, spread * 0.5)  # 霰弹枪精度加成减半散布
		
		# 构建配件追踪参数
		var bullet_extra_params = {
			"tracking_strength": _tracking_strength,
			"hit_chance_bonus": _hit_chance_bonus,
			"accuracy_bonus": _accuracy_bonus
		}
		
		BulletFactory.create_player_bullet_ex(
			bullet_type,
			pellet_dir,
			final_damage,
			final_piercing,
			global_position,
			bullet_extra_params
		)
	
	print("[Shooter] Shotgun fired: ", final_pellets, " pellets, damage=", final_damage)

## 普通子弹射击
func _fire_normal_bullet(dir: Vector2) -> void:
	var base_damage = weapon_stats.get("damage", 10.0)
	var base_piercing = weapon_stats.get("piercing", 0)
	
	# 应用熟练度加成
	var final_damage = get_final_damage(base_damage)
	var final_piercing = get_piercing_count(base_piercing)
	
	# 应用精度加成（散布角度）
	var spread = _calculate_spread()
	dir = _apply_spread(dir, spread)
	# 构建配件追踪参数
	var bullet_extra_params = {
		"tracking_strength": _tracking_strength,
		"hit_chance_bonus": _hit_chance_bonus,
		"accuracy_bonus": _accuracy_bonus
	}
	# 使用带配件效果的子弹创建方法
	BulletFactory.create_player_bullet_ex(
		weapon_stats.get("bullet_type", "player_basic"),
		dir,
		final_damage,
		final_piercing,
		global_position,
		bullet_extra_params
	)

func _calculate_spread() -> float:
	# 精度加成越高，散布越小（accuracy_bonus 范围 0-1）
	# 基础散布 0.1，加入 accuracy 减少散布
	return max(0.0, 0.15 * (1.0 - _accuracy_bonus))

func _apply_spread(dir: Vector2, spread: float) -> Vector2:
	# 应用散布
	var angle = randf_range(-spread, spread)
	return dir.rotated(angle)

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
	weapon_stats = ConfigMgr.get_weapon_stats(weapon_id) if ConfigMgr else {}
	if not weapon_stats.is_empty():
		base_max_ammo = weapon_stats.get("magazine_size", 30)
		base_fire_rate = weapon_stats.get("fire_rate", 0.15)
		reload_speed = weapon_stats.get("reload_speed", 2.0)
		# 切换武器时重新应用配件加成
		_apply_magazine_size_bonus()
		_apply_fire_rate_bonus()
		current_ammo = mini(current_ammo, max_ammo)
		# 更新瞄准线（狙击枪需要显示）
		_update_aim_line_visibility()
		# 更新熟练度效果
		var weapon_type = _get_weapon_type_from_id(weapon_id)
		if _weapon_upgrade_system:
			_weapon_upgrade_system.update_for_weapon_type(weapon_type)
	print("[Shooter] Switched to: ", weapon_id, " (ammo: ", current_ammo, "/", max_ammo, ")")

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

# ===== 配件效果应用（Day 5新增）=====

## 初始化配件效果
func _init_attachment_effects() -> void:
	_accuracy_bonus = 0.0
	_recoil_reduction = 0.0
	_fire_rate_bonus = 0.0
	_magazine_size_bonus = 0.0
	_tracking_strength = 0.0
	_hit_chance_bonus = 0.0
	print("[Shooter] Attachment effects initialized")

## 应用所有已安装配件的效果
func _apply_all_attachment_effects() -> void:
	if not ShopSystem:
		return
	var installed = ShopSystem.get_installed_attachments()
	for attachment_type in installed.keys():
		var _item_id = installed[attachment_type]
		var effect = ShopSystem.get_attachment_effect(attachment_type)
		_apply_single_attachment_effect(attachment_type, effect)
	print("[Shooter] Applied all attachment effects")

## 应用单个配件的效果
func _apply_single_attachment_effect(attachment_type: String, effect: Dictionary) -> void:
	if effect.is_empty():
		return

	match attachment_type:
		"stabilizer":
			var bonus = effect.get("accuracy_bonus", 0.0)
			if bonus > _accuracy_bonus:
				_accuracy_bonus = bonus
				print("[Shooter] Applied stabilizer: accuracy_bonus=", _accuracy_bonus)
			var recoil = effect.get("recoil_reduction", 0.0)
			if recoil > _recoil_reduction:
				_recoil_reduction = recoil
				print("[Shooter] Applied stabilizer: recoil_reduction=", _recoil_reduction)

		"muzzle_brake":
			var recoil = effect.get("recoil_reduction", 0.0)
			if recoil > _recoil_reduction:
				_recoil_reduction = recoil
				print("[Shooter] Applied muzzle_brake: recoil_reduction=", _recoil_reduction)
			var fire_rate_upgrade = effect.get("fire_rate_bonus", 0.0)
			if fire_rate_upgrade > _fire_rate_bonus:
				_fire_rate_bonus = fire_rate_upgrade
				_apply_fire_rate_bonus()
				print("[Shooter] Applied muzzle_brake: fire_rate_bonus=", _fire_rate_bonus)

		"extended_mag":
			var mag_bonus = effect.get("magazine_size_bonus", 0.0)
			if mag_bonus > _magazine_size_bonus:
				_magazine_size_bonus = mag_bonus
				_apply_magazine_size_bonus()
				print("[Shooter] Applied extended_mag: magazine_size_bonus=", _magazine_size_bonus)

		"tracking":
			var tracking = effect.get("tracking_strength", 0.0)
			if tracking > _tracking_strength:
				_tracking_strength = tracking
				print("[Shooter] Applied tracking: tracking_strength=", _tracking_strength)
			var hit_chance = effect.get("hit_chance_bonus", 0.0)
			if hit_chance > _hit_chance_bonus:
				_hit_chance_bonus = hit_chance
				print("[Shooter] Applied tracking: hit_chance_bonus=", _hit_chance_bonus)

## 配件购买/安装回调
func _on_attachment_purchased(p_item_id: String, effect: Dictionary) -> void:
	if ShopSystem:
		var item_data = ShopSystem.get_item_data(p_item_id)
		var attachment_type = item_data.get("attachment_type", "")
		_apply_single_attachment_effect(attachment_type, effect)
		_installed_attachments[attachment_type] = p_item_id
		# 切换武器时重新应用加成（保持加成一致）
		_apply_magazine_size_bonus()
		_apply_fire_rate_bonus()
	print("[Shooter] Attachment purchased: ", p_item_id, " effect: ", effect)

## 配件安装回调
func _on_attachment_installed(attachment_type: String, item_id: String) -> void:
	if ShopSystem:
		var effect = ShopSystem.get_attachment_effect(attachment_type)
		_apply_single_attachment_effect(attachment_type, effect)
		_installed_attachments[attachment_type] = item_id
		_apply_magazine_size_bonus()
		_apply_fire_rate_bonus()
	print("[Shooter] Attachment installed: ", attachment_type, " (", item_id, ")")

# ===== 狙击枪瞄准线功能（Day 4）=====

## 创建瞄准线节点
func _create_aim_line() -> void:
	_aim_line = Line2D.new()
	_aim_line.name = "AimLine"
	_aim_line.width = 2.0
	_aim_line.default_color = Color(1.0, 0.2, 0.2, 0.8)  # 红色半透明
	_aim_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_aim_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	# 设置瞄准线点（初始为空）
	_aim_line.clear_points()
	_aim_line.visible = false
	add_child(_aim_line)

## 更新瞄准线可见性
func _update_aim_line_visibility() -> void:
	var weapon_type = weapon_stats.get("type", "")
	_is_sniper_aiming = (weapon_type == "rifle")
	if _aim_line:
		_aim_line.visible = _is_sniper_aiming
		if _is_sniper_aiming:
			# 设置红色虚线效果
			_aim_line.width = 2.0
			_aim_line.default_color = Color(1.0, 0.2, 0.2, 0.8)
		print("[Shooter] Aim line visibility updated: sniper=", _is_sniper_aiming)

## 更新瞄准线位置和方向
func _update_aim_line() -> void:
	if not _aim_line or not is_instance_valid(_aim_line):
		return

	var weapon_type = weapon_stats.get("type", "")

	if weapon_type != "rifle":
		# 非狙击枪，隐藏瞄准线
		if _aim_line.visible:
			_aim_line.visible = false
		return

	# 狙击枪模式
	if not _aim_line.visible:
		_aim_line.visible = true

	# 垂直追尾视角：计算瞄准线终点（沿瞄准方向向上）
	var aim_dir = aim_direction.normalized()
	if aim_dir == Vector2.ZERO:
		aim_dir = Vector2.UP  # 默认向上瞄准

	# 获取射程
	var max_range = weapon_stats.get("range", SNIPER_AIM_LENGTH)
	var end_pos = aim_dir * max_range

	# 更新瞄准线
	_aim_line.clear_points()
	_aim_line.add_point(Vector2.ZERO)  # 从枪口位置开始
	_aim_line.add_point(end_pos)

	# 瞄准线跟随射击者位置
	_aim_line.global_position = global_position
	_aim_line.rotation = aim_dir.angle()

## 获取当前是否为狙击枪模式
func is_sniper_mode() -> bool:
	return _is_sniper_aiming

## 获取当前武器类型（供WeaponProficiencySystem调用）
func _get_current_weapon_type() -> String:
	return weapon_stats.get("type", "pistol")

# ===== 武器熟练度系统集成（Day 5）=====

## 熟练度加成变量
var _prof_damage_bonus: float = 0.0
var _prof_fire_rate_bonus: float = 0.0
var _prof_accuracy_bonus: float = 0.0
var _prof_spread_reduction: float = 0.0
var _prof_pellet_bonus: int = 0
var _prof_piercing_bonus: int = 0

## 连接熟练度信号
func _init_proficiency_system() -> void:
	if EventBus.has_signal("weapon_proficiency_level_up"):
		EventBus.weapon_proficiency_level_up.connect(_on_weapon_proficiency_level_up)
	if EventBus.has_signal("weapon_proficiency_changed"):
		EventBus.weapon_proficiency_changed.connect(_on_weapon_proficiency_changed)
	# 初始化WeaponUpgradeSystem引用
	_weapon_upgrade_system = get_node_or_null("/root/WeaponUpgradeSystem")
	if _weapon_upgrade_system:
		_weapon_upgrade_system.initialize(self)
		# 根据当前武器应用熟练度效果
		var weapon_type = _get_weapon_type_from_id(current_weapon_id)
		_weapon_upgrade_system.update_for_weapon_type(weapon_type)
		print("[Shooter] WeaponUpgradeSystem initialized")
	else:
		print("[Shooter] Warning: WeaponUpgradeSystem not found")
	print("[Shooter] Proficiency system initialized")

## 获取武器类型
func _get_weapon_type_from_id(weapon_id: String) -> String:
	var stats = ConfigMgr.get_weapon_stats(weapon_id) if ConfigMgr else {}
	return stats.get("type", "pistol")

## 武器熟练度升级回调
func _on_weapon_proficiency_level_up(_weapon_type_arg: String, _new_level: int, _effects: Dictionary) -> void:
	print("[Shooter] Proficiency level up for current weapon")
	# 刷新熟练度效果
	_apply_fire_rate_bonus()

## 武器熟练度变化回调
func _on_weapon_proficiency_changed(_weapon_type_arg: String, _proficiency: float, _level: int) -> void:
	pass

## 应用熟练度升级效果
func apply_proficiency_effect(
	_weapon_type: String,
	damage_bonus: float,
	fire_rate_bonus: float,
	accuracy_bonus: float,
	spread_reduction: float,
	pellet_bonus: int,
	piercing_bonus: int
) -> void:
	_prof_damage_bonus = damage_bonus
	_prof_fire_rate_bonus = fire_rate_bonus
	_prof_accuracy_bonus = accuracy_bonus
	_prof_spread_reduction = spread_reduction
	_prof_pellet_bonus = pellet_bonus
	_prof_piercing_bonus = piercing_bonus
	
	# 重新应用弹匣和射速加成
	_apply_magazine_size_bonus()
	_apply_fire_rate_bonus()
	
	print("[Shooter] Applied proficiency effects: damage=", _prof_damage_bonus, " fire_rate=", _prof_fire_rate_bonus)

## 获取熟练度伤害加成
func get_proficiency_damage_bonus() -> float:
	return _prof_damage_bonus

## 获取最终伤害（基础伤害 + 熟练度加成）
func get_final_damage(base_damage: float) -> float:
	return base_damage * (1.0 + _prof_damage_bonus)

## 获取弹丸数（霰弹枪）
func get_pellet_count(base_pellets: int) -> int:
	return base_pellets + _prof_pellet_bonus

## 获取穿透数（狙击枪）
func get_piercing_count(base_piercing: int) -> int:
	return base_piercing + _prof_piercing_bonus

## 重置熟练度加成
func reset_proficiency_effects() -> void:
	_prof_damage_bonus = 0.0
	_prof_fire_rate_bonus = 0.0
	_prof_accuracy_bonus = 0.0
	_prof_spread_reduction = 0.0
	_prof_pellet_bonus = 0
	_prof_piercing_bonus = 0
	print("[Shooter] Proficiency effects reset")
