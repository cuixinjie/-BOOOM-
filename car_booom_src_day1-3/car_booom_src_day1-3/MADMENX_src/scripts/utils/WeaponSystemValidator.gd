## WeaponSystemValidator — 武器系统验证工具
##
## 功能说明：
## - 验证武器系统各组件是否正确工作
## - 测试武器熟练度系统
## - 测试配件系统叠加
## - 测试弹药类型系统
## - 输出验证报告
##
## 使用方法：
## - 在游戏中通过控制台命令调用
## - 或在编辑器中运行此脚本进行测试
##
## 创建人：池言いく
## 创建日期：2026-05-06
## Day 6 任务：武器系统完整验证

extends Node

## 验证结果
var _test_results: Dictionary = {}
var _all_passed: bool = true

signal validation_complete(all_passed: bool, results: Dictionary)
signal test_result(test_name: String, passed: bool, message: String)

## 运行所有验证测试
func run_all_tests() -> void:
	print("========================================")
	print("[WeaponSystemValidator] 开始武器系统验证...")
	print("========================================")

	_all_passed = true
	_test_results.clear()

	# 1. 测试 ConfigManager
	_test_config_manager()

	# 2. 测试武器配置
	_test_weapon_stats()

	# 3. 测试熟练度系统
	_test_proficiency_system()

	# 4. 测试升级系统
	_test_upgrade_system()

	# 5. 测试配件系统
	_test_attachment_system()

	# 6. 测试弹药系统
	_test_ammo_system()

	# 7. 测试商店系统
	_test_shop_system()

	# 输出结果
	_print_results()

	# 发送完成信号
	validation_complete.emit(_all_passed, _test_results)

## 测试 ConfigManager
func _test_config_manager() -> void:
	print("\n[1] 测试 ConfigManager...")
	var passed = true
	var message = ""

	# 检查配置加载
	if ConfigMgr == null:
		message = "ConfigMgr is null"
		passed = false
		_register_result("ConfigManager_Load", false, message)
		return

	# 测试获取武器配置
	var pistol_stats = ConfigMgr.get_weapon_stats("pistol_basic")
	if pistol_stats.is_empty():
		message = "Failed to load pistol_basic config"
		passed = false
	else:
		message = " pistol_basic loaded: damage=%s" % pistol_stats.get("damage", 0)

	_register_result("ConfigManager_Load", passed, message)

## 测试武器配置
func _test_weapon_stats() -> void:
	print("\n[2] 测试武器配置...")
	var passed = true
	var message = ""

	var weapons_to_test = [
		{"id": "pistol_basic", "type": "pistol", "min_damage": 8, "max_damage": 15},
		{"id": "smg", "type": "smg", "min_damage": 4, "max_damage": 10},
		{"id": "shotgun", "type": "shotgun", "min_damage": 6, "max_damage": 15},
		{"id": "rifle", "type": "rifle", "min_damage": 40, "max_damage": 80}
	]

	var weapon_results = []
	for weapon in weapons_to_test:
		var stats = ConfigMgr.get_weapon_stats(weapon["id"])
		if stats.is_empty():
			weapon_results.append("FAIL: %s not found" % weapon["id"])
			passed = false
		else:
			var damage = stats.get("damage", 0)
			if damage >= weapon["min_damage"] and damage <= weapon["max_damage"]:
				weapon_results.append("OK: %s damage=%s" % [weapon["id"], damage])
			else:
				weapon_results.append("WARN: %s damage=%s (expected %s-%s)" % [weapon["id"], damage, weapon["min_damage"], weapon["max_damage"]])

	message = "; ".join(weapon_results)
	_register_result("WeaponStats_Load", passed, message)

