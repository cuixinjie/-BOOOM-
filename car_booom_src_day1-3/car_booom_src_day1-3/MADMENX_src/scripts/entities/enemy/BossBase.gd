## BossBase — BOSS基类
##
## 功能说明：
## - 所有BOSS的基类
## - 支持多阶段、召唤、特殊技能
##
## 对接注意事项：
## - BOSS血量通过 ConfigManager 配置
## - 阶段切换通过 EventBus.boss_phase_changed 广播
## - BOSS召唤通过 EventBus.spawn_boss_requested 通知
##
## 创建人：长安旧梦（主）、新街（扩展）
## 创建日期：2026-04-29
## 合并日期：2026-05-02

class_name BossBase
extends EnemyBase

signal phase_started(phase: int)
signal special_attack_triggered(attack_name: String)

enum BossType {
	DRONE_COMMANDER,
	MECH_TANK,
	BIKE_LEADER
}

var boss_type: BossType = BossType.DRONE_COMMANDER
var boss_name: String = "Unknown Boss"
var current_phase: int = 1
var max_phase: int = 3

var phase_timers: Array = []
var phase_thresholds: Array = [0.66, 0.33]

var is_enraged: bool = false
var enraged_threshold: float = 0.3

var summon_cooldown: float = 10.0
var _summon_timer: float = 0.0

var _special_attack_queue: Array = []
var _attack_pattern_timer: float = 0.0
var _base_attack_cooldown: float = 2.0
var _current_attack_cooldown: float = 2.0

var _elbow_active: bool = false
var _stomp_active: bool = false

var _special_attack_damage: float = 15.0

var _spread_by_phase: Array = [1, 2, 3]
var _summon_minion_count: int = 3
var _base_move_speed_storage: float = 60.0
var _phase_move_scales: Array = [1.0, 1.15, 1.35]
var _phase_cooldown_scales: Array = [1.0, 0.72, 0.48]
var _special_damage_scales: Array = [1.0, 1.15, 1.35]

func _ready() -> void:
	_apply_boss_balance_from_config()
	enemy_type = "boss"
	score_value = 500
	coin_drop_max = 50
	energy_drop_max = 20

	super._ready()
	if has_node("BossHealthBar"):
		$BossHealthBar.visible = true
	_update_health_bar()


func _apply_boss_balance_from_config() -> void:
	var cfg: Dictionary = ConfigMgr.get_enemy_stats("boss_drone_commander")
	if cfg.is_empty():
		return
	max_health = float(cfg.get("max_health", max_health))
	current_health = max_health
	attack_damage = float(cfg.get("damage", attack_damage))
	move_speed = float(cfg.get("move_speed", move_speed))
	_base_move_speed_storage = move_speed
	summon_cooldown = float(cfg.get("summon_cooldown", summon_cooldown))
	enraged_threshold = float(cfg.get("enraged_threshold", enraged_threshold))
	_summon_minion_count = int(cfg.get("summon_minion_count", _summon_minion_count))
	var th: Array = cfg.get("phase_thresholds", phase_thresholds) as Array
	if th.size() > 0:
		phase_thresholds = th.duplicate()
	_spread_by_phase = [
		int(cfg.get("spread_bullets_phase_1", 1)),
		int(cfg.get("spread_bullets_phase_2", 2)),
		int(cfg.get("spread_bullets_phase_3", 3)),
	]
	_base_attack_cooldown = float(cfg.get("base_attack_cooldown", _base_attack_cooldown))
	_current_attack_cooldown = _base_attack_cooldown
	var pms: Array = cfg.get("phase_move_speed_scale", _phase_move_scales) as Array
	if pms.size() >= 3:
		_phase_move_scales = [float(pms[0]), float(pms[1]), float(pms[2])]
	var pcs: Array = cfg.get("phase_cooldown_scale", _phase_cooldown_scales) as Array
	if pcs.size() >= 3:
		_phase_cooldown_scales = [float(pcs[0]), float(pcs[1]), float(pcs[2])]
	var sds: Array = cfg.get("special_damage_scale", _special_damage_scales) as Array
	if sds.size() >= 3:
		_special_damage_scales = [float(sds[0]), float(sds[1]), float(sds[2])]
	score_value = int(cfg.get("score_value", score_value))
	var cd: Array = cfg.get("coin_drop", [30, 50])
	var ed: Array = cfg.get("energy_drop", [10, 20])
	if cd.size() >= 2:
		coin_drop_min = int(cd[0])
		coin_drop_max = int(cd[1])
	if ed.size() >= 2:
		energy_drop_min = int(ed[0])
		energy_drop_max = int(ed[1])


func _process(delta: float) -> void:
	if is_dead:
		return

	super._process(delta)

	if _summon_timer > 0:
		_summon_timer -= delta

	_check_phase_transition()
	_update_attack_pattern(delta)

