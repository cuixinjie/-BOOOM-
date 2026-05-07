## SpecialSegmentManager — 特殊路段管理器
##
## 功能说明：
## - 管理特殊路段效果（窄路、迷雾、EMP等）
## - 效果计时和状态切换
## - 追踪多个同时激活的特殊效果
##
## EMP完整实现（Day 4）：
## - 通过 EventBus 向所有敌人广播 EMP 状态
## - 敌人收到信号后停止移动和攻击
## - 机车电子设备（技能）暂时失效
## - 弹幕子弹减速50%
##
## 特殊效果叠加（Day 6完善）：
## - 支持多个特殊效果同时激活
## - 视觉效果正确叠加（迷雾+窄路等）
## - 效果结束后正确恢复
##
## 对接注意事项：
## - 特殊效果通过 EventBus 广播供 Camera/Environment 层处理
## - EMP/迷雾等视觉特效由 Effect 层实现
## - 多个效果同时存在时，窄路宽度取最小值
##
## 创建人：新街（主）、长安旧梦（扩展）
## 创建日期：2026-04-29
## 合并日期：2026-05-02
## Day 4完善：EMP电子设备禁用逻辑（由新街实现）
## Day 6完善：多效果叠加处理

extends Node

signal special_segment_started(segment_type: String, duration: float)
signal special_segment_ended(segment_type: String)

enum SpecialSegmentType {
	ROAD_NARROW,
	FOG,
	EMP,
	TRAFFIC_JAM
}

var _active_effects: Dictionary = {}
var _effect_durations: Dictionary = {
	"road_narrow": 15.0,
	"fog": 20.0,
	"emp": 10.0,
	"traffic_jam": 12.0
}

# EMP特效参数
const EMP_BULLET_SLOW_FACTOR: float = 0.5

# 雾效强度追踪（用于多雾效叠加）
var _fog_effects: Dictionary = {}  # {effect_id: coverage_ratio}

# 存储每个效果的详细数据
var _special_effects_data: Dictionary = {}

# 关卡配置
var _level_config: Dictionary = {}

# ===== 接口定义 =====
## trigger_special_segment(segment_type: String, duration: float = -1.0) -> void
##   触发特殊路段
##
## end_special_segment(segment_type: String) -> void
##   结束特殊路段
##
## is_segment_active(segment_type: String) -> bool
##   检查特殊路段是否激活
## ===== 接口结束 =====

func _ready() -> void:
	_connect_signals()
	# 初始化特殊效果追踪器
	_special_effects_data = {}
	print("[SpecialSegmentManager] Initialized with multi-effect support")

func _connect_signals() -> void:
	# 目前不需要连接特殊信号，事件通过 trigger_special_segment 触发
	pass

func _process(delta: float) -> void:
	var expired_types: Array = []
	for seg_type in _active_effects.keys():
		_active_effects[seg_type] -= delta
		if _active_effects[seg_type] <= 0:
			expired_types.append(seg_type)

	for seg_type in expired_types:
		end_special_segment(seg_type)

	# 更新多效果叠加状态
	_update_multi_effect_state()

func trigger_special_segment(segment_type: String, duration: float = -1.0) -> void:
	var actual_duration = duration if duration > 0 else _effect_durations.get(segment_type, 10.0)
	_active_effects[segment_type] = actual_duration
	
	# 存储效果详细数据
	_special_effects_data[segment_type] = {
		"duration": actual_duration,
		"remaining": actual_duration,
		"start_time": Time.get_ticks_msec() / 1000.0
	}

	special_segment_started.emit(segment_type, actual_duration)
	EventBus.special_segment_trigger_requested.emit(_get_type_enum(segment_type), actual_duration)

	match segment_type:
		"road_narrow":
			EventBus.road_width_changed.emit(0.5)
		"fog":
			# 使用配置的雾效强度（如果未指定则使用默认值 0.7）
			var fog_coverage = _level_config.get("special_events_config", {}).get("fog", {}).get("visibility_reduction", 0.7)
			_add_fog_effect(fog_coverage)
		"emp":
			EventBus.emp_activated.emit()
			_disable_electronics()
		"traffic_jam":
			# 交通堵塞效果 - 增加障碍物密度
			var multiplier = _level_config.get("special_events_config", {}).get("traffic_jam", {}).get("obstacle_multiplier", 2.0)
			EventBus.traffic_jam_obstacles_requested.emit(multiplier)
			print("[SpecialSegmentManager] Traffic jam triggered - obstacle multiplier: ", multiplier)

	_update_multi_effect_state()
	print("[SpecialSegmentManager] Special segment started: ", segment_type)

func end_special_segment(segment_type: String) -> void:
	if not _active_effects.has(segment_type):
		return

	_active_effects.erase(segment_type)
	special_segment_ended.emit(segment_type)
	EventBus.special_segment_completed.emit(segment_type)

	match segment_type:
		"road_narrow":
			EventBus.road_width_changed.emit(1.0)
		"fog":
			_remove_fog_effect()
		"emp":
			EventBus.emp_deactivated.emit()
			_enable_electronics()

	print("[SpecialSegmentManager] Special segment ended: ", segment_type)

