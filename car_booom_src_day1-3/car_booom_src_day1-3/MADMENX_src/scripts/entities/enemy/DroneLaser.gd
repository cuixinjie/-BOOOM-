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
	if _is_charging:
		_charge_timer -= delta
		if _charge_timer <= 0:
			_fire_laser()
		return
	super._process(delta)

func perform_attack() -> void:
	if not is_instance_valid(target_node):
		return

	super.perform_attack()
	_is_charging = true
	_charge_timer = laser_charge_time
	$LaserChargeEffect.visible = true

func _fire_laser() -> void:
	_is_charging = false
	$LaserChargeEffect.visible = false

	if not is_instance_valid(target_node):
		return

	var dir = (target_node.global_position - global_position).normalized()
	BulletFactory.create_enemy_bullet("enemy_laser", dir, attack_damage * 1.5)
	AudioManager.play_sfx("laser_fire")
