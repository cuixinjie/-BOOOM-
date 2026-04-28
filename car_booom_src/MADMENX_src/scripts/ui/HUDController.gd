## HUDController — HUD总控制器
##
## 功能说明：
## - 管理所有 HUD 显示
## - 协调 DriverHUD 和 ShooterHUD
##
## 对接注意事项：
## - 被 GameManager 调用
## - 管理子 HUD 组件
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name HUDController
extends CanvasLayer

@onready var driver_hud: Node = $DriverHUD
@onready var shooter_hud: Node = $ShooterHUD
@onready var world_state_indicator: Node = $WorldStateIndicator

var _is_visible: bool = true

func _ready() -> void:
	_connect_signals()
	print("[HUDController] Initialized")

func _connect_signals() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.world_state_changed.connect(_on_world_state_changed)

func _on_game_started() -> void:
	show_hud()

func _on_game_paused() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS

func _on_game_resumed() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS

func _on_game_over(victory: bool) -> void:
	hide_hud()

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	if world_state_indicator:
		world_state_indicator.update_state(to_state)

func show_hud() -> void:
	_is_visible = true
	visible = true

func hide_hud() -> void:
	_is_visible = false
	visible = false

func update_vehicle_health(health: float, max_health: float) -> void:
	if driver_hud:
		driver_hud.update_health(health, max_health)

func update_energy(energy: float, max_energy: float) -> void:
	if driver_hud:
		driver_hud.update_energy(energy, max_energy)

func update_stamina(stamina: float, max_stamina: float) -> void:
	if driver_hud:
		driver_hud.update_stamina(stamina, max_stamina)

func update_ammo(current: int, max_ammo: int) -> void:
	if shooter_hud:
		shooter_hud.update_ammo(current, max_ammo)

func update_coins(coins: int) -> void:
	if driver_hud:
		driver_hud.update_coins(coins)
