## EnergyOrb — 能量球
##
## 功能说明：
## - 恢复能量的拾取物
##
## 对接注意事项：
## - 通过 ObjectPool 管理
## - 拾取调用 EconomySystem.add_energy
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name EnergyOrb
extends Pickupable

func _ready() -> void:
	pickup_type = PickupType.ENERGY
	value = 20
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.2, 0.8, 1.0, 1.0)

func on_pickup(picker: Node) -> void:
	EconomySystem.add_energy(value)
	AudioManager.play_sfx("energy_pickup")
	EventBus.energy_collected.emit(value)
	print("[EnergyOrb] Collected ", value, " energy")
