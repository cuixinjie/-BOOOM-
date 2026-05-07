## AmmoTypeEnum — 弹药类型枚举
##
## 功能说明：
## - 定义所有弹药类型
## - 提供弹药类型名称和切换成本
##
## 创建人：池言いく
## 创建日期：2026-05-06
## Day 6 任务：弹药类型系统实现

class_name AmmoTypeEnum
extends RefCounted

enum Type {
	NORMAL = 0,
	ARMOR_PIERCING = 1,
	EXPLOSIVE = 2,
	POISON = 3,
	ELECTROMAGNETIC = 4,
	FRAGMENT = 5,
	SNIPER = 6
}

static func get_type_name(t: int) -> String:
	match t:
		Type.NORMAL: return "普通弹"
		Type.ARMOR_PIERCING: return "穿甲弹"
		Type.EXPLOSIVE: return "爆炸弹"
		Type.POISON: return "毒弹"
		Type.ELECTROMAGNETIC: return "电磁弹"
		Type.FRAGMENT: return "子母弹"
		Type.SNIPER: return "狙击弹"
	return "普通弹"

static func get_cost(t: int) -> int:
	match t:
		Type.NORMAL: return 0
		Type.ARMOR_PIERCING: return 15
		Type.EXPLOSIVE: return 20
		Type.POISON: return 15
		Type.ELECTROMAGNETIC: return 20
		Type.FRAGMENT: return 18
		Type.SNIPER: return 15
	return 0
