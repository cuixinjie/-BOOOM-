## SpecialSegmentManager — 特殊路段管理器
##
## 功能说明：
## - 管理特殊路段效果
## - 处理 EMP、视野遮蔽等
##
## 对接注意事项：
## - 被 LevelManager 调用
## - 通过 EventBus 广播特殊路段事件
##
## 创建人：新街
## 创建日期：2026-04-28

class_name SpecialSegmentManager
extends Node

enum SegmentType {
	NORMAL,
	NARROW_ROAD,
	EMP_ZONE,
	FOG_ZONE
}

var _current_segment_type: SegmentType = SegmentType.NORMAL
var _is_active: bool = false

# ===== 接口定义 =====
## start_segment(type: SegmentType) -> void
##   开始特殊路段
##
## end_segment() -> void
##   结束特殊路段
##
## get_current_type() -> SegmentType
##   获取当前路段类型
## ===== 接口结束 =====

func _ready() -> void:
	print("[SpecialSegmentManager] Initialized")

func _process(delta: float) -> void:
	pass

func start_segment(type: SegmentType) -> void:
	_current_segment_type = type
	_is_active = true
	
	match type:
		SegmentType.NARROW_ROAD:
			_start_narrow_road()
		SegmentType.EMP_ZONE:
			_start_emp_zone()
		SegmentType.FOG_ZONE:
			_start_fog_zone()
	
	EventBus.special_segment_started.emit(SegmentType.keys()[type])
	print("[SpecialSegmentManager] Segment started: ", SegmentType.keys()[type])

func _start_narrow_road() -> void:
	EventBus.road_width_changed.emit(0.5)
	print("[SpecialSegmentManager] Road narrowed")

func _start_emp_zone() -> void:
	EventBus.emp_activated.emit()
	print("[SpecialSegmentManager] EMP zone active")

func _start_fog_zone() -> void:
	EventBus.fog_activated.emit()
	print("[SpecialSegmentManager] Fog zone active")

func end_segment() -> void:
	_is_active = false
	
	match _current_segment_type:
		SegmentType.NARROW_ROAD:
			EventBus.road_width_changed.emit(1.0)
		SegmentType.EMP_ZONE:
			EventBus.emp_deactivated.emit()
		SegmentType.FOG_ZONE:
			EventBus.fog_deactivated.emit()
	
	EventBus.special_segment_completed.emit(SegmentType.keys()[_current_segment_type])
	print("[SpecialSegmentManager] Segment ended: ", SegmentType.keys()[_current_segment_type])
	_current_segment_type = SegmentType.NORMAL

func get_current_type() -> SegmentType:
	return _current_segment_type

func is_active() -> bool:
	return _is_active
