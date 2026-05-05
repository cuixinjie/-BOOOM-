## BulletBase — 子弹基类
##
## 功能说明：
## - 所有子弹的基类
## - 处理移动、碰撞、效果
##
## 对接注意事项：
## - 子弹通过 ObjectPool 管理
## - 命中通过 EventBus.bullet_hit 广播
##
## 创建人：长安旧梦（主）、cjs（扩展）
## 创建日期：2026-04-29
## 合并日期：2026-05-02

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

# 可被穿透子弹覆盖（穿透 N 表示额外贯穿 N 个目标，共命中 N+1 次）
var piercing_count: int = 0
var hits_landed: int = 0
var speed_mult_after_pierce: float = 1.0
var collision_radius: float = 8.0
var _collision_hit_targets: Array = []

# 弹药特效（由 BulletFactory.apply_ammo_effect 写入）
var explosion_radius: float = 0.0
var explosion_damage_ratio: float = 0.0
var poison_max_hp_pct: float = 0.0
var poison_duration: float = 0.0
var poison_stack_cap: int = 3
var emp_duration: float = 0.0
var submunition_split_delay: float = -1.0
var submunition_count: int = 0
var submunition_damage_scale: float = 1.0
var submunition_angle_deg: float = 15.0

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

func _process(delta: float) -> void:
	if not is_active:
		return

	if submunition_split_delay >= 0.0:
		submunition_split_delay -= delta
		if submunition_split_delay <= 0.0:
			submunition_split_delay = -1.0
			_spawn_submunitions()

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

func fire(dir: Vector2, spd: float, dmg: float, blt_owner: int = 0, pierce: int = 0, spawn_pos: Vector2 = Vector2.ZERO) -> void:
	bullet_direction = dir.normalized()
	bullet_speed = spd
	damage = dmg
	bullet_owner = blt_owner
	is_active = true
	lifetime_timer = lifetime
	distance_traveled = 0.0
	visible = true
	hits_landed = 0
	if spawn_pos != Vector2.ZERO:
		global_position = spawn_pos
	set_process(true)

	piercing_count = maxi(0, pierce)
	speed_mult_after_pierce = 1.0
	explosion_radius = 0.0
	explosion_damage_ratio = 0.0
	poison_max_hp_pct = 0.0
	poison_duration = 0.0
	emp_duration = 0.0
	submunition_split_delay = -1.0
	submunition_count = 0

	_collision_hit_targets.clear()

func set_pool_name(pool_name: String) -> void:
	_pool_name = pool_name

func on_spawned() -> void:
	is_active = false
	lifetime_timer = 0.0
	distance_traveled = 0.0
	visible = false
	set_process(false)
	hits_landed = 0
	piercing_count = 0
	_collision_hit_targets.clear()
	submunition_split_delay = -1.0

func on_despawned() -> void:
	is_active = false
	set_process(false)
	visible = false

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return

	var target = area.get_parent() if area.get_parent() else area

	if _should_hit(target):
		_on_hit(target)
		bullet_hit_target.emit(target)

func _check_manual_collision() -> void:
	var nearby = get_tree().get_nodes_in_group("enemies")
	for target in nearby:
		if not is_instance_valid(target):
			continue
		if _collision_hit_targets.has(target):
			continue
		if not _should_hit(target):
			continue
		var dist = global_position.distance_to(target.global_position)
		var target_radius = 18.0
		var radius_val = target.get("collision_radius")
		if radius_val != null:
			target_radius = radius_val
		if dist <= collision_radius + target_radius:
			_collision_hit_targets.append(target)
			_on_hit(target)
			bullet_hit_target.emit(target)
			if not is_active:
				return

func _should_hit(target: Node) -> bool:
	if target == self or target == get_owner():
		return false

	# 防御性检查：忽略非实体对象（如 ObjectPool 等 Node）
	if not target.has_method("take_damage") and not target.has_method("is_player"):
		return false

	match bullet_owner:
		0:  # PLAYER
			var dead_val = target.get("is_dead")
			var target_is_dead = dead_val if dead_val != null else false
			return not target_is_dead
		1:  # ENEMY
			return target.has_method("is_player") and target.is_player()
		_:  # ENVIRONMENT or other
			return target.has_method("take_damage")

func _on_hit(target: Node) -> void:
	if not is_active:
		return

	var damage_info := DamageSystem.DamageInfo.new(self, damage, damage_type)
	DamageSystem.apply_damage(target, damage_info)
	AudioManager.play_hit_sound()

	if explosion_radius > 0.0 and explosion_damage_ratio > 0.0:
		DamageSystem.apply_explosion_aoe(global_position, explosion_radius, damage * explosion_damage_ratio, self, target)

	if poison_max_hp_pct > 0.0 and poison_duration > 0.0 and target.has_method("apply_poison_stack"):
		target.call("apply_poison_stack", poison_max_hp_pct, poison_duration, poison_stack_cap)

	if emp_duration > 0.0 and target.has_method("apply_stun"):
		target.call("apply_stun", emp_duration)

	hits_landed += 1
	var max_hits := 1
	if piercing_count > 0:
		max_hits = piercing_count + 1
	bullet_speed *= speed_mult_after_pierce
	if hits_landed >= max_hits:
		expire()


func _spawn_submunitions() -> void:
	if bullet_owner != 0 or submunition_count <= 0:
		return
	var fac := BulletFactory
	if fac == null or not fac.has_method("create_player_bullet"):
		return
	var base_angle := rad_to_deg(bullet_direction.angle())
	for i in submunition_count:
		var off := (float(i) - float(submunition_count - 1) * 0.5) * submunition_angle_deg
		var ang := deg_to_rad(base_angle + off)
		var dir := Vector2.from_angle(ang)
		var child_dmg := damage * submunition_damage_scale
		fac.create_player_bullet("player_basic", dir, child_dmg, 0, global_position, {"skip_submunition_clone": true})

func expire() -> void:
	if not is_active:
		return
	is_active = false
	bullet_expired.emit()
	var return_pool = _pool_name if _pool_name != "" else "Bullet"
	ObjectPool.return_object(return_pool, self)

func set_direction(dir: Vector2) -> void:
	bullet_direction = dir.normalized()
	rotation = bullet_direction.angle()
