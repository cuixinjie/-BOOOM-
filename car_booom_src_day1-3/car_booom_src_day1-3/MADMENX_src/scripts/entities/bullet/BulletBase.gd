## BulletBase — 子弹基类
##
## 功能说明：
## - 所有子弹的基类
## - 处理移动、碰撞、效果
## - EMP期间敌人弹幕减速50%（Day 4完善）
## - 支持玩家子弹追踪效果（Day 5完善）
##
## 对接注意事项：
## - 子弹通过 ObjectPool 管理
## - 命中通过 EventBus.bullet_hit 广播
## - EMP信号由 SpecialSegmentManager 触发
## - 追踪效果通过 set_tracking() 和 set_hit_chance_bonus() 设置
##
## 创建人：长安旧梦（主）、cjs（扩展）
## 创建日期：2026-04-29
## 合并日期：2026-05-02
## Day 4完善：EMP敌人弹幕减速逻辑（由新街实现）
## Day 5完善：玩家子弹追踪效果接入

class_name BulletBase
extends Area2D

signal bullet_hit_target(target: Node)
signal bullet_expired()

var bullet_owner: int = 0  # 0=PLAYER, 1=ENEMY, 2=ENVIRONMENT
var bullet_speed: float = 400.0
var damage: float = 10.0
var damage_type: String = "physical"
var bullet_direction: Vector2 = Vector2.RIGHT
var is_active: bool = false

var max_range: float = 1000.0
var distance_traveled: float = 0.0

var lifetime: float = 5.0
var lifetime_timer: float = 0.0

var _pool_name: String = ""

# EMP状态追踪（敌人弹幕减速）
var _is_emp_slowed: bool = false
var _base_speed: float = 400.0
var _current_speed_multiplier: float = 1.0

# 可被穿透子弹覆盖
var piercing_count: int = 0
var current_pierce: int = 0
var collision_radius: float = 8.0
var _collision_hit_targets: Array = []

# ===== 追踪效果参数（Day 5新增）=====
var _tracking_strength: float = 0.0    # 追踪强度 0.0-1.0
var _hit_chance_bonus: float = 0.0     # 命中率加成 0.0-1.0
var _has_tracking_target: bool = false
var _tracking_target: Node = null
var _tracking_cooldown: float = 0.0   # 追踪冷却时间
var _tracking_interval: float = 0.1    # 追踪更新间隔

# ===== 接口定义 =====
## fire(dir: Vector2, spd: float, dmg: float, owner: int, pierce: int = 0) -> void
##   发射子弹（可选穿透参数）
##
## on_spawned() -> void
##   对象从池中取出时的回调
##
## on_despawned() -> void
##   对象归还池中的回调
## ===== 接口结束 =====

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_connect_emp_signals()

func _connect_emp_signals() -> void:
	if not EventBus.emp_activated.is_connected(_on_emp_activated):
		EventBus.emp_activated.connect(_on_emp_activated)
	if not EventBus.emp_deactivated.is_connected(_on_emp_deactivated):
		EventBus.emp_deactivated.connect(_on_emp_deactivated)

func _on_emp_activated() -> void:
	# 只有敌人弹幕在EMP期间减速
	if bullet_owner == 1:
		_is_emp_slowed = true
		_current_speed_multiplier = 0.5
		bullet_speed = _base_speed * _current_speed_multiplier

func _on_emp_deactivated() -> void:
	_is_emp_slowed = false
	_current_speed_multiplier = 1.0
	bullet_speed = _base_speed

func _process(delta: float) -> void:
	if not is_active:
		return

	# 更新追踪冷却
	if _tracking_cooldown > 0:
		_tracking_cooldown -= delta

	# 执行追踪（仅对玩家子弹且有追踪效果时）
	if _tracking_strength > 0:
		_update_tracking(delta)

	var movement = bullet_direction * bullet_speed * delta
	global_position += movement
	distance_traveled += movement.length()

	# 手动碰撞检测：检测附近的敌人
	_check_manual_collision()

	if lifetime_timer > 0:
		lifetime_timer -= delta
		if lifetime_timer <= 0:
			expire()

	if max_range > 0 and distance_traveled >= max_range:
		expire()

func _update_tracking(_delta: float) -> void:
	# 查找最近的敌人目标
	if not _has_tracking_target or not is_instance_valid(_tracking_target):
		_tracking_target = _find_nearest_enemy()
		_has_tracking_target = _tracking_target != null

	if _has_tracking_target and _tracking_target != null:
		# 按追踪间隔更新方向
		if _tracking_cooldown <= 0:
			_tracking_cooldown = _tracking_interval
			var target_dir = (_tracking_target.global_position - global_position).normalized()
			# 根据追踪强度混合方向（强度越高，越快转向目标）
			var track_factor = _tracking_strength * 0.5  # 最大50%混合
			bullet_direction = bullet_direction.lerp(target_dir, track_factor).normalized()
			rotation = bullet_direction.angle()

