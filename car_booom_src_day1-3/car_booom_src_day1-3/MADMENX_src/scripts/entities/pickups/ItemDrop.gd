## ItemDrop — 物品掉落
##
## 功能说明：
## - 敌人死亡后掉落的物品
## - 支持多种掉落类型
##
## 对接注意事项：
## - 掉落类型通过 DropType 枚举定义
## - 数值通过 set_drop_info 设置
##
## 创建人：长安旧梦
## 创建日期：2026-04-29

class_name ItemDrop
extends Pickupable

enum DropType {
	AMMO,
	HEALTH,
	SKILL_TOKEN,
	SPECIAL_ITEM
}

var drop_type: DropType = DropType.AMMO
var item_id: String = ""

func _ready() -> void:
	pickup_type = PickupType.ITEM

func set_drop_info(type: DropType, id: String, val: int) -> void:
	drop_type = type
	item_id = id
	value = val

func on_pickup(picker: Node) -> void:
	match drop_type:
		DropType.AMMO:
			if picker.has_method("add_ammo"):
				picker.add_ammo(value)
		DropType.HEALTH:
			if picker.has_method("heal"):
				picker.heal(value)
		DropType.SKILL_TOKEN:
			EconomySystem.add_energy(value)
		DropType.SPECIAL_ITEM:
			pass

	EventBus.drop_spawned.emit(self, global_position)
