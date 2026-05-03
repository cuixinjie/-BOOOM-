## UIIntegrationTest — UI集成测试工具（增强版）
##
## 功能说明：
## - 自动化测试UI组件
## - 验证EventBus连接
## - 验证全流程UI对接
##
## Day 3增强：完善测试用例，增加错误恢复能力
##
## 创建人：cjs
## 创建日期：2026-04-29

class_name UIIntegrationTest
extends Control

var _test_results: Array = []
var _verbose: bool = false

func _ready() -> void:
	print("[UIIntegrationTest] Starting UI integration tests")
	print("[UIIntegrationTest] Call run_all_tests() to begin")

func run_all_tests() -> void:
	_test_results.clear()
	print("========== UI INTEGRATION TEST ==========")
	_test_hud_visibility()
	_test_coin_system()
	_test_world_state_ui()
	_test_driver_hud()
	_test_shooter_hud()
	_test_menu_controller()
	_test_shop_ui()
	_test_world_state_indicator()
	_print_results()
	print("========================================")

func _test_hud_visibility() -> void:
	var passed = true
	var msg = ""

	if not has_node("/root/Main/HUDController"):
		msg = "HUDController not found in scene tree"
		passed = false
	elif not has_node("/root/Main"):
		msg = "Main scene not loaded"
		passed = false

	_record_result("HUD Exists", passed, msg)
	if _verbose:
		print("[HUD] Visibility test: ", "PASS" if passed else "FAIL - " + msg)

func _test_coin_system() -> void:
	var eco = get_node_or_null("/root/EconomySystem")
	if not eco:
		_record_result("EconomySystem Exists", false, "EconomySystem autoload not found")
		return

	var initial = eco.get_coins()
	eco.add_coins(100)
	var after = eco.get_coins()
	var result = after == initial + 100
	eco.spend_coins(100)
	_record_result("Coin System", result, "" if result else "Expected %d, got %d" % [initial + 100, after])

func _test_world_state_ui() -> void:
	var wsm = get_node_or_null("/root/WorldStateManager")
	if not wsm:
		_record_result("WorldStateManager Exists", false, "Not found")
		return

	var state = wsm.get_current_world()
	_record_result("World State Manager", state == 0 or state == 1, "")

	if wsm.has_signal("world_state_changed"):
		_record_result("WorldStateManager emits world_state_changed", true, "")
	else:
		_record_result("WorldStateManager emits world_state_changed", false, "Missing signal")

func _test_driver_hud() -> void:
	var passed = ResourceLoader.exists("res://scripts/ui/DriverHUD.gd")
	_record_result("DriverHUD Script Exists", passed, "" if passed else "File not found")
	if passed:
		var hud = get_node_or_null("/root/Main/HUDController/DriverHUD")
		if hud:
			_record_result("DriverHUD in scene", true, "")
			if hud.has_method("update_health_bar"):
				_record_result("DriverHUD.update_health_bar", true, "")
			if hud.has_method("update_coins"):
				_record_result("DriverHUD.update_coins", true, "")
			if hud.has_method("update_energy"):
				_record_result("DriverHUD.update_energy", true, "")
		else:
			_record_result("DriverHUD in scene", false, "Not under HUDController")

func _test_shooter_hud() -> void:
	var passed = ResourceLoader.exists("res://scripts/ui/ShooterHUD.gd")
	_record_result("ShooterHUD Script Exists", passed, "" if passed else "File not found")
	if passed:
		var hud = get_node_or_null("/root/Main/HUDController/ShooterHUD")
		if hud:
			_record_result("ShooterHUD in scene", true, "")
			if hud.has_method("update_ammo"):
				_record_result("ShooterHUD.update_ammo", true, "")
			if hud.has_method("update_weapon"):
				_record_result("ShooterHUD.update_weapon", true, "")
		else:
			_record_result("ShooterHUD in scene", false, "Not under HUDController")

func _test_menu_controller() -> void:
	var passed = ResourceLoader.exists("res://scripts/ui/MenuController.gd")
	_record_result("MenuController Script Exists", passed, "" if passed else "File not found")

func _test_shop_ui() -> void:
	var shop_ui = get_node_or_null("/root/Main/HUD/ShopUI")
	if not shop_ui:
		_record_result("ShopUI in scene", false, "Not found under Main/HUD")
		return

	_record_result("ShopUI in scene", true, "")
	if shop_ui.has_method("show_shop"):
		_record_result("ShopUI.show_shop", true, "")
	if shop_ui.has_method("hide_shop"):
		_record_result("ShopUI.hide_shop", true, "")

func _test_world_state_indicator() -> void:
	var wsi = get_node_or_null("/root/Main/HUDController/WorldStateIndicator")
	if not wsi:
		_record_result("WorldStateIndicator in scene", false, "Not found under HUDController")
		return

	_record_result("WorldStateIndicator in scene", true, "")
	if wsi.has_method("show_world_change"):
		_record_result("WorldStateIndicator.show_world_change", true, "")

func _record_result(test_name: String, passed: bool, detail: String = "") -> void:
	_test_results.append({"name": test_name, "passed": passed, "detail": detail})
	var status = "PASS" if passed else "FAIL"
	if detail:
		print("[UITest] %s: %s — %s" % [test_name, status, detail])
	else:
		print("[UITest] %s: %s" % [test_name, status])

func _print_results() -> void:
	var passed = _test_results.filter(func(r): return r["passed"]).size()
	var failed = _test_results.size() - passed
	print("[UITest] Results: %d/%d passed" % [passed, _test_results.size()])
	if failed > 0:
		print("[UITest] FAILED TESTS:")
		for r in _test_results:
			if not r["passed"]:
				print("  - %s: %s" % [r["name"], r["detail"]])
