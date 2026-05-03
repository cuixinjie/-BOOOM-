## EnemyBase — 敌人基类
##
## 功能说明：
## - 所有敌人的基类
## - 定义敌人通用属性和行为
##
## 对接注意事项：
## - AI行为、攻击模式由子类实现
## - 死亡通过 EventBus.enemy_killed 广播
## - 掉落通过 ObjectPool 管理
##
## 创建人：长安旧梦（主）、新街（接口）
## 创建日期：2026-04-29
## 合并日期：2026-05-02
## 修复日期：2026-05-02

class_name EnemyBase
extends Entity

signal target_updated(new_target: Node)
signal attack_triggered()

enum EnemyState {
	IDLE,
	CHASE,
	ATTACK,
	RETREAT,
	DEAD
}

var enemy_type: String = "basic"
var enemy_state: EnemyState = EnemyState.IDLE
var chase_range: float = 400.0
var attack_range: float = 200.0
var attack_cooldown: float = 1.0
var _attack_timer: float = 0.0
var attack_damage: float = 10.0
var _cached_delta: float = 0.0
# 移除了 move_speed - 继承自 Entity 基类

const DEFAULT_CHASE_RANGE_MULT: float = 1.5

var score_value: int = 10
var coin_drop_min: int = 1
var coin_drop_max: int = 5
var energy_drop_min: int = 0
var energy_drop_max: int = 2

var target_node: Node = null

# ===== 接口定义 =====
## set_target(target: Node) -> void
##   设置追击目标
##
## enter_attack_state() -> void
##   进入攻击状态
##
## perform_attack() -> void
##   执行攻击
##
## die(killer: Node) -> void
##   敌人死亡
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	_connect_signals()
	add_to_group("enemy")
	add_to_group("enemies")
	if max_health <= 0:
		max_health = 30.0
		current_health = max_health
	activate()

func _connect_signals() -> void:
	if not EventBus.world_state_changed.is_connected(_on_world_state_changed):
		EventBus.world_state_changed.connect(_on_world_state_changed)

func _on_world_state_changed(_from_state: int, _to_state: int) -> void:
	pass

func _process(delta: float) -> void:
	if is_dead:
		return

	if _attack_timer > 0:
		_attack_timer -= delta

	match enemy_state:
		EnemyState.IDLE:
			_update_idle()
		EnemyState.CHASE:
			_update_chase(delta)
		EnemyState.ATTACK:
			_cached_delta = delta
			_update_attack()

func _update_idle() -> void:
	if target_node and is_instance_valid(target_node):
		var dist = global_position.distance_to(target_node.global_position)
		if dist <= chase_range:
			_change_state(EnemyState.CHASE)

func _update_chase(delta: float) -> void:
	if not is_instance_valid(target_node):
		_change_state(EnemyState.IDLE)
		return

	var dist = global_position.distance_to(target_node.global_position)
	if dist > chase_range * DEFAULT_CHASE_RANGE_MULT:
		_change_state(EnemyState.IDLE)
	elif dist <= attack_range:
		_change_state(EnemyState.ATTACK)
	else:
		var dir = (target_node.global_position - global_position).normalized()
		global_position += dir * move_speed * delta

func _update_attack() -> void:
	if not is_instance_valid(target_node):
		_change_state(EnemyState.IDLE)
		return

	var dist = global_position.distance_to(target_node.global_position)
	if dist > attack_range:
		_change_state(EnemyState.CHASE)
	elif _attack_timer <= 0:
		perform_attack()
		_attack_timer = attack_cooldown

func _change_state(new_state: EnemyState) -> void:
	enemy_state = new_state
	print("[EnemyBase] ", entity_name, " state changed to: ", EnemyState.keys()[new_state])

func set_target(target: Node) -> void:
	target_node = target
	target_updated.emit(target)

func enter_attack_state() -> void:
	_change_state(EnemyState.ATTACK)

func perform_attack() -> void:
	attack_triggered.emit()
	AudioManager.play_sfx("enemy_attack")

func die(killer: Node = null) -> void:
	is_dead = true
	died.emit(killer)
	deactivate()
	_change_state(EnemyState.DEAD)
	EventBus.enemy_killed.emit(self, killer)
	_drop_loot()
	_death_animation()

func _drop_loot() -> void:
	var coin_count = randi_range(coin_drop_min, coin_drop_max)
	var energy_count = randi_range(energy_drop_min, energy_drop_max)

	for i in coin_count:
		var coin = ObjectPool.get_object("Coin", "res://scenes/entities/pickups/Coin.tscn")
		if coin:
			coin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			if coin.has_method("pickup"):
				coin.pickup(null)

	for i in energy_count:
		var orb = ObjectPool.get_object("EnergyOrb", "res://scenes/entities/pickups/EnergyOrb.tscn")
		if orb:
			orb.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			if orb.has_method("pickup"):
				orb.pickup(null)

	GameManager.add_score(score_value)

func _death_animation() -> void:
	hide()
	await get_tree().create_timer(1.0).timeout
	queue_free()
