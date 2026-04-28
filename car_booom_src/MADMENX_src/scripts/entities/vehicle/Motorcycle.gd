## Motorcycle — 摩托车
##
## 功能说明：
## - 具体机车实现
## - 继承 VehicleController
##
## 对接注意事项：
## - 场景文件：scenes/entities/vehicles/Motorcycle.tscn
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name Motorcycle
extends VehicleController

@export var max_health: float = 100.0

func _ready() -> void:
	super._ready()
	entity_name = "Motorcycle"
	print("[Motorcycle] Initialized")
