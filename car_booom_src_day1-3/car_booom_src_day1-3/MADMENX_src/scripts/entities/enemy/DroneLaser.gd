## DroneLaser — 激光无人机
##
## 功能说明：
## - 发射激光弹幕
## - 伤害更高但射速慢
##
## 对接注意事项：
## - 充能完成后发射一枚高伤害激光
## - 充能期间敌人不移动（由 DroneLaser 自身 _process 处理）
##
## 创建人：长安旧梦
## 创建日期：2026-04-29
## 修复日期：2026-05-02

class_name DroneLaser
extends EnemyBase

var laser_charge_time: float = 1.5
var _charge_timer: float = 0.0
var _is_charging: bool = false

func _ready() -> void:
	enemy_type = "drone_laser"
	max_health = 20.0
	current_health = max_health
	move_speed = 60.0
	chase_range = 400.0
	attack_range = 300.0
	attack_cooldown = 3.0
	attack_damage = 20.0
	score_value = 20

	super._ready()

func _process(delta: float) -> void:
	if is_dead:
		return

	# EMP期间敌人完全静止
	if _is_emp_disabled:
		return

	if _attack_timer > 0:
		_attack_timer -= delta

	if _is_charging:
		_charge_timer -= delta
		if _charge_timer <= 0:
			_fire_laser()
		# 充能期间仍然处理攻击计时器
		return

	# 非充能状态下的正常行为
	match enemy_state:
		EnemyState.IDLE:
			_update_idle()
		EnemyState.CHASE:
			_update_chase(delta)
		EnemyState.ATTACK:
			_cached_delta = delta
			_update_attack()

## 被击中时重置充能状态（防止卡住）
func take_damage(amount: float, source: Node = null) -> void:
	# 重置充能状态，允许敌人被击中后恢复移动
	if _is_charging:
		_is_charging = false
		_charge_timer = 0.0
		# 关键修复：检查节点有效性
		if has_node("LaserChargeEffect") and is_instance_valid($LaserChargeEffect):
			$LaserChargeEffect.visible = false
		print("[DroneLaser] Charge cancelled due to damage")

	super.take_damage(amount, source)

func perform_attack() -> void:
	if not is_instance_valid(target_node):
		return

	super.perform_attack()
	_is_charging = true
	_charge_timer = laser_charge_time
	# 关键修复：检查节点有效性
	if has_node("LaserChargeEffect") and is_instance_valid($LaserChargeEffect):
		$LaserChargeEffect.visible = true

func _fire_laser() -> void:
	_is_charging = false
	# 关键修复：检查节点有效性
	if has_node("LaserChargeEffect") and is_instance_valid($LaserChargeEffect):
		$LaserChargeEffect.visible = false

	if not is_instance_valid(target_node):
		return

	# 垂直视角：激光向下发射
	var dir = Vector2(0, 1)
	BulletFactory.create_enemy_bullet("enemy_laser", dir, attack_damage * 1.5, global_position)
	AudioManager.play_sfx("laser_fire")
