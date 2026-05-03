## WeaponBase — 武器基类
##
## 功能说明：
## - 所有武器的基类
## - 定义武器通用属性
##
## 对接注意事项：
## - 实际射击逻辑在 Shooter 中实现
## - WeaponBase 主要用于配置和数据
##
## 创建人：池言いく
## 创建日期：2026-04-29

class_name WeaponBase
extends Node

var weapon_id: String = ""
var weapon_name: String = ""
var weapon_type: String = "pistol"

var base_damage: float = 10.0
var fire_rate: float = 0.2
var magazine_size: int = 30
var reload_speed: float = 2.0
var bullet_speed: float = 500.0
var piercing: int = 0

# 重命名为 weapon_owner 以避免与 Node 基类的 owner 属性冲突
var weapon_owner: Node = null

# ===== 接口定义 =====
## fire(direction: Vector2) -> void
##   开火
##
## reload() -> void
##   装填
##
## get_damage() -> float
##   获取武器伤害
## ===== 接口结束 =====

func _ready() -> void:
	pass

func fire(direction: Vector2) -> void:
	pass

func reload() -> void:
	pass

func get_damage() -> float:
	return base_damage

func equip() -> void:
	print("[WeaponBase] ", weapon_name, " equipped")

func unequip() -> void:
	print("[WeaponBase] ", weapon_name, " unequipped")
