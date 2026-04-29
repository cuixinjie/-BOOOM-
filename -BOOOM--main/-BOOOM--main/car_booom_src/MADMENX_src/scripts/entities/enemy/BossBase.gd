## BossBase — BOSS基类
##
## 功能说明：
## - BOSS实体基类
## - 支持多阶段战斗
##
## 对接注意事项：
## - 场景文件：scenes/entities/enemies/bosses/Boss01.tscn
## - 阶段切换通过 EventBus.boss_phase_changed 广播
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name BossBase
extends EnemyBase

signal phase_changed(new_phase: int)
signal phase_completed()

@export var phases: Array = []

var _current_phase: int = 0
var _phase_thresholds: Array = []

func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	_load_boss_stats()

func _load_boss_stats() -> void:
	var stats = ConfigManager.get_enemy_stats(enemy_type)
	if stats and stats.has("phases"):
		phases = stats["phases"]
		for phase in phases:
			_phase_thresholds.append(phase.get("threshold", 1.0))
	print("[BossBase] Boss initialized with ", phases.size(), " phases")

func _process(delta: float) -> void:
	super._process(delta)
	_check_phase_transition()

func _check_phase_transition() -> void:
	var health_percent = current_health / max_health if max_health > 0 else 0.0
	
	for i in _phase_thresholds.size():
		if health_percent <= _phase_thresholds[i] and _current_phase < i:
			_transition_to_phase(i)
			break

func _transition_to_phase(new_phase: int) -> void:
	_current_phase = new_phase
	phase_changed.emit(_current_phase)
	EventBus.boss_phase_changed.emit(_current_phase)
	print("[BossBase] Entered phase ", _current_phase)

func get_current_phase() -> int:
	return _current_phase

func get_phase_attack_pattern() -> String:
	if phases.size() > _current_phase:
		return phases[_current_phase].get("pattern", "basic")
	return "basic"