func is_segment_active(segment_type: String) -> bool:
	return _active_effects.has(segment_type)

func _get_type_enum(seg_type: String) -> int:
	match seg_type:
		"road_narrow": return SpecialSegmentType.ROAD_NARROW
		"fog": return SpecialSegmentType.FOG
		"emp": return SpecialSegmentType.EMP
		"traffic_jam": return SpecialSegmentType.TRAFFIC_JAM
	return 0

func _disable_electronics() -> void:
	print("[SpecialSegmentManager] EMP activated — disabling electronics")
	# 广播EMP激活信号，所有敌人和机车系统自行处理
	EventBus.emp_activated.emit()
	# 通知屏幕特效层
	EventBus.screen_shake_requested.emit(0.1, 2.0)

func _enable_electronics() -> void:
	print("[SpecialSegmentManager] EMP deactivated — restoring electronics")
	# 广播EMP停用信号
	EventBus.emp_deactivated.emit()

# ===== 多效果叠加处理（Day 6新增）=====

## 更新多效果叠加状态
func _update_multi_effect_state() -> void:
	# 计算窄路效果：取所有激活的窄路效果的最小宽度
	var min_road_width = 1.0
	var has_road_narrow = false
	
	if _active_effects.has("road_narrow"):
		has_road_narrow = true
		var road_narrow_config = _level_config.get("special_events_config", {}).get("road_narrow", {})
		var modifier = road_narrow_config.get("road_width_modifier", 0.5)
		min_road_width = min(min_road_width, modifier)
	
	# 如果有窄路效果被激活，发送最终的道路宽度
	if has_road_narrow:
		EventBus.road_width_changed.emit(min_road_width)
	
	# 计算迷雾效果：取所有激活的迷雾效果的最大覆盖率
	var max_fog_coverage = 0.0
	var has_fog = false
	
	if _active_effects.has("fog"):
		has_fog = true
		var fog_config = _level_config.get("special_events_config", {}).get("fog", {})
		var visibility = fog_config.get("visibility_reduction", 0.7)
		max_fog_coverage = max(max_fog_coverage, visibility)
	
	# 如果有迷雾效果被激活，发送最终的迷雾覆盖率
	if has_fog:
		EventBus.fog_activated.emit(max_fog_coverage)
	
	if has_road_narrow or has_fog:
		print("[SpecialSegmentManager] Multi-effect state updated: road_width=", min_road_width, ", fog_coverage=", max_fog_coverage)

## 获取当前激活的所有效果类型
func get_active_effect_types() -> Array:
	return _active_effects.keys()

## 检查是否有指定类型的效果激活
func is_any_effect_active(effect_types: Array) -> bool:
	for effect_type in effect_types:
		if _active_effects.has(effect_type):
			return true
	return false

## 获取指定效果类型的剩余时间
func get_effect_remaining_time(segment_type: String) -> float:
	return _active_effects.get(segment_type, 0.0)

## 获取效果叠加后的综合宽度修正
func get_combined_road_width_modifier() -> float:
	if not _active_effects.has("road_narrow"):
		return 1.0
	var road_narrow_config = _level_config.get("special_events_config", {}).get("road_narrow", {})
	return road_narrow_config.get("road_width_modifier", 0.5)

## 获取效果叠加后的综合迷雾覆盖率
func get_combined_fog_coverage() -> float:
	if not _active_effects.has("fog"):
		return 0.0
	var fog_config = _level_config.get("special_events_config", {}).get("fog", {})
	return fog_config.get("visibility_reduction", 0.7)

# ===== 雾效强度追踪方法（用于多雾效叠加）=====

## 添加一个雾效效果
func _add_fog_effect(coverage_ratio: float) -> void:
	var effect_id = "fog_%d" % Time.get_ticks_msec()
	_fog_effects[effect_id] = coverage_ratio
	_update_fog_overlay()
	print("[SpecialSegmentManager] Added fog effect: ", effect_id, " coverage: ", coverage_ratio)

## 移除一个雾效效果
func _remove_fog_effect() -> void:
	# 移除最早添加的雾效
	var keys = _fog_effects.keys()
	if keys.size() > 0:
		var oldest_key = keys[0]
		_fog_effects.erase(oldest_key)
		print("[SpecialSegmentManager] Removed fog effect: ", oldest_key)
	_update_fog_overlay()

## 更新雾效叠加层
func _update_fog_overlay() -> void:
	if _fog_effects.is_empty():
		EventBus.fog_deactivated.emit()
	else:
		# 计算所有雾效的最大覆盖率
		var max_coverage: float = 0.0
		for coverage in _fog_effects.values():
			if coverage > max_coverage:
				max_coverage = coverage
		EventBus.fog_activated.emit(max_coverage)
		print("[SpecialSegmentManager] Fog overlay updated: max_coverage=", max_coverage, ", effect_count=", _fog_effects.size())

## 获取当前雾效数量
func get_fog_effect_count() -> int:
	return _fog_effects.size()

func set_level_config(config: Dictionary) -> void:
	_level_config = config

func get_active_count() -> int:
	return _active_effects.size()
