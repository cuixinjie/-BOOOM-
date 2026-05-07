## EnemyBike — 对冲摩托车
##
## 功能说明：
## - 从前方高速冲来的摩托车敌人
## - 直线冲向玩家位置，冲锋时发射扇形弹幕
##
## Day 4完善内容（长安旧梦）：
## - 修复附带弹幕位置传递问题（现在弹幕从敌人实际位置生成）
## - 冲锋弹幕应用正确的spawn_pos参数
##
## 对接注意事项：
## - 冲锋伤害通过 GameManager.damage_vehicle 作用于机车
## - 冲锋时附带弹幕由 BulletFactory.create_enemy_bullet 生成
## - EMP期间冲锋和弹幕均被禁用
##
## 创建人：长安旧梦
## 创建日期：2026-04-29
## Day 4完善：附带弹幕位置修复（2026-05-06）

class_name EnemyBike
extends EnemyBase

var charge_speed: float = 500.0
var charge_cooldown: float = 4.0
var charge_damage: float = 25.0
var _is_charging: bool = false
var _charge_direction: Vector2 = Vector2.ZERO

# 附带弹幕参数
var bullet_count: int = 3
var bullet_spread: float = 0.4
var bullet_damage: float = 5.0
var _has_fired_bullets_this_charge: bool = false

# EMP状态追踪
var _is_disabled: bool = false

func _ready() -> void:
	enemy_type = "enemy_bike"
	max_health = 50.0
	current_health = max_health
	move_speed = 150.0
	chase_range = 600.0
	attack_range = 50.0
	attack_cooldown = charge_cooldown
	score_value = 25
	coin_drop_max = 8

	super._ready()
	_connect_emp_signals()

func _connect_emp_signals() -> void:
	if not EventBus.emp_activated.is_connected(_on_emp_activated):
		EventBus.emp_activated.connect(_on_emp_activated)
	if not EventBus.emp_deactivated.is_connected(_on_emp_deactivated):
		EventBus.emp_deactivated.connect(_on_emp_deactivated)

func _on_emp_activated() -> void:
	_is_disabled = true
	_is_charging = false
	_attack_timer = charge_cooldown * 0.5
	print("[EnemyBike] Disabled by EMP")

func _on_emp_deactivated() -> void:
	_is_disabled = false
	print("[EnemyBike] Re-enabled after EMP")

func _update_attack() -> void:
	if _is_disabled:
		return

	if not _is_charging:
		if _attack_timer <= 0:
			_start_charge()
			return
		_attack_timer -= _cached_delta

	if _is_charging:
		global_position += _charge_direction * charge_speed * _cached_delta
		if not _has_fired_bullets_this_charge:
			_fire_charge_bullets()
		if _check_player_collision():
			_trigger_charge_damage()
		# 冲锋超时保护：防止冲锋卡住
		_attack_timer -= _cached_delta
		if _attack_timer <= -3.0:
			_cancel_charge()

## 取消冲锋并重置状态
func _cancel_charge() -> void:
	_is_charging = false
	_has_fired_bullets_this_charge = false
	_attack_timer = charge_cooldown
	_change_state(EnemyState.IDLE)
	print("[EnemyBike] Charge cancelled (timeout)")

## 被击中时重置冲锋状态
func take_damage(amount: float, source: Node = null) -> void:
	if _is_charging:
		_cancel_charge()
	super.take_damage(amount, source)

func _start_charge() -> void:
	if not is_instance_valid(target_node):
		return

	_is_charging = true
	_has_fired_bullets_this_charge = false
	# 垂直视角：从上向下冲锋
	var dir = (target_node.global_position - global_position).normalized()
	# 确保向下冲锋（Y轴正方向）
	if dir.y < 0:
		dir.y = -dir.y
	_charge_direction = dir
	_attack_timer = 1.5
	print("[EnemyBike] Charging!")

func _fire_charge_bullets() -> void:
	_has_fired_bullets_this_charge = true
	if not is_instance_valid(target_node):
		return
	AudioManager.play_sfx("bike_charge")
	# 垂直视角：弹幕向下发射（Y轴正方向）
	var bullet_dir = Vector2(0, 1)
	for i in bullet_count:
		var angle_offset = (i - (bullet_count - 1) * 0.5) * bullet_spread
		var rotated_dir = bullet_dir.rotated(angle_offset)
		BulletFactory.create_enemy_bullet("enemy_basic", rotated_dir, bullet_damage, global_position)

func _check_player_collision() -> bool:
	if is_instance_valid(target_node):
		var dist = global_position.distance_to(target_node.global_position)
		return dist <= attack_range
	return false

func _trigger_charge_damage() -> void:
	GameManager.damage_vehicle(charge_damage)
	_is_charging = false
	_has_fired_bullets_this_charge = false
	_attack_timer = charge_cooldown
	AudioManager.play_sfx("bike_charge")

func _on_world_state_changed(_from_state: int, _to_state: int) -> void:
	pass
