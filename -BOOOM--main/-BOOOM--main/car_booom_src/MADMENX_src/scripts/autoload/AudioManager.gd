## AudioManager — 音频管理器
##
## 功能说明：
## - 管理所有音频播放
## - 支持BGM和SFX分类
## - 提供音量控制
##
## 对接注意事项：
## - 被所有需要播放音效的模块依赖
## - 音频文件路径约定在 assets/audio/ 目录下
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name AudioManager
extends Node

@onready var _sfx_bus: AudioStreamPlayer = $SFXPlayer
@onready var _bgm_bus: AudioStreamPlayer = $BGMPlayer
@onready var _bgm_fade_tween: Tween

var _sfx_volume: float = 0.0
var _bgm_volume: float = 0.0
var _master_volume: float = 1.0

var _current_bgm: String = ""

# ===== 接口定义 =====
## play_sfx(sfx_name: String, volume_db: float = 0.0) -> void
##   播放音效
##
## play_bgm(bgm_name: String, fade: bool = true) -> void
##   播放背景音乐，支持淡入淡出
##
## stop_bgm(fade: bool = true) -> void
##   停止背景音乐
##
## set_volume(category: String, value: float) -> void
##   设置音量，category 可选 "master", "sfx", "bgm"
##
## set_bgm_pitch(pitch: float) -> void
##   设置BGM音调（用于里世界切换）
## ===== 接口结束 =====

func _ready() -> void:
	_sfx_bus.bus = "SFX"
	_bgm_bus.bus = "BGM"

func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	var path = "res://assets/audio/sfx/" + sfx_name + ".ogg"
	var stream = load_sfx(path)
	if stream:
		_sfx_bus.stream = stream
		_sfx_bus.volume_db = volume_db
		_sfx_bus.play()
		print("[AudioManager] Playing SFX: ", sfx_name)

func play_bgm(bgm_name: String, fade: bool = true) -> void:
	if _current_bgm == bgm_name and _bgm_bus.playing:
		return
	
	var path = "res://assets/audio/bgm/" + bgm_name + ".ogg"
	var stream = load_sfx(path)
	if stream:
		if fade and _bgm_bus.playing:
			_fade_out_and_play(stream)
		else:
			_bgm_bus.stream = stream
			_bgm_bus.play()
		_current_bgm = bgm_name
		print("[AudioManager] Playing BGM: ", bgm_name)

func stop_bgm(fade: bool = true) -> void:
	if fade:
		_fade_out()
	else:
		_bgm_bus.stop()
	_current_bgm = ""

func set_volume(category: String, value: float) -> void:
	value = clamp(value, 0.0, 1.0)
	match category:
		"master":
			_master_volume = value
		"sfx":
			_sfx_volume = value
		"bgm":
			_bgm_volume = value
	
	_update_volumes()

func set_bgm_pitch(pitch: float) -> void:
	_bgm_bus.pitch_scale = pitch

func load_sfx(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("[AudioManager] SFX not found: " + path)
	return null

func _fade_out_and_play(new_stream: AudioStream) -> void:
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(_bgm_bus, "volume_db", -80.0, 0.5)
	await _bgm_fade_tween.finished
	_bgm_bus.stop()
	_bgm_bus.stream = new_stream
	_bgm_bus.volume_db = _bgm_volume * _master_volume * 100 - 80
	_bgm_bus.play()
	_fade_in()

func _fade_out() -> void:
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(_bgm_bus, "volume_db", -80.0, 0.5)
	await _bgm_fade_tween.finished
	_bgm_bus.stop()

func _fade_in() -> void:
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(_bgm_bus, "volume_db", _bgm_volume * _master_volume * 100 - 80, 0.5)

func _update_volumes() -> void:
	_sfx_bus.volume_db = _sfx_volume * _master_volume * 100 - 80
	_bgm_bus.volume_db = _bgm_volume * _master_volume * 100 - 80

# 便捷方法
func play_shoot_sound(weapon_type: String) -> void:
	play_sfx("shoot_" + weapon_type)

func play_hit_sound() -> void:
	play_sfx("hit")

func play_explosion_sound() -> void:
	play_sfx("explosion")

func play_coin_sound() -> void:
	play_sfx("coin")
