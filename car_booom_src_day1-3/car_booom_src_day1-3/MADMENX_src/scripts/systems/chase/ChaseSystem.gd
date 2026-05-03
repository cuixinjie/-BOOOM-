## ChaseSystem — 追兵系统
##
## 功能说明：
## - 管理追兵敌人在后方的追击
## - 距离越近越危险
## - 被追上则游戏结束
##
## 对接注意事项：
## - 追兵通过此系统生成和管理
## - 距离变化通过 EventBus.chase_distance_changed 广播
##
## Day 3修复：处理 ChaseEnemy.tscn 不存在的fallback逻辑，修复重复代码
##
## 创建人：新街（主）、长安旧梦（AI行为）、cjs（修复）
## 创建日期：2026-04-29
## 合并日期：2026-05-02
## 修复日期：2026-05-02

class_name ChaseSystem
extends Node

signal chase_distance_updated(distance: float)
signal player_caught()

const MIN_SAFE_DISTANCE: float = 200.0
const MAX_CHASE_DISTANCE: float = 1200.0
const DEFAULT_CHASE_SPEED: float = 80.0
const GRACE_PERIOD: float = 30.0

var chase_distance: float = MAX_CHASE_DISTANCE
var min_safe_distance: float = MIN_SAFE_DISTANCE
var max_chase_distance: float = MAX_CHASE_DISTANCE
var chase_speed: float = DEFAULT_CHASE_SPEED

var _chase_enemy: Node = null
var _is_chase_active: bool = false
var _chase_spawned: bool = false
var _grace_timer: float = 0.0

# ===== 接口定义 =====
## start_chase() -> void
##   开始追兵
##
## stop_chase() -> void
##   停止追兵
##
## increase_chase_distance(amount: float) -> void
##   增加安全距离
##
## decrease_chase_distance(amount: float) -> void
##   减少安全距离（危险）
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	print("[ChaseSystem] Initialized")

func _connect_signals() -> void:
	if EventBus.has_signal("level_started"):
		EventBus.level_started.connect(start_chase)
	if EventBus.has_signal("level_completed"):
		EventBus.level_completed.connect(stop_chase)
	if EventBus.has_signal("rest_point_entered"):
		EventBus.rest_point_entered.connect(_on_rest_point_entered)

func _process(delta: float) -> void:
	if not _is_chase_active:
		return

	if _grace_timer > 0:
		_grace_timer -= delta
		return

	if _chase_enemy == null or not is_instance_valid(_chase_enemy):
		_spawn_chase_enemy()

	if is_instance_valid(_chase_enemy):
		_update_chase_enemy(delta)
	_check_caught()

func _spawn_chase_enemy() -> void:
	if _chase_spawned:
		return

	var scene_path = "res://scenes/entities/enemies/ChaseEnemy.tscn"
	if not ResourceLoader.exists(scene_path):
		scene_path = "res://scenes/entities/enemies/DroneBasic.tscn"
		print("[ChaseSystem] ChaseEnemy.tscn not found, using DroneBasic as fallback")

	_chase_enemy = ObjectPool.get_object("ChaseEnemy", scene_path)
	if _chase_enemy:
		var vp = get_viewport().get_visible_rect()
		_chase_enemy.global_position = Vector2(vp.size.x + 100, vp.size.y * 0.5)
		_chase_spawned = true
		print("[ChaseSystem] Chase enemy spawned")
	else:
		_chase_spawned = true
		print("[ChaseSystem] Chase active (no visual enemy)")

func _update_chase_enemy(delta: float) -> void:
	chase_distance -= chase_speed * delta
	chase_distance = max(0, chase_distance)
	chase_distance_updated.emit(chase_distance)
	EventBus.chase_distance_changed.emit(chase_distance)

func _check_caught() -> void:
	if chase_distance <= min_safe_distance:
		player_caught.emit()
		EventBus.chase_caught.emit()
		GameManager.end_game(false)
		print("[ChaseSystem] Caught by chase enemy!")

func start_chase() -> void:
	_is_chase_active = true
	chase_distance = max_chase_distance
	_chase_spawned = false
	_chase_enemy = null
	_grace_timer = GRACE_PERIOD
	print("[ChaseSystem] Chase started with ", GRACE_PERIOD, "s grace period")

func stop_chase() -> void:
	_is_chase_active = false
	if is_instance_valid(_chase_enemy):
		ObjectPool.return_object("ChaseEnemy", _chase_enemy)
	_chase_enemy = null
	_chase_spawned = false
	print("[ChaseSystem] Chase stopped")

func increase_chase_distance(amount: float) -> void:
	chase_distance = min(max_chase_distance, chase_distance + amount)

func decrease_chase_distance(amount: float) -> void:
	chase_distance = max(0, chase_distance - amount)

func _on_rest_point_entered() -> void:
	_decrease_chase_intensity()

func _decrease_chase_intensity() -> void:
	chase_distance = max_chase_distance
	chase_speed = 0.0
	_chase_spawned = false
	if is_instance_valid(_chase_enemy):
		ObjectPool.return_object("ChaseEnemy", _chase_enemy)
		_chase_enemy = null
	await get_tree().create_timer(5.0).timeout
	chase_speed = DEFAULT_CHASE_SPEED
