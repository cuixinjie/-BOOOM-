## ConfigManager — 配置管理器
##
## 功能说明：
## - 统一管理所有 JSON 配置文件的加载和访问
## - 提供类型安全的配置读取接口
##
## 对接注意事项：
## - 被所有需要读取配置的模块依赖
## - 配置键名遵循 snake_case 规范
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name ConfigManager
extends Node

var _weapon_stats: Dictionary = {}
var _enemy_stats: Dictionary = {}
var _level_config: Dictionary = {}
var _game_config: Dictionary = {}

var _configs_loaded: bool = false

# ===== 接口定义 =====
## get_weapon_stats(weapon_id: String) -> Dictionary
##   获取武器配置
##
## get_enemy_stats(enemy_id: String) -> Dictionary
##   获取敌人配置
##
## get_level_config(level_id: String) -> Dictionary
##   获取关卡配置
##
## get_game_config(category: String) -> Dictionary
##   获取游戏通用配置（vehicle, skills, 追兵等）
##
## reload_configs() -> void
##   重新加载所有配置
## ===== 接口结束 =====

func _ready() -> void:
	_load_all_configs()

func _load_all_configs() -> void:
	_weapon_stats = _load_json("res://assets/configs/weapon_stats.json")
	_enemy_stats = _load_json("res://assets/configs/enemy_stats.json")
	_level_config = _load_json("res://assets/configs/level_config.json")
	_game_config = _load_json("res://assets/configs/game_config.json")
	_configs_loaded = true
	print("[ConfigManager] All configs loaded")

func _load_json(path: String) -> Dictionary:
	if ResourceLoader.exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			if parse_result == OK:
				return json.get_data()
			else:
				push_error("[ConfigManager] JSON parse error in: " + path)
		else:
			push_error("[ConfigManager] Cannot open file: " + path)
	else:
		push_warning("[ConfigManager] Config file not found: " + path)
	return {}

func get_weapon_stats(weapon_id: String) -> Dictionary:
	return _weapon_stats.get(weapon_id, {})

func get_all_weapon_ids() -> Array:
	return _weapon_stats.keys()

func get_enemy_stats(enemy_id: String) -> Dictionary:
	return _enemy_stats.get(enemy_id, {})

func get_all_enemy_ids() -> Array:
	return _enemy_stats.keys()

func get_level_config(level_id: String) -> Dictionary:
	return _level_config.get(level_id, {})

func get_all_level_ids() -> Array:
	return _level_config.keys()

func get_game_config(category: String) -> Dictionary:
	return _game_config.get(category, {})

func get_skill_config(skill_id: String) -> Dictionary:
	var skills = _game_config.get("skills", {})
	return skills.get(skill_id, {})

func reload_configs() -> void:
	_configs_loaded = false
	_load_all_configs()
	print("[ConfigManager] Configs reloaded")
