## SaveManager — 存档管理器
##
## 功能说明：
## - 管理游戏存档的保存和加载
## - 支持玩家数据、设置和进度
##
## 对接注意事项：
## - 被 GameManager 和 UI 调用
## - 存档格式为 JSON
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name SaveManager
extends Node

const SAVE_PATH = "user://save_game.json"
const SETTINGS_PATH = "user://settings.json"

var _current_save: Dictionary = {}
var _settings: Dictionary = {
	"sfx_volume": 1.0,
	"bgm_volume": 1.0,
	"master_volume": 1.0,
	"fullscreen": false,
	"show_fps": false
}

# ===== 接口定义 =====
## save_game() -> bool
##   保存当前游戏状态
##
## load_game() -> bool
##   加载存档
##
## has_save() -> bool
##   检查是否存在存档
##
## delete_save() -> bool
##   删除存档
##
## save_settings() -> void
##   保存设置
##
## load_settings() -> void
##   加载设置
##
## get_setting(key: String, default = null)
##   获取设置值
##
## set_setting(key: String, value) -> void
##   设置值
## ===== 接口结束 =====

func _ready() -> void:
	load_settings()

func save_game() -> bool:
	_current_save = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"player": {
			"coins": GameManager.get_coins(),
			"score": GameManager.get_score(),
			"current_level": GameManager.current_level
		},
		"progress": {
			"highest_level": GameManager.current_level
		}
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(_current_save, "\t")
		file.store_string(json_string)
		file.close()
		print("[SaveManager] Game saved")
		return true
	else:
		push_error("[SaveManager] Cannot save game")
		return false

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		if parse_result == OK:
			_current_save = json.get_data()
			print("[SaveManager] Game loaded")
			return true
		else:
			push_error("[SaveManager] JSON parse error")
			return false
	return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> bool:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save deleted")
		return true
	return false

func save_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(_settings, "\t")
		file.store_string(json_string)
		file.close()
		print("[SaveManager] Settings saved")

func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			if parse_result == OK:
				_settings = json.get_data()
				_apply_settings()
				print("[SaveManager] Settings loaded")

func _apply_settings() -> void:
	AudioManager.set_volume("sfx", _settings.get("sfx_volume", 1.0))
	AudioManager.set_volume("bgm", _settings.get("bgm_volume", 1.0))
	AudioManager.set_volume("master", _settings.get("master_volume", 1.0))
	
	if _settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func get_setting(key: String, default = null):
	return _settings.get(key, default)

func set_setting(key: String, value) -> void:
	_settings[key] = value
	save_settings()

func get_current_save() -> Dictionary:
	return _current_save
