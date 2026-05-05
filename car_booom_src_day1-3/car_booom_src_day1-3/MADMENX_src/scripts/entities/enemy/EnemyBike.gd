## EnemyBike — 对冲摩托车
##
## 功能说明：
## - 预警 → 直线冲锋 → 冲锋途中三连弹幕 → 撞击机车造成伤害
## - 数值来自 enemy_stats.json / enemy_bike
##
## 对接注意事项：
## - 伤害机车沿用 GameManager.damage_vehicle（与全局血量一致）
## - 弹幕使用 BulletFactory.create_enemy_bullet
##
## 创建人：长安旧梦
## 创建日期：2026-04-29
## 更新日期：2026-05-05

class_name EnemyBike
extends EnemyBase

enum BikePhase {
	_idle,
	_warn,
	_charge,
	_cooldown
}

var charge_speed: float = 500.0
var charge_cooldown: float = 4.0
var charge_damage: float = 25.0
var warn_time: float = 1.5
var burst_bullet_count: int = 3
var burst_bullet_damage: float = 3.0
var burst_interval: float = 0.28

var _bike_phase: BikePhase = BikePhase._idle
var _phase_timer: float = 0.0
var _burst_remaining: int = 0
var _burst_cool: float = 0.0
var _charge_dir: Vector2 = Vector2.LEFT


func _ready() -> void:
	enemy_type = "enemy_bike"
	_load_stats_from_config()
	super._ready()


func _load_stats_from_config() -> void:
	var cfg: Dictionary = ConfigMgr.get_enemy_stats("enemy_bike")
	if cfg.is_empty():
		return
	max_health = float(cfg.get("max_health", max_health))
	current_health = max_health
	move_speed = float(cfg.get("move_speed", move_speed))
	chase_range = float(cfg.get("chase_range", chase_range))
	charge_speed = float(cfg.get("charge_speed", charge_speed))
	charge_cooldown = float(cfg.get("charge_cooldown", charge_cooldown))
	charge_damage = float(cfg.get("damage", charge_damage))
	attack_damage = charge_damage
	warn_time = float(cfg.get("warn_time", warn_time))
	burst_bullet_count = int(cfg.get("burst_bullet_count", burst_bullet_count))
	burst_bullet_damage = float(cfg.get("burst_bullet_damage", burst_bullet_damage))
	burst_interval = float(cfg.get("burst_interval", burst_interval))
	attack_range = 240.0
	attack_cooldown = charge_cooldown
	score_value = int(cfg.get("score_value", score_value))
	var cd: Array = cfg.get("coin_drop", [3, 8])
	var ed: Array = cfg.get("energy_drop", [1, 4])
	if cd.size() >= 2:
		coin_drop_min = int(cd[0])
		coin_drop_max = int(cd[1])
	if ed.size() >= 2:
		energy_drop_min = int(ed[0])
		energy_drop_max = int(ed[1])


func _start_charge_sequence() -> void:
	if not is_instance_valid(target_node):
		return
	_bike_phase = BikePhase._warn
	_phase_timer = warn_time
	var raw: Vector2 = target_node.global_position - global_position
	_charge_dir = Vector2(sign(raw.x), 0.0)
	if _charge_dir.x == 0.0:
		_charge_dir = Vector2.LEFT


func _fire_burst_round() -> void:
	if not is_instance_valid(target_node):
		return
	var dir: Vector2 = (target_node.global_position - global_position).normalized()
	BulletFactory.create_enemy_bullet("enemy_basic", dir, burst_bullet_damage, global_position)


func _update_attack() -> void:
	if not is_instance_valid(target_node):
		_bike_phase = BikePhase._idle
		return

	match _bike_phase:
		BikePhase._idle:
			if _attack_timer > 0.0:
				_attack_timer -= _cached_delta
				return
			_start_charge_sequence()

		BikePhase._warn:
			_phase_timer -= _cached_delta
			if _phase_timer <= 0.0:
				_bike_phase = BikePhase._charge
				_burst_remaining = burst_bullet_count
				_burst_cool = 0.0

		BikePhase._charge:
			global_position += _charge_dir * charge_speed * _cached_delta
			_burst_cool -= _cached_delta
			if _burst_remaining > 0 and _burst_cool <= 0.0:
				_fire_burst_round()
				_burst_remaining -= 1
				_burst_cool = burst_interval

			if _check_player_collision():
				_apply_charge_impact()
				return

			var viewport := get_viewport()
			if viewport:
				var rect: Rect2 = viewport.get_visible_rect()
				var pad := 200.0
				if global_position.x < rect.position.x - pad or global_position.x > rect.end.x + pad:
					_enter_cooldown()

		BikePhase._cooldown:
			_phase_timer -= _cached_delta
			if _phase_timer <= 0.0:
				_bike_phase = BikePhase._idle
				_attack_timer = charge_cooldown


func _check_player_collision() -> bool:
	if is_instance_valid(target_node):
		var dist: float = global_position.distance_to(target_node.global_position)
		return dist <= 55.0
	return false


func _apply_charge_impact() -> void:
	GameManager.damage_vehicle(charge_damage)
	_bike_phase = BikePhase._cooldown
	_phase_timer = charge_cooldown * 0.35
	_attack_timer = charge_cooldown
	AudioManager.play_sfx("bike_charge")


func _enter_cooldown() -> void:
	_bike_phase = BikePhase._cooldown
	_phase_timer = charge_cooldown * 0.25
	_attack_timer = charge_cooldown
