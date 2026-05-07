## IntegrationTest — 全系统集成测试
##
## 功能说明：
## - Day 5 全系统集成测试
## - 验证 Day 1-4 完成的所有系统
## - 自动检测配置加载、信号连接、对象池等
##
## 运行方式：
## - 在游戏中按下 F3 打开调试面板
## - 或在 _ready() 中自动运行
##
## 创建人：cjs
## 创建日期：2026-05-06
## Day 5 任务：全系统集成测试

extends Node

signal test_completed(results: Dictionary)
signal test_failed(category: String, test_name: String, error: String)

var _test_results: Dictionary = {}
var _test_categories: Array = []

func _ready() -> void:
	print("[IntegrationTest] System ready, waiting for game start...")
	_connect_signals()

func _connect_signals() -> void:
	EventBus.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	print("[IntegrationTest] Game started, running integration tests...")
	await get_tree().create_timer(1.0).timeout
	run_all_tests()

## 运行所有测试
func run_all_tests() -> void:
	_test_results.clear()
	_test_categories = [
		"autoload_systems",
		"event_bus",
		"object_pool",
		"economy_system",
		"weapon_system",
		"proficiency_system",
		"shop_system",
		"ui_system"
	]
	
	for category in _test_categories:
		_test_results[category] = {"passed": 0, "failed": 0, "tests": []}
	
	# 运行测试
	_test_autoload_systems()
	_test_event_bus()
	_test_object_pool()
	_test_economy_system()
	_test_weapon_system()
	_test_proficiency_system()
	_test_shop_system()
	_test_ui_system()
	
	_print_results()
	test_completed.emit(_test_results)

## 测试自动加载系统
func _test_autoload_systems() -> void:
	var category = "autoload_systems"
	var required_systems = [
		"EventBus",
		"GameManager",
		"ObjectPool",
		"EconomySystem",
		"ConfigMgr",
		"WeaponProficiencySystem"
	]
	
	for system_name in required_systems:
		var passed = false
		var error_msg = ""
		
		if has_node("/root/" + system_name):
			var system = get_node("/root/" + system_name)
			if is_instance_valid(system):
				passed = true
			else:
				error_msg = "Instance is not valid"
		else:
			error_msg = "Autoload not found"
		
		_record_test(category, system_name, passed, error_msg)

## 测试EventBus信号
func _test_event_bus() -> void:
	var category = "event_bus"
	var required_signals = [
		"game_started",
		"game_over",
		"enemy_killed",
		"vehicle_damaged",
		"coin_collected",
		"energy_collected",
		"proficiency_gained",
		"level_up",
		"weapon_fired",
		"shop_purchased"
	]
	
	var eb = get_node_or_null("/root/EventBus")
	if not eb:
		for sig in required_signals:
			_record_test(category, "signal_" + sig, false, "EventBus not found")
		return
	
	for signal_name in required_signals:
		var passed = eb.has_signal(signal_name)
		_record_test(category, "signal_" + signal_name, passed, 
			"Signal not found: " + signal_name if not passed else "")

## 测试对象池
func _test_object_pool() -> void:
	var category = "object_pool"
	var pool = get_node_or_null("/root/ObjectPool")
	
	if not pool:
		_record_test(category, "object_pool_exists", false, "ObjectPool autoload not found")
		return
	
	_record_test(category, "object_pool_exists", true)
	
	# 检查对象池接口
	var interface_tests = [
		"create_pool",
		"get_object",
		"return_object",
		"clear_pool"
	]
	
	for method in interface_tests:
		var has_method = pool.has_method(method)
		_record_test(category, "pool_method_" + method, has_method,
			"Method not found: " + method if not has_method else "")

## 测试经济系统
func _test_economy_system() -> void:
	var category = "economy_system"
	var eco = get_node_or_null("/root/EconomySystem")
	
	if not eco:
		_record_test(category, "economy_system_exists", false, "EconomySystem not found")
		return
	
	_record_test(category, "economy_system_exists", true)
	
	# 测试接口
	var methods = ["add_coins", "spend_coins", "add_energy", "spend_energy", 
				  "add_proficiency", "get_coins", "get_energy", "reset"]
	
	for method in methods:
		var has_method = eco.has_method(method)
		_record_test(category, "eco_method_" + method, has_method,
			"Method not found: " + method if not has_method else "")
	
	# 测试信号
	var signals = ["coins_changed", "energy_changed", "proficiency_changed", "level_up"]
	for sig in signals:
		var has_signal = eco.has_signal(sig)
		_record_test(category, "eco_signal_" + sig, has_signal,
			"Signal not found: " + sig if not has_signal else "")

