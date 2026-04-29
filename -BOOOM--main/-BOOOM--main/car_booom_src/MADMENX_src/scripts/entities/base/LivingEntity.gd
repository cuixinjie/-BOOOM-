## LivingEntity — 可存活实体基类
##
## 功能说明：
## - 具有生命值的实体基类
## - 支持受伤、死亡、复活
##
## 对接注意事项：
## - 被 PlayerBase、EnemyBase 继承
## - 通过 EventBus.player_damaged / enemy_killed 广播状态
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name LivingEntity
extends Entity

signal health_changed(current: float, maximum: float)
signal died(entity: Node)
signal revived(entity: Node)

@export var max_health: float = 100.0
@export var start_health: float = 100.0
@export var is_invulnerable: bool = false
@export var invulnerability_duration: float = 0.0

var current_health: float
var _is_dead: bool = false
var _invulnerability_timer: float = 0.0

# ===== 接口定义 =====
## get_health() -> float
##   获取当前生命值
##
## get_max_health() -> float
##   获取最大生命值
##
## get_health_percent() -> float
##   获取生命值百分比
##
## take_damage(amount: float) -> void
##   受到伤害
##
## heal(amount: float) -> void
##   治疗
##
## heal_to_full() -> void
##   治愈到满
##
## is_dead() -> bool
##   是否已死亡
##
## kill() -> void
##   立即杀死
##
## revive(health_percent: float = 1.0) -> void
##   复活
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	current_health = start_health if start_health > 0 else max_health
	max_health = max_health if max_health > 0 else 100.0

func _process(delta: float) -> void:
	super._process(delta)
	_update_invulnerability(delta)

func _update_invulnerability(delta: float) -> void:
	if _invulnerability_timer > 0:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0:
			is_invulnerable = false

func _take_damage(amount: float, damage_info) -> void:
	if is_invulnerable or _is_dead:
		return
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if damage_info.source is Entity:
		_on_damaged(damage_info)
	
	if current_health <= 0:
		die()

func _on_damaged(damage_info) -> void:
	print("[LivingEntity] ", entity_name, " took ", damage_info.base_damage, " damage")

func get_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health

func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0

func take_damage(amount: float) -> void:
	if is_invulnerable or _is_dead:
		return
	
	var damage_info = DamageSystem.DamageInfo.new(self, amount, "physical")
	DamageSystem.apply_damage(self, damage_info)

func heal(amount: float) -> void:
	if _is_dead:
		return
	
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func heal_to_full() -> void:
	heal(max_health - current_health)

func is_dead() -> bool:
	return _is_dead

func kill() -> void:
	if not _is_dead:
		current_health = 0
		health_changed.emit(0, max_health)
		die()

func die() -> void:
	if _is_dead:
		return
	
	_is_dead = true
	died.emit(self)
	print("[LivingEntity] ", entity_name, " died")
	destroy()

func revive(health_percent: float = 1.0) -> void:
	_is_dead = false
	current_health = max_health * health_percent
	health_changed.emit(current_health, max_health)
	revived.emit(self)
	print("[LivingEntity] ", entity_name, " revived at ", health_percent * 100, "%")

func get_armor() -> float:
	return 0.0

func is_in_invulnerable_state() -> bool:
	return is_invulnerable

func grant_invulnerability(duration: float) -> void:
	is_invulnerable = true
	_invulnerability_timer = duration
