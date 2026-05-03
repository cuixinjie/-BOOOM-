## MenuController — 菜单控制器
##
## 功能说明：
## - 管理主菜单和暂停菜单
## - 处理游戏胜利/失败画面
##
## Day 3修复：添加调试快捷键支持
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name MenuController
extends CanvasLayer

@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_screen: Control = $GameOverScreen

var _current_menu: Control = null
var _debug_mode: bool = false

func _ready() -> void:
	_show_menu(main_menu)
	_connect_signals()

func _connect_signals() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.game_over.connect(_on_game_over)

func _process(delta: float) -> void:
	_check_debug_input()

func _check_debug_input() -> void:
	if Input.is_key_pressed(KEY_F3):
		if not _debug_mode:
			_debug_mode = true
			_toggle_debug_mode()
	elif _debug_mode:
		_debug_mode = false
		_toggle_debug_mode()

func _toggle_debug_mode() -> void:
	var hud = get_node_or_null("/root/Main/HUDController")
	if hud and hud.has_method("toggle_debugger"):
		hud.toggle_debugger()
	print("[MenuController] Debug mode: ", _debug_mode)

func _show_menu(menu: Control) -> void:
	if _current_menu:
		_current_menu.visible = false
	_current_menu = menu
	if _current_menu:
		_current_menu.visible = true

func _on_game_started() -> void:
	_show_menu(null)

func _on_game_paused() -> void:
	_show_menu(pause_menu)

func _on_game_resumed() -> void:
	_show_menu(null)

func _on_game_over(victory: bool) -> void:
	_show_menu(game_over_screen)
	if game_over_screen:
		var result_label = game_over_screen.get_node_or_null("ResultLabel")
		if result_label:
			result_label.text = "VICTORY!" if victory else "GAME OVER"

func _on_start_pressed() -> void:
	GameManager.start_game()

func _on_resume_pressed() -> void:
	GameManager.resume_game()

func _on_restart_pressed() -> void:
	GameManager.restart_level()

func _on_quit_pressed() -> void:
	get_tree().quit()
