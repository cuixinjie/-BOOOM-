## MenuController — 菜单控制器
##
## 功能说明：
## - 管理主菜单、暂停菜单、死亡画面、通关画面
## - 处理菜单导航
## - 处理游戏状态切换
##
## 对接注意事项：
## - EventBus.game_started → 关闭主菜单
## - EventBus.game_paused → 显示暂停菜单
## - EventBus.game_over → 显示死亡/通关画面
## - EventBus.rest_point_entered → 允许访问暂停菜单功能
## - GameManager（新街）调用 show_menu() / hide_menu()
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name MenuController
extends CanvasLayer

enum MenuState {
	HIDDEN,
	MAIN_MENU,
	PAUSE_MENU,
	GAME_OVER,
	VICTORY
}

var _current_state: MenuState = MenuState.HIDDEN
var _is_input_enabled: bool = true

@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_screen: Control = $GameOverScreen
@onready var victory_screen: Control = $VictoryScreen
@onready var hud_controller: Control = $HUDController

func _ready() -> void:
	_connect_signals()
	_hide_all_menus()
	_show_menu(MenuState.MAIN_MENU)
	print("[MenuController] Initialized")

func _connect_signals() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.rest_point_entered.connect(_on_rest_point_entered)

func _input(event: InputEvent) -> void:
	if not _is_input_enabled:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause_menu()

func _on_rest_point_entered() -> void:
	_is_input_enabled = true

func _on_game_started() -> void:
	_hide_all_menus()
	_current_state = MenuState.HIDDEN
	
	if hud_controller and hud_controller.has_method("show_hud"):
		hud_controller.show_hud()

func _on_game_paused() -> void:
	if _current_state == MenuState.MAIN_MENU:
		return
	_show_menu(MenuState.PAUSE_MENU)

func _on_game_resumed() -> void:
	_hide_all_menus()
	_current_state = MenuState.HIDDEN

func _on_game_over(victory: bool) -> void:
	_is_input_enabled = false
	
	if victory:
		_show_menu(MenuState.VICTORY)
	else:
		_show_menu(MenuState.GAME_OVER)

func _toggle_pause_menu() -> void:
	match _current_state:
		MenuState.PAUSE_MENU:
			resume_game()
		MenuState.HIDDEN:
			if GameManager and GameManager.has_method("pause_game"):
				GameManager.pause_game()

func _hide_all_menus() -> void:
	if main_menu:
		main_menu.visible = false
	if pause_menu:
		pause_menu.visible = false
	if game_over_screen:
		game_over_screen.visible = false
	if victory_screen:
		victory_screen.visible = false

func _show_menu(state: MenuState) -> void:
	_hide_all_menus()
	_current_state = state
	
	match state:
		MenuState.MAIN_MENU:
			if main_menu:
				main_menu.visible = true
		MenuState.PAUSE_MENU:
			if pause_menu:
				pause_menu.visible = true
		MenuState.GAME_OVER:
			if game_over_screen:
				game_over_screen.visible = true
		MenuState.VICTORY:
			if victory_screen:
				victory_screen.visible = true
		MenuState.HIDDEN:
			pass

func start_game() -> void:
	if GameManager and GameManager.has_method("start_game"):
		GameManager.start_game()
	else:
		EventBus.game_started.emit()

func resume_game() -> void:
	_hide_all_menus()
	_current_state = MenuState.HIDDEN
	
	if GameManager and GameManager.has_method("resume_game"):
		GameManager.resume_game()
	else:
		EventBus.game_resumed.emit()

func restart_game() -> void:
	_hide_all_menus()
	_current_state = MenuState.HIDDEN
	
	get_tree().reload_current_scene()
	
	if GameManager and GameManager.has_method("start_game"):
		GameManager.start_game()

func quit_game() -> void:
	get_tree().quit()

func show_menu(state: MenuState) -> void:
	_show_menu(state)

func hide_menu() -> void:
	_hide_all_menus()
	_current_state = MenuState.HIDDEN

func get_current_state() -> MenuState:
	return _current_state
