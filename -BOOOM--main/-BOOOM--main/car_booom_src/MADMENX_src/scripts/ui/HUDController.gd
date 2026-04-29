## HUDController — HUD总控制器
##
## 功能说明：
## - 管理所有 HUD 显示
## - 协调 DriverHUD 和 ShooterHUD
## - 处理分屏布局（左 P1 驾驶员 / 右 P2 射击手）
## - 处理游戏状态变化时的 HUD 切换
##
## 对接注意事项：
## - 被 GameManager 调用
## - 管理子 HUD 组件
## - EventBus 信号驱动所有 HUD 更新
## - GameManager（新街）控制 HUD 的显示/隐藏
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name HUDController
extends CanvasLayer

@onready var driver_hud: DriverHUD = $DriverHUD
@onready var shooter_hud: ShooterHUD = $ShooterHUD
@onready var world_state_indicator: Control = $WorldStateIndicator
@onready var center_message: Label = $CenterMessage
@onready var split_divider: ColorRect = $SplitDivider

const SPLIT_SCREEN_OFFSET: float = 0.5

var _is_visible: bool = true
var _is_paused: bool = false

func _ready() -> void:
	_setup_split_screen()
	_connect_signals()
	_hide_all_huds()
	print("[HUDController] Initialized")

func _setup_split_screen() -> void:
	if driver_hud:
		driver_hud.anchor_right = SPLIT_SCREEN_OFFSET
		driver_hud.set_deferred("size_flags_stretch_ratio", 1.0)
	
	if shooter_hud:
		shooter_hud.anchor_left = SPLIT_SCREEN_OFFSET
		shooter_hud.set_deferred("anchor_right", 1.0)
	
	if split_divider:
		split_divider.position.x = get_viewport_rect().size.x * SPLIT_SCREEN_OFFSET - 2

func _connect_signals() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.world_state_changed.connect(_on_world_state_changed)
	EventBus.segment_completed.connect(_on_segment_completed)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.role_swap_triggered.connect(_on_role_swap_triggered)

func _hide_all_huds() -> void:
	if driver_hud:
		driver_hud.hide_hud()
	if shooter_hud:
		shooter_hud.hide_hud()
	if world_state_indicator:
		world_state_indicator.visible = false
	if center_message:
		center_message.visible = false

func _on_game_started() -> void:
	show_hud()
	_show_center_message("游戏开始！", 2.0)

func _on_game_paused() -> void:
	_is_paused = true
	pause_mode = Node.PAUSE_MODE_PROCESS

func _on_game_resumed() -> void:
	_is_paused = false
	pause_mode = Node.PAUSE_MODE_PROCESS

func _on_game_over(victory: bool) -> void:
	hide_hud()
	var message = "胜利！" if victory else "失败..."
	_show_center_message(message, 5.0)

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	_show_center_message(_get_world_state_message(to_state), 2.0)
	
	if world_state_indicator:
		world_state_indicator.visible = true
		if world_state_indicator.has_method("update_state"):
			world_state_indicator.update_state(to_state)

func _on_segment_completed(segment_id: int) -> void:
	_show_center_message("路段 %d 完成" % segment_id, 1.5)

func _on_boss_spawned(boss: Node) -> void:
	_show_center_message("BOSS 出现！", 3.0)

func _on_role_swap_triggered(driver_id: int, shooter_id: int) -> void:
	_show_center_message("职责互换！", 2.0)
	_perform_hud_swap()

func _perform_hud_swap() -> void:
	var temp_driver = driver_hud
	driver_hud = shooter_hud
	shooter_hud = temp_driver
	
	_setup_split_screen()

func _show_center_message(text: String, duration: float) -> void:
	if not center_message:
		return
	
	center_message.text = text
	center_message.visible = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(center_message, "modulate:a", 0.0, duration).set_delay(duration - 0.5)
	tween.tween_property(center_message, "scale", Vector2(1.2, 1.2), duration * 0.3)
	tween.chain().tween_property(center_message, "scale", Vector2.ONE, duration * 0.2)
	
	await get_tree().create_timer(duration).timeout
	center_message.visible = false
	center_message.modulate.a = 1.0
	center_message.scale = Vector2.ONE

func _get_world_state_message(state: int) -> String:
	match state:
		0:
			return "表世界 - 废土"
		1:
			return "里世界 - 沃土"
		_:
			return "世界切换"

func show_hud() -> void:
	_is_visible = true
	visible = true
	
	if driver_hud:
		driver_hud.show_hud()
	if shooter_hud:
		shooter_hud.show_hud()

func hide_hud() -> void:
	_is_visible = false
	visible = false
	
	if driver_hud:
		driver_hud.hide_hud()
	if shooter_hud:
		shooter_hud.hide_hud()

func update_driver_hud(data: Dictionary) -> void:
	if not driver_hud:
		return
	
	if data.has("health"):
		driver_hud.update_health(data["health"], data.get("max_health", 100.0))
	if data.has("energy"):
		driver_hud.update_energy(data["energy"], data.get("max_energy", 100.0))
	if data.has("stamina"):
		driver_hud.update_stamina(data["stamina"], data.get("max_stamina", 100.0))
	if data.has("coins"):
		driver_hud.update_coins(data["coins"])

func update_shooter_hud(data: Dictionary) -> void:
	if not shooter_hud:
		return
	
	if data.has("weapon"):
		shooter_hud.update_weapon(data["weapon"])
	if data.has("ammo"):
		shooter_hud.update_ammo(data["ammo"], data.get("max_ammo", 6))
	if data.has("ammo_type"):
		shooter_hud.update_ammo_type(data["ammo_type"])

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

func show_game_over_screen(victory: bool) -> void:
	hide_hud()
	var message = "胜利！" if victory else "失败..."
	_show_center_message(message, 10.0)

func show_pause_menu() -> void:
	_show_center_message("游戏暂停", -1)

func show_reload_progress(duration: float) -> void:
	if shooter_hud:
		shooter_hud.show_reload_progress(duration)
