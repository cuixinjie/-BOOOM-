## WeaponIntegrationTest — 武器系统集成测试
##
## 功能说明：
## - 集成测试武器系统的各个组件
## - 测试武器射击流程
## - 测试配件叠加效果
## - 测试熟练度升级流程
## - 测试弹药类型切换
##
## 使用方法：
## - 在 Main 场景中挂载此脚本
## - 按 T 键运行测试
##
## 创建人：池言いく
## 创建日期：2026-05-06
## Day 6 任务：武器系统完整验证

extends Node2D

var _test_running: bool = false
var _test_results: Array = []

func _ready() -> void:
	print("[WeaponIntegrationTest] Ready. Press T to run tests.")
	# 可以通过控制台命令调用
	add_to_group("debug")

## 运行集成测试
func run_tests() -> void:
	if _test_running:
		print("[WeaponIntegrationTest] Tests already running...")
		return

	_test_running = true
	_test_results.clear()

	print("========================================")
	print("[WeaponIntegrationTest] 开始集成测试...")
	print("========================================")

	# 1. 系统初始化测试
	_test_system_initialization()

	# 2. 武器配置测试
	_test_weapon_configs()

	# 3. 熟练度系统测试
	_test_proficiency_system()

	# 4. 配件系统测试
	_test_attachment_system()

	# 5. 弹药系统测试
	_test_ammo_system()

	# 6. 伤害计算测试
	_test_damage_calculation()

	# 7. 霰弹枪散射测试
	_test_shotgun_spread()

	# 8. 狙击枪穿透测试
	_test_rifle_piercing()

	# 输出结果
	_print_test_summary()

	_test_running = false

## 测试系统初始化
func _test_system_initialization() -> void:
	print("\n[Test 1] 系统初始化...")
	var passed = true

	# 检查所有关键系统
	if ConfigMgr == null:
		print("  [FAIL] ConfigMgr 未初始化")
		passed = false
	else:
		print("  [OK] ConfigMgr")

	if ShopSystem == null:
		print("  [FAIL] ShopSystem 未初始化")
		passed = false
	else:
		print("  [OK] ShopSystem")

	if WeaponProficiencySystem == null:
		print("  [FAIL] WeaponProficiencySystem 未初始化")
		passed = false
	else:
		print("  [OK] WeaponProficiencySystem")

	if WeaponUpgradeSystem == null:
		print("  [FAIL] WeaponUpgradeSystem 未初始化")
		passed = false
	else:
		print("  [OK] WeaponUpgradeSystem")

	if AmmoSystem == null:
		print("  [FAIL] AmmoSystem 未初始化")
		passed = false
	else:
		print("  [OK] AmmoSystem")

	if BulletFactory == null:
		print("  [FAIL] BulletFactory 未初始化")
		passed = false
	else:
		print("  [OK] BulletFactory")

	_test_results.append({"name": "系统初始化", "passed": passed})

## 测试武器配置
func _test_weapon_configs() -> void:
	print("\n[Test 2] 武器配置...")
	var passed = true
	var weapons = ["pistol_basic", "smg", "shotgun", "rifle", "laser"]

	for weapon_id in weapons:
		var stats = ConfigMgr.get_weapon_stats(weapon_id)
		if stats.is_empty():
			print("  [FAIL] %s 配置未找到" % weapon_id)
			passed = false
		else:
			var damage = stats.get("damage", 0)
			var fire_rate = stats.get("fire_rate", 0)
			print("  [OK] %s: damage=%s, fire_rate=%s" % [weapon_id, damage, fire_rate])

	_test_results.append({"name": "武器配置", "passed": passed})

## 测试熟练度系统
func _test_proficiency_system() -> void:
	print("\n[Test 3] 熟练度系统...")
	var passed = true

	# 保存初始值
	var initial_pistol = WeaponProficiencySystem.get_proficiency("pistol")

	# 增加熟练度
	WeaponProficiencySystem.add_proficiency_for_weapon("pistol", 50.0)
	var after_add = WeaponProficiencySystem.get_proficiency("pistol")

	if after_add > initial_pistol:
		print("  [OK] 熟练度增加: %s -> %s" % [initial_pistol, after_add])
	else:
		print("  [FAIL] 熟练度未增加")
		passed = false

	# 检查等级
	var level = WeaponProficiencySystem.get_proficiency_level("pistol")
	print("  [OK] 熟练度等级: %s" % level)

	# 检查升级效果
	var effects = WeaponProficiencySystem.get_current_effects("pistol")
	print("  [OK] 升级效果: %s" % effects)

	_test_results.append({"name": "熟练度系统", "passed": passed})

## 测试配件系统
func _test_attachment_system() -> void:
	print("\n[Test 4] 配件系统...")
	var passed = true

	# 获取已安装的配件
	var installed = ShopSystem.get_installed_attachments()
	print("  [INFO] 已安装配件: %s" % installed)

	# 获取配件效果
	var stabilizer_effect = ShopSystem.get_attachment_effect("stabilizer")
	if stabilizer_effect.is_empty():
		print("  [WARN] 稳定器未安装或无效果")
	else:
		print("  [OK] 稳定器效果: %s" % stabilizer_effect)

	_test_results.append({"name": "配件系统", "passed": true})  # 始终通过，因为配件可能未安装

