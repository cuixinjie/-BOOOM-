## Entity — 实体基类
##
## 功能说明：
## - 所有游戏实体的基类
## - 提供基础的位置、移动、碰撞属性
##
## 对接注意事项：
## - 被 LivingEntity、Damager、Pickupable 继承
## - 不应被 Systems 层直接访问
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name Entity
extends CharacterBody2D

signal position_changed(new_position: Vector2)
signal entity_destroyed(entity: Node)

@export var entity_name: String = "Entity"
@export var entity_type: String = "generic"

var _velocity: Vector2 = Vector2.ZERO
var _max_speed: float = 200.0
var _is_active: bool = true

# ===== 接口定义 =====
## get_velocity() -> Vector2
##   获取当前速度
##
## set_velocity(vel: Vector2) -> void
##   设置速度
##
## get_max_speed() -> float
##   获取最大速度
##
## set_max_speed(speed: float) -> void
##   设置最大速度
##
## is_active() -> bool
##   返回实体是否活跃
##
## set_active(active: bool) -> void
##   设置活跃状态
##
## destroy() -> void
##   销毁实体
## ===== 接口结束 =====

func _ready() -> void:
	add_to_group("entities")

func _physics_process(delta: float) -> void:
	if _is_active:
		var motion = _velocity * delta
		var collision = move_and_collide(motion)
		if collision:
			_on_collision(collision)

func _process(delta: float) -> void:
	if position_changed.get_connection_count() > 0:
		position_changed.emit(position)

func _on_collision(collision: KinematicCollision2D) -> void:
	pass

func get_velocity() -> Vector2:
	return _velocity

func set_velocity(vel: Vector2) -> void:
	_velocity = vel

func get_max_speed() -> float:
	return _max_speed

func set_max_speed(speed: float) -> void:
	_max_speed = speed

func is_active() -> bool:
	return _is_active

func set_active(active: bool) -> void:
	_is_active = active
	set_process(active)
	set_physics_process(active)
	visible = active

func destroy() -> void:
	entity_destroyed.emit(self)
	queue_free()
