## SpecialSegmentManager — 特殊路段管理器
##
## 功能说明：
## - 管理特殊路段效果（窄路、迷雾、EMP等）
## - 效果计时和状态切换
##
## 对接注意事项：
## - 特殊效果通过 EventBus 广播供 Camera/Environment 层处理
## - EMP/迷雾等视觉特效由 Effect 层实现
##
## 创建人：新街（主）、长安旧梦（扩展）
## 创建日期：2026-04-29
## 合并日期：2026-05-02

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
	print("[SpecialSegmentManager] Initialized")

func _process(delta: float) -> void:
	var expired_types: Array = []
	for seg_type in _active_effects.keys():
		_active_effects[seg_type] -= delta
		if _active_effects[seg_type] <= 0:
			expired_types.append(seg_type)

	for seg_type in expired_types:
		end_special_segment(seg_type)

func trigger_special_segment(segment_type: String, duration: float = -1.0) -> void:
	var actual_duration = duration if duration > 0 else _effect_durations.get(segment_type, 10.0)
	_active_effects[segment_type] = actual_duration

	special_segment_started.emit(segment_type, actual_duration)
	EventBus.special_segment_trigger_requested.emit(_get_type_enum(segment_type), actual_duration)

	match segment_type:
		"road_narrow":
			EventBus.road_width_changed.emit(0.5)
		"fog":
			EventBus.fog_activated.emit(0.7)
		"emp":
			EventBus.emp_activated.emit()
			_disable_electronics()

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
			EventBus.fog_deactivated.emit()
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
	pass

func _enable_electronics() -> void:
	pass

func get_active_count() -> int:
	return _active_effects.size()
