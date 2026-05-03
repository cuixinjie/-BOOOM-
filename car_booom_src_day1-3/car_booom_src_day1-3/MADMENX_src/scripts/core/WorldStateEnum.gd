## WorldState — 里世界状态枚举
##
## 功能说明：
## - 表世界/里世界的状态枚举常量
## - 供所有需要判断世界状态的模块使用
##
## 使用方式：
## - 直接使用 WState.NORMAL / WState.INVERTED
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name WState
extends RefCounted

enum WorldState {
	NORMAL,    # 表世界（废土）
	INVERTED   # 里世界（沃土）
}
