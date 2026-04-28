## MenuController — 菜单控制器
##
## 功能说明：
## - 管理主菜单、暂停菜单、游戏结束菜单
##
## 对接注意事项：
## - 被 InputManager 调用
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
var _menu_scenes: Dictionary = {}

@onready var main_menu: Node = $MainMenu
@onready var pause_menu: Node = $PauseMenu
@onready var game_over_screen: Node = $GameOverScreen
@onready var victory_screen: Node = $VictoryScreen

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

func _on_game_started() -> void:
	_hide_all_menus()
	_current_state = MenuState.HIDDEN

func _on_game_paused() -> void:
	_show_menu(MenuState.PAUSE_MENU)

func _on_game_resumed() -> void:
	_hide_all_menus()
	_current_state = MenuState.HIDDEN

func _on_game_over(victory: bool) -> void:
	if victory:
		_show_menu(MenuState.VICTORY)
	else:
		_show_menu(MenuState.GAME_OVER)

func _hide_all_menus() -> void:
	main_menu.visible = false
	pause_menu.visible = false
	game_over_screen.visible = false
	victory_screen.visible = false

func _show_menu(state: MenuState) -> void:
	_hide_all_menus()
	_current_state = state
	
	match state:
		MenuState.MAIN_MENU:
			main_menu.visible = true
		MenuState.PAUSE_MENU:
			pause_menu.visible = true
		MenuState.GAME_OVER:
			game_over_screen.visible = true
		MenuState.VICTORY:
			victory_screen.visible = true

func start_game() -> void:
	GameManager.start_game()

func resume_game() -> void:
	GameManager.resume_game()

func restart_game() -> void:
	_get_tree().reload_current_scene()
	GameManager.start_game()

func quit_game() -> void:
	get_tree().quit()