func _find_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var nearest_dist = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dead_val = enemy.get("is_dead")
		if dead_val == true:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		# 追踪范围限制（最大300像素内）
		if dist < 300 and dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest

func fire(dir: Vector2, spd: float, dmg: float, blt_owner: int = 0, pierce: int = 0, spawn_pos: Vector2 = Vector2.ZERO) -> void:
	bullet_direction = dir.normalized()
	_base_speed = spd
	# 如果在EMP期间且是敌人子弹，使用减速速度
	if bullet_owner == 1 and _is_emp_slowed:
		bullet_speed = spd * _current_speed_multiplier
	else:
		bullet_speed = spd
	damage = dmg
	bullet_owner = blt_owner
	is_active = true
	lifetime_timer = lifetime
	distance_traveled = 0.0
	visible = true
	if spawn_pos != Vector2.ZERO:
		global_position = spawn_pos
	set_process(true)

	# 穿透相关
	if pierce > 0:
		piercing_count = pierce
		current_pierce = 0

	_collision_hit_targets.clear()

func set_pool_name(pool_name: String) -> void:
	_pool_name = pool_name

func on_spawned() -> void:
	is_active = false
	lifetime_timer = 0.0
	distance_traveled = 0.0
	visible = false
	set_process(false)
	current_pierce = 0
	_collision_hit_targets.clear()
	# 重置EMP状态（子弹被回收时可能EMP已结束）
	_is_emp_slowed = false
	_current_speed_multiplier = 1.0
	# 重置追踪状态（Day 5新增）
	_tracking_strength = 0.0
	_hit_chance_bonus = 0.0
	_has_tracking_target = false
	_tracking_target = null
	_tracking_cooldown = 0.0
	# 重置弹药效果（Day 6新增）
	reset_ammo_effects()

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return

	# 关键修复：检查 area 是否有效
	if not is_instance_valid(area):
		return

	var parent_node = area.get_parent()
	if not is_instance_valid(parent_node):
		return

	var target = parent_node if is_instance_valid(parent_node) else area

	if _should_hit(target):
		_on_hit(target)
		bullet_hit_target.emit(target)

func _check_manual_collision() -> void:
	var nearby = get_tree().get_nodes_in_group("enemies")
	for target in nearby:
		# 关键修复：检查目标是否有效
		if not is_instance_valid(target):
			continue
		if _collision_hit_targets is Array and _collision_hit_targets.has(target):
			continue
		if not _should_hit(target):
			continue
		var dist = global_position.distance_to(target.global_position)
		var target_radius = 18.0
		var radius_val = target.get("collision_radius")
		if radius_val != null:
			target_radius = radius_val
		if dist <= collision_radius + target_radius:
			if _collision_hit_targets is Array:
				_collision_hit_targets.append(target)
			_on_hit(target)
			bullet_hit_target.emit(target)
			if piercing_count > 0 and current_pierce >= piercing_count:
				expire()
				return

func _should_hit(target: Node) -> bool:
	if target == self or target == get_owner():
		return false

	# 关键修复：检查目标是否已被释放
	if not is_instance_valid(target):
		return false

	# 防御性检查：忽略非实体对象（如 ObjectPool 等 Node）
	if not target.has_method("take_damage") and not target.has_method("is_player"):
		return false

	match bullet_owner:
		0:  # PLAYER
			# 再次验证目标有效性并检查死亡状态
			if not is_instance_valid(target):
				return false
			var dead_val = target.get("is_dead")
			var target_is_dead = dead_val if dead_val == true else false
			return not target_is_dead
		1:  # ENEMY
			return target.has_method("is_player") and target.is_player()
		_:  # ENVIRONMENT or other
			return target.has_method("take_damage")

func _on_hit(target: Node) -> void:
	# 关键修复：检查目标有效性
	if not is_instance_valid(target):
		return

	# 如果有穿透能力且未穿透完，则不造成伤害
	if piercing_count > 0 and current_pierce < piercing_count:
		current_pierce += 1
		AudioManager.play_hit_sound()
		return

	# 计算最终伤害
	var final_damage = damage * _damage_multiplier

	# 创建伤害信息
	var damage_info = DamageSystem.DamageInfo.new(self, final_damage, damage_type)

	# 应用弹药特殊效果
	if _explosive_radius > 0:
		damage_info.damage_type = "explosive"
		_trigger_explosion()

	if _poison_dps > 0:
		_apply_poison_effect(target)

	if _electromagnetic_stun > 0:
		_apply_electromagnetic_effect(target)

	DamageSystem.apply_damage(target, damage_info)

	# 子母弹分裂
	if _fragment_count > 0 and not _is_fragment_parent:
		_spawn_fragments()

	expire()

