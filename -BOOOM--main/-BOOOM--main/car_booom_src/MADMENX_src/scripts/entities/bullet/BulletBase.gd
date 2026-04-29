## BulletBase — 子弹基类
##
## 功能说明：
## - 所有子弹的基类
## - 支持移动、碰撞、伤害
##
## 对接注意事项：
## - 通过 ObjectPool 管理生命周期
## - 命中通过 DamageSystem 处理
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name BulletBase
extends Damager

@export var speed: float = 500.0
@export var lifetime: float = 5.0
@export var pierce_count: int = 0

var _lifetime_timer: float = 0.0
var _pierce_remaining: int = 0
var _direction: Vector2 = Vector2.ZERO

var _hit_targets: Array = []

# ===== 接口定义 =====
## fire(direction: Vector2, damage_amount: float) -> void
##   发射子弹
##
## on_spawned() -> void
##   从对象池取出时调用
##
## on_despawned() -> void
##   归还对象池时调用
## ===== 接口结束 =====

func _ready() -> void:
	super._ready()
	add_to_group("bullets")

func _physics_process(delta: float) -> void:
	var motion = _direction * speed * delta
	var collision = move_and_collide(motion)
	
	if collision:
		_handle_collision(collision)
	
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		despawn()

func on_spawned() -> void:
	_lifetime_timer = lifetime
	_pierce_remaining = pierce_count
	_hit_targets.clear()
	_owner = null

func on_despawned() -> void:
	_direction = Vector2.ZERO
	_hit_targets.clear()

func fire(direction: Vector2, damage_amount: float) -> void:
	_direction = direction.normalized()
	damage = damage_amount
	rotation = _direction.angle()

func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	
	if collider in _hit_targets:
		return
	
	if collider.has_method("_take_damage") or collider.has_method("take_damage"):
		_hit_targets.append(collider)
		on_hit(collider)
		
		if _pierce_remaining > 0:
			_pierce_remaining -= 1
		else:
			despawn()

func despawn() -> void:
	ObjectPool.return_object(_get_pool_name(), self)

func _get_pool_name() -> String:
	return "bullet_base"
