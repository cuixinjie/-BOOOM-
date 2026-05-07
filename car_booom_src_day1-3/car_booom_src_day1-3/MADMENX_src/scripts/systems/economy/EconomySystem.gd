## EconomySystem — 经济系统
##
## 功能说明：
## - 管理金币、能量等经济资源
## - 提供加减货币接口
## - Day 4扩展：熟练度掉落系统对接
##
## 对接注意事项：
## - 所有货币变动必须通过此系统
## - 货币变动通过 EventBus 广播
## - 熟练度由WeaponProficiencySystem管理
##
## 创建人：cjs（主）、新街（扩展）
## 创建日期：2026-04-28
## 合并日期：2026-05-02
## Day 4扩展：熟练度掉落接口

extends Node

signal coins_changed(amount: int)
signal energy_changed(amount: float)
signal proficiency_changed(amount: float)
signal level_up(new_level: int)

var coins: int = 0
var energy: float = 0.0
var proficiency: float = 0.0

var current_level: int = 1
var proficiency_per_level: float = 100.0

# ===== 掉落配置 =====
var coin_drop_multiplier: float = 1.0
var energy_drop_multiplier: float = 1.0
var proficiency_drop_multiplier: float = 1.0

# ===== 接口定义 =====
## add_coins(amount: int) -> void
##   增加金币
##
## spend_coins(amount: int) -> bool
##   消耗金币，返回是否成功
##
## add_energy(amount: float) -> void
##   增加能量
##
## spend_energy(amount: float) -> bool
##   消耗能量，返回是否成功
##
## add_proficiency(amount: float) -> void
##   增加熟练度
## ===== 接口结束 =====

func _ready() -> void:
	print("[EconomySystem] Initialized")

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	EventBus.coin_collected.emit(amount)
	print("[EconomySystem] Coins: ", coins)

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true

func add_energy(amount: float) -> void:
	energy += amount
	energy_changed.emit(energy)
	EventBus.energy_collected.emit(int(amount))
	print("[EconomySystem] Energy: ", energy)

func spend_energy(amount: float) -> bool:
	if energy < amount:
		return false
	energy -= amount
	energy_changed.emit(energy)
	return true

func add_proficiency(amount: float) -> void:
	proficiency += amount
	EventBus.proficiency_gained.emit(amount)

	while proficiency >= proficiency_per_level:
		proficiency -= proficiency_per_level
		current_level += 1
		level_up.emit(current_level)
		EventBus.level_up.emit(current_level)
		print("[EconomySystem] Level up! Level: ", current_level)

	proficiency_changed.emit(proficiency)

func get_coins() -> int:
	return coins

func get_energy() -> float:
	return energy

func get_level() -> int:
	return current_level

func reset() -> void:
	coins = 0
	energy = 0.0
	proficiency = 0.0
	current_level = 1
	print("[EconomySystem] Reset")

# ===== Day 4 扩展接口 =====

## 设置掉落倍率（用于难度调整）
func set_drop_multipliers(coins_mult: float, energy_mult: float, prof_mult: float) -> void:
	coin_drop_multiplier = coins_mult
	energy_drop_multiplier = energy_mult
	proficiency_drop_multiplier = prof_mult
	print("[EconomySystem] Drop multipliers set: coins=", coin_drop_multiplier,
		  ", energy=", energy_drop_multiplier, ", prof=", proficiency_drop_multiplier)

## 获取掉落倍率
func get_drop_multipliers() -> Dictionary:
	return {
		"coins": coin_drop_multiplier,
		"energy": energy_drop_multiplier,
		"proficiency": proficiency_drop_multiplier
	}

## 应用掉落倍率到数值
func apply_drop_multiplier(base_value: int, drop_type: String) -> int:
	match drop_type:
		"coins":
			return int(base_value * coin_drop_multiplier)
		"energy":
			return int(base_value * energy_drop_multiplier)
		"proficiency":
			return int(base_value * proficiency_drop_multiplier)
		_:
			return base_value

## 获取总熟练度（玩家等级熟练度）
func get_proficiency() -> float:
	return proficiency

## 获取熟练度进度百分比
func get_proficiency_percent() -> float:
	return (proficiency / proficiency_per_level) * 100.0