func expire() -> void:
	if not is_active:
		return
	is_active = false
	bullet_expired.emit()
	# 确保在返回对象池前再次检查实例有效性
	if not is_instance_valid(self):
		return
	var return_pool = _pool_name if _pool_name != "" else "Bullet"
	ObjectPool.return_object(return_pool, self)

func on_despawned() -> void:
	if not is_instance_valid(self):
		return
	is_active = false
	set_process(false)
	visible = false

func set_direction(dir: Vector2) -> void:
	bullet_direction = dir.normalized()
	rotation = bullet_direction.angle()

## 设置追踪强度（Day 5新增）
func set_tracking(strength: float) -> void:
	_tracking_strength = clamp(strength, 0.0, 1.0)
	if _tracking_strength > 0:
		print("[BulletBase] Tracking enabled: strength=", _tracking_strength)

## 设置命中率加成（Day 5新增）
func set_hit_chance_bonus(bonus: float) -> void:
	_hit_chance_bonus = clamp(bonus, 0.0, 1.0)
	if _hit_chance_bonus > 0:
		print("[BulletBase] Hit chance bonus: ", _hit_chance_bonus)

# ===== 弹药类型效果（Day 6新增）=====
var _damage_multiplier: float = 1.0
var _explosive_radius: float = 0.0
var _poison_dps: float = 0.0
var _poison_duration: float = 0.0
var _poison_timer: float = 0.0
var _electromagnetic_stun: float = 0.0
var _fragment_count: int = 0
var _is_fragment_parent: bool = false

## 设置伤害倍率（弹药效果）
func set_damage_multiplier(multiplier: float) -> void:
	_damage_multiplier = clamp(multiplier, 0.1, 2.0)

## 获取实际伤害（基础伤害 * 倍率）
func get_final_damage(base_damage: float) -> float:
	return base_damage * _damage_multiplier

## 设置爆炸效果
func set_explosive(radius: float) -> void:
	_explosive_radius = radius

## 设置毒弹效果
func set_poison(dps: float, duration: float) -> void:
	_poison_dps = dps
	_poison_duration = duration

## 设置电磁弹效果
func set_electromagnetic(stun_duration: float) -> void:
	_electromagnetic_stun = stun_duration

## 设置子母弹效果
func set_fragment(count: int) -> void:
	_fragment_count = count

## 添加穿透
func add_piercing(count: int) -> void:
	piercing_count += count

## 触发爆炸效果
func _trigger_explosion() -> void:
	if _explosive_radius <= 0:
		return
	# 查找范围内的敌人并造成伤害
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		# 关键修复：检查敌人有效性
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= _explosive_radius:
			var enemy_damage = DamageSystem.DamageInfo.new(self, damage * _damage_multiplier * 0.5, "explosive")
			DamageSystem.apply_damage(enemy, enemy_damage)
	print("[BulletBase] Explosion triggered at ", global_position, " radius=", _explosive_radius)

## 触发毒弹效果
func _apply_poison_effect(target: Node) -> void:
	if _poison_dps <= 0 or _poison_duration <= 0:
		return
	# 关键修复：检查目标有效性
	if not is_instance_valid(target):
		return
	if target.has_method("apply_poison_damage"):
		target.apply_poison_damage(_poison_dps, _poison_duration)
	print("[BulletBase] Poison applied: dps=", _poison_dps, " duration=", _poison_duration)

## 触发电磁弹效果
func _apply_electromagnetic_effect(target: Node) -> void:
	if _electromagnetic_stun <= 0:
		return
	# 关键修复：检查目标有效性
	if not is_instance_valid(target):
		return
	if target.has_method("apply_stun"):
		target.apply_stun(_electromagnetic_stun)
	print("[BulletBase] Electromagnetic stun applied: duration=", _electromagnetic_stun)

## 重置弹药效果（归还对象时调用）
func reset_ammo_effects() -> void:
	_damage_multiplier = 1.0
	_explosive_radius = 0.0
	_poison_dps = 0.0
	_poison_duration = 0.0
	_poison_timer = 0.0
	_electromagnetic_stun = 0.0
	_fragment_count = 0
	_is_fragment_parent = false

## 子母弹分裂
func _spawn_fragments() -> void:
	if _fragment_count <= 0:
		return

	# 计算分裂后的伤害
	var fragment_damage = damage * _damage_multiplier * 0.5  # 每发分裂弹伤害为原伤害的50%

	# 创建分裂子弹
	for i in range(_fragment_count):
		# 随机角度分裂
		var angle = randf_range(0, TAU)
		var dir = Vector2.from_angle(angle)

		# 创建分裂子弹（标记为子子弹，不再分裂）
		var fragment_bullet = BulletFactory.create_player_bullet(
			"player_basic",
			dir,
			fragment_damage,
			0,
			global_position
		)

		# 标记为子子弹，不继续分裂
		if fragment_bullet:
			fragment_bullet._is_fragment_parent = true

	print("[BulletBase] Spawned ", _fragment_count, " fragments")
