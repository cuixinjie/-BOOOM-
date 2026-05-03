## SaveManager — 存档管理器
##
## 功能说明：
## - 管理游戏存档的保存和加载
## - 存储玩家进度、设置等信息
##
## 创建人：cjs
## 创建日期：2026-04-28

extends Node

const SAVE_FILE_PATH = "user://save_game.dat"

var _save_data: Dictionary = {}

# ===== 接口定义 =====
## save_game(data: Dictionary) -> bool
##   保存游戏数据
##
## load_game() -> Dictionary
##   加载游戏数据
##
## has_save() -> bool
##   检查是否存在存档
##
## delete_save() -> void
##   删除存档
## ===== 接口结束 =====

func _ready() -> void:
	print("[SaveManager] Initialized")

func save_game(data: Dictionary) -> bool:
	_save_data = data
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data)
		file.store_line(json_string)
		file.close()
		print("[SaveManager] Game saved")
		return true
	else:
		push_error("[SaveManager] Failed to save game")
		return false

func load_game() -> Dictionary:
	if not has_save():
		return {}

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_line()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			_save_data = json.get_data()
			print("[SaveManager] Game loaded")
			return _save_data
		else:
			push_error("[SaveManager] Failed to parse save file")
	return {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		_save_data = {}
		print("[SaveManager] Save deleted")