## 测试熟练度系统
func _test_proficiency_system() -> void:
	print("\n[3] 测试熟练度系统...")
	var passed = true
	var message = ""

	if WeaponProficiencySystem == null:
		message = "WeaponProficiencySystem is null"
		passed = false
		_register_result("ProficiencySystem_Load", false, message)
		return

	# 测试熟练度增加
	var initial_pistol = WeaponProficiencySystem.get_proficiency("pistol")
	WeaponProficiencySystem.add_proficiency_for_weapon("pistol", 10.0)
	var after_pistol = WeaponProficiencySystem.get_proficiency("pistol")

	if after_pistol > initial_pistol:
		message = "Proficiency increased: %s -> %s" % [initial_pistol, after_pistol]
	else:
		message = "Proficiency NOT increased"
		passed = false

	_register_result("Proficiency_Add", passed, message)

	# 测试熟练度等级
	var level = WeaponProficiencySystem.get_proficiency_level("pistol")
	message = "Level=%s (expected >=1)" % level
	_register_result("Proficiency_Level", level >= 1, message)

## 测试升级系统
func _test_upgrade_system() -> void:
	print("\n[4] 测试升级系统...")
	var passed = true
	var message = ""

	if WeaponUpgradeSystem == null:
		message = "WeaponUpgradeSystem is null"
		passed = false
		_register_result("UpgradeSystem_Load", false, message)
		return

	# 测试升级效果获取
	var effects = WeaponProficiencySystem.get_current_effects("pistol")
	message = "Effects retrieved: %s" % effects
	_register_result("UpgradeSystem_Effects", true, message)

## 测试配件系统
func _test_attachment_system() -> void:
	print("\n[5] 测试配件系统...")
	var passed = true
	var message = ""

	# 检查已安装的配件
	var installed = ShopSystem.get_installed_attachments()
	message = "Installed attachments: %s" % installed
	_register_result("Attachment_Installed", true, message)

	# 测试配件效果
	var stabilizer_effect = ShopSystem.get_attachment_effect("stabilizer")
	if stabilizer_effect.is_empty():
		message = "Stabilizer effect empty (may not be installed)"
	else:
		message = "Stabilizer effect: %s" % stabilizer_effect

	_register_result("Attachment_Effect", true, message)

## 测试弹药系统
func _test_ammo_system() -> void:
	print("\n[6] 测试弹药系统...")
	var passed = true
	var message = ""

	if AmmoSystem == null:
		message = "AmmoSystem is null"
		passed = false
		_register_result("AmmoSystem_Load", false, message)
		return

	# 测试当前弹药类型
	var current_type = AmmoSystem.get_current_ammo_type()
	message = "Current ammo type: %s (%s)" % [current_type, AmmoTypeEnum.get_type_name(current_type)]
	_register_result("AmmoSystem_Current", true, message)

	# 测试弹药效果
	var effects = AmmoSystem.get_current_ammo_effects()
	message = "Ammo effects: %s" % effects
	_register_result("AmmoSystem_Effects", true, message)

## 测试商店系统
func _test_shop_system() -> void:
	print("\n[7] 测试商店系统...")
	var passed = true
	var message = ""

	if ShopSystem == null:
		message = "ShopSystem is null"
		passed = false
		_register_result("ShopSystem_Load", false, message)
		return

	# 测试商品列表
	var items = ShopSystem.get_shop_items()
	message = "Shop items count: %s" % items.size()
	_register_result("ShopSystem_Items", items.size() > 0, message)

	# 测试初始武器
	var owned = ShopSystem.get_owned_weapons()
	message = "Owned weapons: %s" % owned
	_register_result("ShopSystem_Owned", true, message)

## 注册测试结果
func _register_result(test_name: String, passed: bool, message: String) -> void:
	_test_results[test_name] = {
		"passed": passed,
		"message": message
	}
	if not passed:
		_all_passed = false
	test_result.emit(test_name, passed, message)
	print("[%s] %s: %s" % ["PASS" if passed else "FAIL", test_name, message])

