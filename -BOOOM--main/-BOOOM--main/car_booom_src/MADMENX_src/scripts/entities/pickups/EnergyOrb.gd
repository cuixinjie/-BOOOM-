## EnergyOrb — 能量球拾取物
##
## 功能说明：
## - 恢复驾驶员能量
##
## 对接注意事项：
## - 场景文件：scenes/entities/pickups/EnergyOrb.tscn
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name EnergyOrb
extends Pickupable

func _ready() -> void:
	super._ready()
	pickup_value = 20
	despawn_time = 12.0

func on_pickup_effect(picker: Node) -> void:
	EventBus.energy_collected.emit(pickup_value)
	print("[EnergyOrb] Collected ", pickup_value, " energy")
