## Pickupable — 可拾取物品基类
##
## 功能说明：
## - 可被玩家拾取的物品基类
## - 支持自动拾取和手动拾取
##
## 对接注意事项：
## - 被 Coin、EnergyOrb、ItemDrop 继承
## - 拾取通过 EventBus.item_picked_up 广播
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name Pickupable
extends Area2D

signal picked_up(item: Node, picker: Node)

@export var pickup_value: int = 1
@export var auto_pickup_radius: float = 50.0
@export var despawn_time: float = 10.0
@export var is_picked_up: bool = false

var _owner: Node = null
var _despawn_timer: float = 0.0

# ===== 接口定义 =====
## get_pickup_value() -> int
##   获取拾取值（金币数量等）
##
## can_be_picked_up(picker: Node) -> bool
##   检查是否可以被拾取
##
## pickup(picker: Node) -> bool
##   执行拾取操作
##
## on_pickup_effect(picker: Node) -> void
##   拾取后的效果（子类实现）
## ===== 接口结束 =====

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_despawn_timer = despawn_time

func _process(delta: float) -> void:
	if not is_picked_up:
		_despawn_timer -= delta
		if _despawn_timer <= 0:
			despawn()
		_update_visual()

func _update_visual() -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	if is_picked_up:
		return
	
	if area.is_in_group("players") or area.is_in_group("vehicle"):
		if can_be_picked_up(area):
			pickup(area)

func can_be_picked_up(picker: Node) -> bool:
	return not is_picked_up

func pickup(picker: Node) -> bool:
	if is_picked_up:
		return false
	
	if not can_be_picked_up(picker):
		return false
	
	is_picked_up = true
	_owner = picker
	
	on_pickup_effect(picker)
	
	picked_up.emit(self, picker)
	EventBus.item_picked_up.emit(self, picker)
	
	queue_free()
	return true

func on_pickup_effect(picker: Node) -> void:
	pass

func despawn() -> void:
	if not is_picked_up:
		queue_free()