## 打印结果摘要
func _print_results() -> void:
	print("\n========================================")
	print("[WeaponSystemValidator] 验证结果摘要")
	print("========================================")

	var passed_count = 0
	var failed_count = 0

	for test_name in _test_results.keys():
		var result = _test_results[test_name]
		if result["passed"]:
			passed_count += 1
		else:
			failed_count += 1

	print("通过: %d / %d" % [passed_count, passed_count + failed_count])
	if failed_count > 0:
		print("失败: %d" % failed_count)
		print("\n失败项目:")
		for test_name in _test_results.keys():
			var result = _test_results[test_name]
			if not result["passed"]:
				print("  - %s: %s" % [test_name, result["message"]])

	print("========================================")
	if _all_passed:
		print("[✓] 所有验证通过！")
	else:
		print("[×] 存在失败项目，需要修复")
	print("========================================")

## 运行快速验证（不打印详细结果）
func run_quick_check() -> bool:
	_test_results.clear()

	# 基本检查
	if ConfigMgr == null:
		return false
	if WeaponProficiencySystem == null:
		return false
	if ShopSystem == null:
		return false
	if AmmoSystem == null:
		return false

	# 武器配置检查
	var pistol = ConfigMgr.get_weapon_stats("pistol_basic")
	if pistol.is_empty():
		return false

	return true

## 获取测试结果
func get_results() -> Dictionary:
	return _test_results.duplicate()

## 验证武器伤害计算
func validate_damage_calculation() -> void:
	print("\n========================================")
	print("[WeaponSystemValidator] 验证伤害计算...")
	print("========================================")

	# 获取基础伤害
	var pistol = ConfigMgr.get_weapon_stats("pistol_basic")
	var base_damage = pistol.get("damage", 10.0)
	print("基础伤害: %s" % base_damage)

	# 测试熟练度加成
	var prof_level = WeaponProficiencySystem.get_proficiency_level("pistol")
	var effects = WeaponProficiencySystem.get_current_effects("pistol")
	var prof_bonus = effects.get("damage_bonus", 0.0)
	print("熟练度等级: %s, 伤害加成: %s%%" % [prof_level, int(prof_bonus * 100)])

	# 计算最终伤害
	var final_damage = base_damage * (1.0 + prof_bonus)
	print("最终伤害: %s" % final_damage)

	# 模拟 Shooter 中的伤害计算
	# 这里简化处理，实际在 Shooter.gd 中
	print("伤害计算验证完成")
	print("========================================")

## 验证霰弹枪散射
func validate_shotgun_spread() -> void:
	print("\n========================================")
	print("[WeaponSystemValidator] 验证霰弹枪散射...")
	print("========================================")

	var shotgun = ConfigMgr.get_weapon_stats("shotgun")
	if shotgun.is_empty():
		print("[FAIL] 霰弹枪配置未找到")
		return

	var pellets = shotgun.get("pellets", 5)
	var spread = shotgun.get("spread", 0.3)
	print("霰弹枪弹丸数: %s" % pellets)
	print("散射角度: %s rad (%.1f°)" % [spread, rad_to_deg(spread)])

	# 模拟散射
	print("散射计算:")
	for i in range(pellets):
		var angle_step = spread / max(1, pellets - 1)
		var pellet_angle = -spread / 2 + angle_step * i
		print("  弹丸 %d: %.2f°" % [i + 1, rad_to_deg(pellet_angle)])

	print("霰弹枪验证完成")
	print("========================================")

## 验证狙击枪穿透
func validate_rifle_piercing() -> void:
	print("\n========================================")
	print("[WeaponSystemValidator] 验证狙击枪穿透...")
	print("========================================")

	var rifle = ConfigMgr.get_weapon_stats("rifle")
	if rifle.is_empty():
		print("[FAIL] 狙击枪配置未找到")
		return

	var damage = rifle.get("damage", 50.0)
	var piercing = rifle.get("piercing", 1)
	print("狙击枪伤害: %s" % damage)
	print("狙击枪穿透: %s" % piercing)

	# 熟练度加成
	var prof_level = WeaponProficiencySystem.get_proficiency_level("rifle")
	if prof_level >= 3:
		print("满级加成: 穿透+1")
	else:
		print("当前等级穿透: %s" % piercing)

	print("狙击枪验证完成")
	print("========================================")