func _check_phase_transition() -> void:
	var health_ratio = current_health / max_health

	for i in range(phase_thresholds.size()):
		var threshold = phase_thresholds[i]
		if health_ratio <= threshold and current_phase < i + 2:
			set_phase(i + 2)
			break

	if not is_enraged and health_ratio <= enraged_threshold:
		_trigger_enrage()

func set_phase(new_phase: int) -> void:
	current_phase = new_phase
	print("[BossBase] ", boss_name, " entered phase ", current_phase)
	phase_started.emit(current_phase)
	EventBus.boss_phase_changed.emit(current_phase)
	_on_phase_start(new_phase)

func _on_phase_start(phase: int) -> void:
	move_speed = _base_move_speed_storage
	var idx: int = clampi(phase - 1, 0, _phase_move_scales.size() - 1)
	move_speed *= float(_phase_move_scales[idx])
	var cds: float = float(_phase_cooldown_scales[clampi(phase - 1, 0, _phase_cooldown_scales.size() - 1)])
	_current_attack_cooldown = _base_attack_cooldown * cds
	match phase:
		3:
			if _summon_timer <= 0:
				summon_minions("drone_basic", _summon_minion_count)

func _trigger_enrage() -> void:
	is_enraged = true
	move_speed *= 2.0
	attack_cooldown *= 0.5
	print("[BossBase] ", boss_name, " ENRAGED!")

func trigger_special_attack(attack_name: String) -> void:
	print("[BossBase] Special attack: ", attack_name)
	special_attack_triggered.emit(attack_name)

func summon_minions(minion_type: String, count: int) -> void:
	_summon_timer = summon_cooldown
	EventBus.spawn_boss_requested.emit(minion_type)
	print("[BossBase] Summoning ", count, "x ", minion_type)

func _update_health_bar() -> void:
	if has_node("BossHealthBar"):
		var bar = $BossHealthBar
		bar.max_value = max_health
		bar.value = current_health

func _update_attack_pattern(delta: float) -> void:
	if _elbow_active or _stomp_active:
		return
	if not is_instance_valid(target_node):
		return

	_attack_pattern_timer -= delta
	if _attack_pattern_timer <= 0:
		_execute_attack_pattern()
		_attack_pattern_timer = _current_attack_cooldown

func _execute_attack_pattern() -> void:
	match current_phase:
		1:
			_fire_bullet_pattern()
		2:
			_fire_bullet_pattern()
			if randf() < 0.3:
				_trigger_elbow_slam()
		3:
			_fire_bullet_pattern()
			if randf() < 0.4:
				_trigger_elbow_slam()
			if randf() < 0.2:
				_trigger_stomp()

func _fire_bullet_pattern() -> void:
	if not is_instance_valid(target_node):
		return
	var dir = (target_node.global_position - global_position).normalized()
	var spread_count: int = int(_spread_by_phase[clampi(current_phase - 1, 0, _spread_by_phase.size() - 1)])
	for i in spread_count:
		var angle_offset = (i - (spread_count - 1) * 0.5) * 0.3
		var rotated_dir = dir.rotated(angle_offset)
		BulletFactory.create_enemy_bullet("enemy_basic", rotated_dir, attack_damage)

func _trigger_elbow_slam() -> void:
	_elbow_active = true
	trigger_special_attack("elbow_slam")
	await get_tree().create_timer(0.8).timeout
	_apply_elbow_damage()
	_elbow_active = false

func _apply_elbow_damage() -> void:
	if not is_instance_valid(target_node):
		return
	var dist = global_position.distance_to(target_node.global_position)
	var sm: float = float(_special_damage_scales[clampi(current_phase - 1, 0, _special_damage_scales.size() - 1)])
	if dist <= 200.0:
		DamageSystem.apply_damage(target_node, DamageSystem.DamageInfo.new(self, _special_attack_damage * float(current_phase) * sm, "impact"))
	GameManager.damage_vehicle(_special_attack_damage * float(current_phase) * 0.5 * sm)
	AudioManager.play_sfx("boss_elbow")

func _trigger_stomp() -> void:
	_stomp_active = true
	trigger_special_attack("stomp")
	EventBus.screen_shake_requested.emit(0.5, 8.0)
	await get_tree().create_timer(0.5).timeout
	_apply_stomp_damage()
	_stomp_active = false

func _apply_stomp_damage() -> void:
	if not is_instance_valid(target_node):
		return
	var dist = global_position.distance_to(target_node.global_position)
	var sm: float = float(_special_damage_scales[clampi(current_phase - 1, 0, _special_damage_scales.size() - 1)])
	if dist <= 300.0:
		DamageSystem.apply_damage(target_node, DamageSystem.DamageInfo.new(self, _special_attack_damage * 2.0 * sm, "impact"))
	GameManager.damage_vehicle(_special_attack_damage * sm)
	AudioManager.play_sfx("boss_stomp")

func perform_attack() -> void:
	if not is_instance_valid(target_node):
		return
	_fire_bullet_pattern()

func die(killer: Node = null) -> void:
	super.die(killer)
	EventBus.boss_phase_timeout.emit()
	queue_free()
