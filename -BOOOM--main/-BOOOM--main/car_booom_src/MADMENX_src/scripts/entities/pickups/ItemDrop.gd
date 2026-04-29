## ItemDrop — 物品掉落
##
## 功能说明：
## - 可拾取物品的通用实现
## - 支持不同类型物品
##
## 对接注意事项：
## - 场景文件：scenes/entities/pickups/ItemDrop.tscn
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name ItemDrop
extends Pickupable

enum ItemType {
	HEALTH,
	ENERGY,
	AMMO,
	SKILL_BOOST
}

@export var item_type: ItemType = ItemType.HEALTH
@export var item_value: float = 20.0

func _ready() -> void:
	super._ready()

func on_pickup_effect(picker: Node) -> void:
	match item_type:
		ItemType.HEALTH:
			GameManager.repair_vehicle(item_value)
		ItemType.ENERGY:
			EventBus.energy_collected.emit(int(item_value))
		ItemType.AMMO:
			print("[ItemDrop] Ammo pickup")
		ItemType.SKILL_BOOST:
			print("[ItemDrop] Skill boost pickup")
	
	print("[ItemDrop] Item collected: ", ItemType.keys()[item_type])
