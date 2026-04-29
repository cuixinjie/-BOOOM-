## WorldStateIndicator — 里世界状态指示器
##
## 功能说明：
## - 显示当前世界状态
## - 表世界（废土）：紫色边框
## - 里世界（沃土）：绿色边框
## - 切换预警：边框闪烁 + 屏幕效果
##
## 对接注意事项：
## - EventBus.world_state_changed → 更新世界状态指示
## - EventBus.world_state_warning → 接收预警信号（提前2秒闪烁）
## - 显示在屏幕顶部居中位置
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name WorldStateIndicator
extends Control

enum WorldState {
	SURFACE_WORLD = 0,  ## 表世界 - 废土
	INNER_WORLD = 1,     ## 里世界 - 沃土
}

enum WarningPhase {
	NONE,
	WARNING,
	TRANSITION
}

## 表世界（废土）
@export var surface_world_color: Color = Color.PURPLE
## 里世界（沃土）
@export var inner_world_color: Color = Color.GREEN
## 预警闪烁颜色
@export var warning_color: Color = Color.ORANGE
## 预警闪烁间隔（秒）
@export var warning_blink_interval: float = 0.25
## 预警持续时间（秒）
@export var warning_duration: float = 2.0
## 预警时边框粗细
@export var warning_border_width: float = 4.0
## 正常边框粗细
@export var normal_border_width: float = 2.0

@onready var state_border: ColorRect = $StateBorder
@onready var state_label: Label = $StateLabel
@onready var state_icon: TextureRect = $StateIcon
@onready var warning_vignette: ColorRect = $WarningVignette
@onready var pulse_effect: ColorRect = $PulseEffect

var _current_state: int = WorldState.SURFACE_WORLD
var _warning_phase: WarningPhase = WarningPhase.NONE
var _warning_timer: float = 0.0
var _remaining_warning_time: float = 0.0
var _blink_on: bool = true
var _original_border_color: Color

const SURFACE_WORLD_NAME: String = "表世界"
const INNER_WORLD_NAME: String = "里世界"
const SURFACE_WORLD_DESC: String = "废土"
const INNER_WORLD_DESC: String = "沃土"

func _ready() -> void:
	_original_border_color = surface_world_color
	_update_display()
	_hide_warning_effects()
	print("[WorldStateIndicator] Initialized")

func _process(delta: float) -> void:
	if _warning_phase == WarningPhase.WARNING:
		_process_warning_phase(delta)
	elif _warning_phase == WarningPhase.TRANSITION:
		_process_transition_phase(delta)

func _process_warning_phase(delta: float) -> void:
	_remaining_warning_time -= delta
	_warning_timer -= delta
	
	if _remaining_warning_time <= 0:
		_end_warning()
		return
	
	if _warning_timer <= 0:
		_warning_timer = warning_blink_interval
		_toggle_warning_visual()
	
	_update_warning_vignette()

func _process_transition_phase(delta: float) -> void:
	_remaining_warning_time -= delta
	
	if _remaining_warning_time <= 0:
		_end_transition()
		return
	
	var progress = 1.0 - (_remaining_warning_time / 0.5)
	_update_transition_effect(progress)

func _toggle_warning_visual() -> void:
	_blink_on = not _blink_on
	
	if state_border:
		if _blink_on:
			state_border.color = warning_color
			state_border.custom_minimum_size.y = warning_border_width
		else:
			state_border.color = _get_state_color()
			state_border.custom_minimum_size.y = normal_border_width
	
	if state_label:
		if _blink_on:
			state_label.add_theme_color_override("font_color", warning_color)
		else:
			state_label.add_theme_color_override("font_color", Color.WHITE)

func _update_warning_vignette() -> void:
	if not warning_vignette:
		return
	
	var pulse = sin(_remaining_warning_time * 10.0) * 0.5 + 0.5
	warning_vignette.modulate.a = pulse * 0.3

func _update_transition_effect(progress: float) -> void:
	if warning_vignette:
		if progress < 0.5:
			warning_vignette.modulate.a = progress * 0.6
			warning_vignette.color = warning_color
		else:
			var invert_progress = 1.0 - progress
			warning_vignette.modulate.a = invert_progress * 0.6
			warning_vignette.color = _get_state_color()
	
	if pulse_effect:
		pulse_effect.modulate.a = sin(progress * PI) * 0.5

func _start_warning() -> void:
	_warning_phase = WarningPhase.WARNING
	_remaining_warning_time = warning_duration
	_warning_timer = warning_blink_interval
	_blink_on = true
	
	_show_warning_effects()

func _end_warning() -> void:
	_warning_phase = WarningPhase.NONE
	_blink_on = true
	
	if state_border:
		state_border.color = _get_state_color()
		state_border.custom_minimum_size.y = normal_border_width
	
	if state_label:
		state_label.add_theme_color_override("font_color", Color.WHITE)
	
	_hide_warning_effects()
	_start_transition()

func _start_transition() -> void:
	_warning_phase = WarningPhase.TRANSITION
	_remaining_warning_time = 0.5

func _end_transition() -> void:
	_warning_phase = WarningPhase.NONE
	_hide_warning_effects()
	_update_display()

func _show_warning_effects() -> void:
	if warning_vignette:
		warning_vignette.visible = true
		warning_vignette.color = warning_color
		warning_vignette.modulate.a = 0.0

func _hide_warning_effects() -> void:
	if warning_vignette:
		warning_vignette.visible = false
	
	if pulse_effect:
		pulse_effect.visible = false

func update_state(new_state: int) -> void:
	if new_state == _current_state:
		return
	
	var old_state = _current_state
	_current_state = new_state
	
	_start_warning()

func update_warning() -> void:
	if _warning_phase != WarningPhase.NONE:
		return
	
	_start_warning()

func _update_display() -> void:
	var color = _get_state_color()
	var name_text = _get_state_name()
	var desc_text = _get_state_description()
	var icon_path = _get_icon_path()
	
	if state_border:
		state_border.color = color
	
	if state_label:
		state_label.text = "%s\n%s" % [name_text, desc_text]
	
	if state_icon and icon_path != "":
		var icon = load(icon_path)
		if icon:
			state_icon.texture = icon

func _get_state_color() -> Color:
	match _current_state:
		WorldState.SURFACE_WORLD:
			return surface_world_color
		WorldState.INNER_WORLD:
			return inner_world_color
		_:
			return surface_world_color

func _get_state_name() -> String:
	match _current_state:
		WorldState.SURFACE_WORLD:
			return SURFACE_WORLD_NAME
		WorldState.INNER_WORLD:
			return INNER_WORLD_NAME
		_:
			return ""

func _get_state_description() -> String:
	match _current_state:
		WorldState.SURFACE_WORLD:
			return SURFACE_WORLD_DESC
		WorldState.INNER_WORLD:
			return INNER_WORLD_DESC
		_:
			return ""

func _get_icon_path() -> String:
	match _current_state:
		WorldState.SURFACE_WORLD:
			return "res://assets/art/ui/icon_surface_world.png"
		WorldState.INNER_WORLD:
			return "res://assets/art/ui/icon_inner_world.png"
		_:
			return ""

func get_current_state() -> int:
	return _current_state

func is_warning_active() -> bool:
	return _warning_phase != WarningPhase.NONE

func get_warning_progress() -> float:
	if _warning_phase == WarningPhase.NONE:
		return 0.0
	return 1.0 - (_remaining_warning_time / warning_duration)
