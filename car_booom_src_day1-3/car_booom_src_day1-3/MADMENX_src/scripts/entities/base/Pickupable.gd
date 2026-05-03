## Pickupable — 可拾取实体基类
##
## 功能说明：
## - 游戏中可拾取物品的基类
## - 支持碰撞检测和自动拾取
## - 支持对象池回收模式
##
## 对接注意事项：
## - 拾取通过 EventBus.item_picked_up 广播
## - 拾取范围通过 collision shape 定义
## - 必须通过 ObjectPool 管理，禁止直接 instance()
##
## 创建人：cjs（主）、长安旧梦（扩展）
## 创建日期：2026-04-28

class_name Pickupable
extends Area2D

signal picked_up(picker: Node)

enum PickupType {
	COIN,
	ENERGY,
	HEALTH,
	AMMO,
	ITEM
}

var pickup_type: PickupType = PickupType.ITEM
var value: int = 1
var auto_despawn_time: float = 10.0
var despawn_timer: float = 0.0

var _is_picked_up: bool = false
var _pool_name: String = ""
var _auto_recycle: bool = true  # 是否在拾取后自动回收池

# ===== 接口定义 =====
## pickup(picker: Node) -> void
##   执行拾取逻辑
##
## on_pickup(picker: Node) -> void
##   拾取成功后的回调，子类可重写
##
## set_value(new_value: int) -> void
##   设置拾取值
## ===== 接口结束 =====

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if auto_despawn_time > 0:
		despawn_timer = auto_despawn_time

func _process(delta: float) -> void:
	if _is_picked_up:
		return
	if auto_despawn_time > 0:
		despawn_timer -= delta
		if despawn_timer <= 0:
			_despawn()

func _on_area_entered(area: Area2D) -> void:
	if _is_picked_up:
		return

	if area.has_method("can_pickup") and area.can_pickup(self):
		pickup(area)
	elif area.get_parent().has_method("on_item_picked_up"):
		pickup(area.get_parent())

func pickup(picker: Node) -> void:
	if _is_picked_up:
		return
	_is_picked_up = true

	on_pickup(picker)
	EventBus.item_picked_up.emit(self, picker)
	picked_up.emit(picker)
	print("[Pickupable] Picked up by: ", picker.name if picker else "unknown")

	if _auto_recycle:
		_recycle_to_pool()
	else:
		queue_free()

func _recycle_to_pool() -> void:
	# 返回对象池而不是直接销毁
	var pool_name = _pool_name if _pool_name != "" else name
	if ObjectPool and ObjectPool.has_method("return_object"):
		ObjectPool.return_object(pool_name, self)
	else:
		queue_free()

func on_pickup(picker: Node) -> void:
	match pickup_type:
		PickupType.COIN:
			EconomySystem.add_coins(value)
			AudioManager.play_coin_sound()
		PickupType.ENERGY:
			EconomySystem.add_energy(value)
		PickupType.HEALTH:
			if picker.has_method("heal"):
				picker.heal(value)

func _despawn() -> void:
	print("[Pickupable] Despawned: ", name)
	_recycle_to_pool()

func set_pool_name(pool_name: String) -> void:
	_pool_name = pool_name

func can_pickup(picker: Node) -> bool:
	return picker.has_method("on_item_picked_up")

func on_spawned() -> void:
	_is_picked_up = false
	despawn_timer = auto_despawn_time
	visible = true

func on_despawned() -> void:
	_is_picked_up = true
	visible = false
