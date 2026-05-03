## HUDController — HUD总控制器
##
## 功能说明：
## - 管理所有HUD组件的显示和更新
## - 协调驾驶员和射击手HUD
##
## 创建人：cjs（主）、池言いく（V车HUD）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

extends CanvasLayer

@onready var driver_hud: Node = $DriverHUD if has_node("DriverHUD") else null
@onready var shooter_hud: Node = $ShooterHUD if has_node("ShooterHUD") else null
@onready var world_state_indicator: Node = $WorldStateIndicator if has_node("WorldStateIndicator") else null
@onready var signal_debugger: Node = $UISignalDebugger if has_node("UISignalDebugger") else null
@onready var shop_ui: Control = $ShopUI if has_node("ShopUI") else null

var _hud_active: bool = true

func _ready() -> void:
	_connect_signals()
	print("[HUDController] Initialized")

func _connect_signals() -> void:
	EventBus.game_started.connect(show_hud)
	EventBus.game_over.connect(_on_game_over)
	EventBus.vehicle_damaged.connect(_on_vehicle_damaged)
	EventBus.vehicle_repaired.connect(_on_vehicle_repaired)
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.energy_collected.connect(_on_energy_collected)
	EventBus.world_state_changed.connect(_on_world_state_changed)
	EventBus.vehicle_speed_changed.connect(_on_vehicle_speed_changed)
	EventBus.level_up.connect(_on_level_up)
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(_on_weapon_reloaded)
	EventBus.chase_distance_changed.connect(_on_chase_distance_changed)
	EventBus.repair_started.connect(_on_repair_started)
	EventBus.repair_completed.connect(_on_repair_completed)
	EventBus.rest_point_entered.connect(_on_rest_point_entered)
	EventBus.rest_point_exited.connect(_on_rest_point_exited)

func toggle_shop() -> void:
	if not shop_ui:
		return
	if shop_ui.visible:
		shop_ui.hide_shop()
	else:
		shop_ui.show_shop()

func _on_rest_point_entered() -> void:
	if shop_ui and shop_ui.has_method("show_shop"):
		shop_ui.show_shop()

func _on_rest_point_exited() -> void:
	if shop_ui and shop_ui.has_method("hide_shop"):
		shop_ui.hide_shop()

func show_hud() -> void:
	_hud_active = true
	visible = true
	if driver_hud:
		driver_hud.visible = true
	if shooter_hud:
		shooter_hud.visible = true
	print("[HUDController] HUD shown")

func hide_hud() -> void:
	_hud_active = false
	visible = false
	print("[HUDController] HUD hidden")

func _on_game_over(victory: bool) -> void:
	hide_hud()
	print("[HUDController] Game over - HUD hidden (victory: ", victory, ")")

func _on_vehicle_damaged(amount: float) -> void:
	var health = GameManager.get_vehicle_health()
	var max_health = GameManager.get_max_vehicle_health()
	if driver_hud and driver_hud.has_method("update_health_bar"):
		driver_hud.update_health_bar(health, max_health)

func _on_vehicle_repaired(amount: float) -> void:
	var health = GameManager.get_vehicle_health()
	var max_health = GameManager.get_max_vehicle_health()
	if driver_hud and driver_hud.has_method("update_health_bar"):
		driver_hud.update_health_bar(health, max_health)

func _on_coin_collected(amount: int) -> void:
	if driver_hud and driver_hud.has_method("update_coins"):
		driver_hud.update_coins(EconomySystem.get_coins())

func _on_energy_collected(amount: float) -> void:
	if driver_hud and driver_hud.has_method("update_energy"):
		driver_hud.update_energy(EconomySystem.get_energy())

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	if world_state_indicator and world_state_indicator.has_method("show_world_change"):
		world_state_indicator.show_world_change(to_state)

func _on_vehicle_speed_changed(speed: float) -> void:
	if driver_hud and driver_hud.has_method("update_speed"):
		driver_hud.update_speed(speed)

func _on_level_up(new_level: int) -> void:
	if driver_hud and driver_hud.has_method("update_level"):
		driver_hud.update_level(new_level)

func _on_weapon_fired(weapon_id: String) -> void:
	pass

func _on_weapon_reloaded(weapon_id: String) -> void:
	pass

func _on_chase_distance_changed(distance: float) -> void:
	pass

func _on_repair_started() -> void:
	pass

func _on_repair_completed() -> void:
	pass

func toggle_debugger() -> void:
	if signal_debugger:
		signal_debugger.visible = not signal_debugger.visible
		print("[HUDController] Debugger toggled: ", signal_debugger.visible)