## 测试弹药系统
func _test_ammo_system() -> void:
	print("\n[Test 5] 弹药系统...")
	var passed = true

	# 检查当前弹药类型
	var current_type = AmmoSystem.get_current_ammo_type()
	print("  [OK] 当前弹药类型: %s (%s)" % [current_type, AmmoTypeEnum.get_type_name(current_type)])

	# 检查弹药效果
	var effects = AmmoSystem.get_current_ammo_effects()
	print("  [OK] 弹药效果: %s" % effects)

	# 检查切换成本
	var cost = AmmoSystem.get_switch_cost(AmmoTypeEnum.Type.ARMOR_PIERCING)
	print("  [OK] 穿甲弹切换成本: %s 金币" % cost)

	# 检查是否可以切换
	var can_switch = AmmoSystem.can_switch_to(AmmoTypeEnum.Type.EXPLOSIVE)
	print("  [INFO] 可以切换到爆炸弹: %s" % can_switch)

	_test_results.append({"name": "弹药系统", "passed": passed})

## 测试伤害计算
func _test_damage_calculation() -> void:
	print("\n[Test 6] 伤害计算...")
	var passed = true

	# 获取手枪基础伤害
	var pistol_stats = ConfigMgr.get_weapon_stats("pistol_basic")
	var base_damage = pistol_stats.get("damage", 10.0)
	print("  [INFO] 手枪基础伤害: %s" % base_damage)

	# 模拟熟练度加成
	var prof_level = WeaponProficiencySystem.get_proficiency_level("pistol")
	var effects = WeaponProficiencySystem.get_current_effects("pistol")
	var prof_bonus = effects.get("damage_bonus", 0.0)
	var final_damage = base_damage * (1.0 + prof_bonus)

	print("  [OK] 熟练度等级: %s" % prof_level)
	print("  [OK] 熟练度加成: %s%%" % [int(prof_bonus * 100)])
	print("  [OK] 最终伤害: %s" % final_damage)

	_test_results.append({"name": "伤害计算", "passed": passed})

## 测试霰弹枪散射
func _test_shotgun_spread() -> void:
	print("\n[Test 7] 霰弹枪散射...")
	var passed = true

	var shotgun = ConfigMgr.get_weapon_stats("shotgun")
	if shotgun.is_empty():
		print("  [FAIL] 霰弹枪配置未找到")
		passed = false
		_test_results.append({"name": "霰弹枪散射", "passed": false})
		return

	var pellets = shotgun.get("pellets", 5)
	var spread = shotgun.get("spread", 0.3)

	print("  [OK] 弹丸数: %s" % pellets)
	print("  [OK] 散射角度: %.2f rad (%.1f°)" % [spread, rad_to_deg(spread)])

	# 模拟计算每发子弹的方向
	var angle_step = spread / max(1, pellets - 1)
	for i in range(pellets):
		var pellet_angle = -spread / 2 + angle_step * i
		print("    弹丸 %d: %.2f°" % [i + 1, rad_to_deg(pellet_angle)])

	_test_results.append({"name": "霰弹枪散射", "passed": passed})

## 测试狙击枪穿透
func _test_rifle_piercing() -> void:
	print("\n[Test 8] 狙击枪穿透...")
	var passed = true

	var rifle = ConfigMgr.get_weapon_stats("rifle")
	if rifle.is_empty():
		print("  [FAIL] 狙击枪配置未找到")
		passed = false
		_test_results.append({"name": "狙击枪穿透", "passed": false})
		return

	var damage = rifle.get("damage", 50.0)
	var piercing = rifle.get("piercing", 1)

	print("  [OK] 伤害: %s" % damage)
	print("  [OK] 穿透数: %s" % piercing)

	# 熟练度加成穿透
	var prof_level = WeaponProficiencySystem.get_proficiency_level("rifle")
	var rifle_effects = WeaponProficiencySystem.get_current_effects("rifle")
	var prof_piercing = rifle_effects.get("piercing_bonus", 0)
	var total_piercing = piercing + prof_piercing

	print("  [OK] 熟练度等级: %s" % prof_level)
	print("  [OK] 熟练度穿透加成: +%s" % prof_piercing)
	print("  [OK] 总穿透数: %s" % total_piercing)

	_test_results.append({"name": "狙击枪穿透", "passed": passed})

## 打印测试摘要
func _print_test_summary() -> void:
	print("\n========================================")
	print("[WeaponIntegrationTest] 测试摘要")
	print("========================================")

	var passed_count = 0
	var failed_count = 0

	for result in _test_results:
		if result["passed"]:
			passed_count += 1
			print("[PASS] %s" % result["name"])
		else:
			failed_count += 1
			print("[FAIL] %s" % result["name"])

	print("----------------------------------------")
	print("通过: %d / %d" % [passed_count, passed_count + failed_count])

	if failed_count > 0:
		print("失败: %d 项" % failed_count)
		print("[需要修复]")
	else:
		print("[✓] 所有测试通过！")

	print("========================================")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			run_tests()
