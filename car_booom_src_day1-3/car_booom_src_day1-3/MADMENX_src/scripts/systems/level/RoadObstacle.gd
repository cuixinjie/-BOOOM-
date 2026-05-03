## RoadObstacle — 路面障碍
##
## 功能说明：
## - 道路上的物理障碍物
## - 碰撞检测和伤害
##
## 对接注意事项：
## - 碰撞后对驾驶员造成伤害并广播 EventBus.vehicle_damaged
##
## 创建人：池言いく
## 创建日期：2026-04-29

class_name RoadObstacle
extends Area2D

enum ObstacleType {
	BARRIER,
	LARGE,
	POTHOLE,
	DEBRIS
}

var obstacle_type: ObstacleType = ObstacleType.BARRIER
var damage: float = 15.0
var speed_penalty: float = 0.5

# ===== 接口定义 =====
## set_obstacle_type(type: ObstacleType) -> void
##   设置障碍类型
##
## get_damage() -> float
##   获取伤害值
## ===== 接口结束 =====

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("is_player") and area.is_player():
		_trigger_effect(area.get_parent())

func _trigger_effect(target) -> void:
	target.damage(damage)
	EventBus.vehicle_damaged.emit(damage)
	print("[RoadObstacle] Hit: ", target.name, " damage: ", damage)