## 测试武器系统
func _test_weapon_system() -> void:
	var category = "weapon_system"
	var config_mgr = get_node_or_null("/root/ConfigMgr")
	
	if not config_mgr:
		_record_test(category, "config_manager_exists", false, "ConfigMgr not found")
		return
	
	_record_test(category, "config_manager_exists", true)
	
	# 测试武器配置加载
	if config_mgr.has_method("get_weapon_stats"):
		var pistol_stats = config_mgr.get_weapon_stats("pistol_basic")
		var has_pistol = not pistol_stats.is_empty()
		_record_test(category, "weapon_config_pistol", has_pistol,
			"pistol_basic config not found" if not has_pistol else "")
		
		if has_pistol:
			var has_damage = pistol_stats.has("damage")
			var has_fire_rate = pistol_stats.has("fire_rate")
			_record_test(category, "weapon_config_has_damage", has_damage,
				"pistol damage field missing" if not has_damage else "")
			_record_test(category, "weapon_config_has_fire_rate", has_fire_rate,
				"pistol fire_rate field missing" if not has_fire_rate else "")
	else:
		_record_test(category, "config_mgr_get_weapon_stats", false, "Method not found")

## 测试熟练度系统
func _test_proficiency_system() -> void:
	var category = "proficiency_system"
	var prof = get_node_or_null("/root/WeaponProficiencySystem")
	
	if not prof:
		_record_test(category, "proficiency_system_exists", false, "WeaponProficiencySystem not found")
		return
	
	_record_test(category, "proficiency_system_exists", true)
	
	# 测试接口
	var methods = ["add_proficiency_for_weapon", "get_proficiency_level", 
				   "get_proficiency_progress", "get_current_effects"]
	
	for method in methods:
		var has_method = prof.has_method(method)
		_record_test(category, "prof_method_" + method, has_method,
			"Method not found: " + method if not has_method else "")

## 测试商店系统
func _test_shop_system() -> void:
	var category = "shop_system"
	var shop = get_node_or_null("/root/ShopSystem")
	
	if not shop:
		_record_test(category, "shop_system_exists", false, "ShopSystem not found")
		return
	
	_record_test(category, "shop_system_exists", true)
	
	# 测试接口
	var methods = ["purchase_item", "can_afford", "get_item_price", 
				   "is_item_purchased", "get_shop_items"]
	
	for method in methods:
		var has_method = shop.has_method(method)
		_record_test(category, "shop_method_" + method, has_method,
			"Method not found: " + method if not has_method else "")

## 测试UI系统
func _test_ui_system() -> void:
	var category = "ui_system"
	
	# 测试HUD节点
	var test_results = [
		["hud_controller_exists", get_node_or_null("/root/Main/HUD") != null],
	]
	
	for test in test_results:
		_record_test(category, test[0], test[1], 
			"UI node not found: " + test[0] if not test[1] else "")

## 记录测试结果
func _record_test(category: String, test_name: String, passed: bool, error_msg: String) -> void:
	var result = {
		"name": test_name,
		"passed": passed,
		"error": error_msg
	}
	
	_test_results[category]["tests"].append(result)
	
	if passed:
		_test_results[category]["passed"] += 1
		print("[IntegrationTest] PASS: ", category, " / ", test_name)
	else:
		_test_results[category]["failed"] += 1
		push_warning("[IntegrationTest] FAIL: " + category + " / " + test_name + " - " + error_msg)
		test_failed.emit(category, test_name, error_msg)

## 打印测试结果
func _print_results() -> void:
	print("\n" + "=".repeat(60))
	print("        INTEGRATION TEST RESULTS")
	print("=".repeat(60))
	
	var total_passed = 0
	var total_failed = 0
	
	for category in _test_categories:
		var results = _test_results[category]
		var passed = results["passed"]
		var failed = results["failed"]
		total_passed += passed
		total_failed += failed
		
		var status = "OK" if failed == 0 else "FAIL"
		print("\n[%s] %s: %d passed, %d failed" % [status, category, passed, failed])
		
		if failed > 0:
			for test in results["tests"]:
				if not test["passed"]:
					print("  - %s: %s" % [test["name"], test["error"]])
	
	print("\n" + "-".repeat(60))
	var total = total_passed + total_failed
	var pass_rate = (float(total_passed) / float(total) * 100.0) if total > 0 else 0.0
	print("TOTAL: %d/%d passed (%.1f%%)" % [total_passed, total, pass_rate])
	print("=".repeat(60))
	
	if total_failed == 0:
		print("\n[IntegrationTest] ALL TESTS PASSED!")
	else:
		push_warning("\n[IntegrationTest] SOME TESTS FAILED - Review output above")

## 获取测试结果摘要
func get_summary() -> String:
	var total_passed = 0
	var total_failed = 0
	
	for category in _test_results:
		total_passed += _test_results[category]["passed"]
		total_failed += _test_results[category]["failed"]
	
	var total = total_passed + total_failed
	var pass_rate = (float(total_passed) / float(total) * 100.0) if total > 0 else 0.0
	
	return "Tests: %d passed, %d failed (%.1f%%)" % [total_passed, total_failed, pass_rate]
