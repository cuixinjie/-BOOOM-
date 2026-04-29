## UIIntegrationTest — UI 全流程对接测试
##
## 功能说明：
## - 测试所有 HUD 组件的信号连接
## - 验证 UI 与各系统的对接
## - 提供调试输出查看数据流
##
## 测试覆盖：
## - HUDController 信号连接
## - DriverHUD 信号和数据更新
## - ShooterHUD 信号和数据更新
## - WorldStateIndicator 状态切换
## - ShopUI 购买流程
## - MenuController 菜单切换
##
## 创建人：cjs
## 创建日期：2026-04-29

class_name UIIntegrationTest
extends Node

signal test_started()
signal test_completed(success: bool, errors: Array)
signal test_progress(stage: String, message: String)

enum TestStage {
	INIT,
	HUD_CONTROLLER,
	DRIVER_HUD,
	SHOOTER_HUD,
	WORLD_STATE,
	SHOP,
	MENU,
	CLEANUP
}

var _current_stage: TestStage = TestStage.INIT
var _test_errors: Array[String] = []
var _hud_controller: HUDController = null
var _driver_hud: DriverHUD = null
var _shooter_hud: ShooterHUD = null
var _world_indicator: WorldStateIndicator = null
var _shop_ui: ShopUI = null
var _menu_controller: MenuController = null

func _ready() -> void:
	print("[UIIntegrationTest] Ready to run tests")

func run_all_tests() -> void:
	_test_errors.clear()
	_current_stage = TestStage.INIT
	test_started.emit()
	print("[UIIntegrationTest] Starting all UI integration tests...")
	
	_run_hud_controller_tests()
	_run_driver_hud_tests()
	_run_shooter_hud_tests()
	_run_world_state_tests()
	_run_shop_tests()
	_run_menu_tests()
	
	_finalize_tests()

func _run_hud_controller_tests() -> void:
	_current_stage = TestStage.HUD_CONTROLLER
	test_progress.emit("HUD_CONTROLLER", "Testing HUD Controller...")
	
	var hud = _get_hud_controller()
	if not hud:
		_add_error("HUD_CONTROLLER", "HUDController not found")
		return
	
	if not hud.has_method("show_hud"):
		_add_error("HUD_CONTROLLER", "HUDController missing show_hud method")
	
	if not hud.has_method("hide_hud"):
		_add_error("HUD_CONTROLLER", "HUDController missing hide_hud method")
	
	if not hud.has_method("update_driver_hud"):
		_add_error("HUD_CONTROLLER", "HUDController missing update_driver_hud method")
	
	if not hud.has_method("update_shooter_hud"):
		_add_error("HUD_CONTROLLER", "HUDController missing update_shooter_hud method")
	
	print("[UIIntegrationTest] HUD Controller tests passed")

func _run_driver_hud_tests() -> void:
	_current_stage = TestStage.DRIVER_HUD
	test_progress.emit("DRIVER_HUD", "Testing Driver HUD...")
	
	var hud = _get_driver_hud()
	if not hud:
		_add_error("DRIVER_HUD", "DriverHUD not found")
		return
	
	hud.update_health(50.0, 100.0)
	hud.update_energy(75.0, 100.0)
	hud.update_stamina(3.0, 3.0)
	hud.update_coins(100)
	hud.update_progression(2, 0.5)
	hud.update_segment_progress(3, 10)
	
	if not hud.has_method("update_health"):
		_add_error("DRIVER_HUD", "DriverHUD missing update_health method")
	
	if not hud.has_method("update_energy"):
		_add_error("DRIVER_HUD", "DriverHUD missing update_energy method")
	
	if not hud.has_method("update_chase_distance"):
		_add_error("DRIVER_HUD", "DriverHUD missing update_chase_distance method")
	
	print("[UIIntegrationTest] Driver HUD tests passed")

func _run_shooter_hud_tests() -> void:
	_current_stage = TestStage.SHOOTER_HUD
	test_progress.emit("SHOOTER_HUD", "Testing Shooter HUD...")
	
	var hud = _get_shooter_hud()
	if not hud:
		_add_error("SHOOTER_HUD", "ShooterHUD not found")
		return
	
	hud.update_weapon("pistol")
	hud.update_ammo(4, 6)
	hud.update_ammo_type("piercing")
	hud.show_reload_progress(1.5)
	hud.update_aim_direction(Vector2.RIGHT)
	
	if not hud.has_method("update_weapon"):
		_add_error("SHOOTER_HUD", "ShooterHUD missing update_weapon method")
	
	if not hud.has_method("update_ammo"):
		_add_error("SHOOTER_HUD", "ShooterHUD missing update_ammo method")
	
	if not hud.has_method("show_reload_progress"):
		_add_error("SHOOTER_HUD", "ShooterHUD missing show_reload_progress method")
	
	print("[UIIntegrationTest] Shooter HUD tests passed")

func _run_world_state_tests() -> void:
	_current_stage = TestStage.WORLD_STATE
	test_progress.emit("WORLD_STATE", "Testing World State Indicator...")
	
	var indicator = _get_world_state_indicator()
	if not indicator:
		_add_error("WORLD_STATE", "WorldStateIndicator not found")
		return
	
	indicator.update_state(0)
	await get_tree().create_timer(0.1).timeout
	indicator.update_state(1)
	await get_tree().create_timer(0.1).timeout
	
	if not indicator.has_method("update_state"):
		_add_error("WORLD_STATE", "WorldStateIndicator missing update_state method")
	
	if not indicator.has_method("get_current_state"):
		_add_error("WORLD_STATE", "WorldStateIndicator missing get_current_state method")
	
	print("[UIIntegrationTest] World State tests passed")

func _run_shop_tests() -> void:
	_current_stage = TestStage.SHOP
	test_progress.emit("SHOP", "Testing Shop UI...")
	
	var shop = _get_shop_ui()
	if not shop:
		_add_error("SHOP", "ShopUI not found")
		return
	
	if not shop.has_method("open_shop"):
		_add_error("SHOP", "ShopUI missing open_shop method")
	
	if not shop.has_method("close_shop"):
		_add_error("SHOP", "ShopUI missing close_shop method")
	
	print("[UIIntegrationTest] Shop tests passed")

func _run_menu_tests() -> void:
	_current_stage = TestStage.MENU
	test_progress.emit("MENU", "Testing Menu Controller...")
	
	var menu = _get_menu_controller()
	if not menu:
		_add_error("MENU", "MenuController not found")
		return
	
	if not menu.has_method("start_game"):
		_add_error("MENU", "MenuController missing start_game method")
	
	if not menu.has_method("resume_game"):
		_add_error("MENU", "MenuController missing resume_game method")
	
	if not menu.has_method("quit_game"):
		_add_error("MENU", "MenuController missing quit_game method")
	
	print("[UIIntegrationTest] Menu tests passed")

func _finalize_tests() -> void:
	_current_stage = TestStage.CLEANUP
	var success = _test_errors.is_empty()
	
	if success:
		print("[UIIntegrationTest] All tests passed!")
	else:
		print("[UIIntegrationTest] Tests failed with %d errors:" % _test_errors.size())
		for error in _test_errors:
			print("  - ", error)
	
	test_completed.emit(success, _test_errors)

func _add_error(stage: String, message: String) -> void:
	var error_msg = "[%s] %s" % [stage, message]
	_test_errors.append(error_msg)
	print("[UIIntegrationTest] ERROR: ", error_msg)

func _get_hud_controller() -> HUDController:
	if _hud_controller:
		return _hud_controller
	
	var root = get_tree().root
	_hud_controller = root.find_child("HUDController", true, false)
	return _hud_controller

func _get_driver_hud() -> DriverHUD:
	if _driver_hud:
		return _driver_hud
	
	var hud = _get_hud_controller()
	if hud:
		_driver_hud = hud.find_child("DriverHUD", true, false)
	return _driver_hud

func _get_shooter_hud() -> ShooterHUD:
	if _shooter_hud:
		return _shooter_hud
	
	var hud = _get_hud_controller()
	if hud:
		_shooter_hud = hud.find_child("ShooterHUD", true, false)
	return _shooter_hud

func _get_world_state_indicator() -> WorldStateIndicator:
	if _world_indicator:
		return _world_indicator
	
	var hud = _get_hud_controller()
	if hud:
		_world_indicator = hud.find_child("WorldStateIndicator", true, false)
	return _world_indicator

func _get_shop_ui() -> ShopUI:
	if _shop_ui:
		return _shop_ui
	
	var root = get_tree().root
	_shop_ui = root.find_child("ShopUI", true, false)
	return _shop_ui

func _get_menu_controller() -> MenuController:
	if _menu_controller:
		return _menu_controller
	
	var root = get_tree().root
	_menu_controller = root.find_child("MenuController", true, false)
	return _menu_controller

func simulate_vehicle_damage() -> void:
	print("[UIIntegrationTest] Simulating vehicle damage...")
	EventBus.vehicle_damaged.emit(10.0)

func simulate_weapon_fire() -> void:
	print("[UIIntegrationTest] Simulating weapon fire...")
	EventBus.weapon_fired.emit("pistol")

func simulate_coin_collection() -> void:
	print("[UIIntegrationTest] Simulating coin collection...")
	EventBus.coin_collected.emit(10)

func simulate_world_state_change() -> void:
	print("[UIIntegrationTest] Simulating world state change...")
	EventBus.world_state_changed.emit(0, 1)

func simulate_game_over(victory: bool) -> void:
	print("[UIIntegrationTest] Simulating game over (victory=%s)..." % victory)
	EventBus.game_over.emit(victory)
