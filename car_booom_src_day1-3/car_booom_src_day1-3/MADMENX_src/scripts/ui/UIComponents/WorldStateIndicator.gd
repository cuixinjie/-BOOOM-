## WorldStateIndicator — 里世界状态指示器
##
## 功能说明：
## - 显示里世界切换提示
## - 警告倒计时显示
##
## 创建人：cjs
## 创建日期：2026-04-28

extends Control

@onready var state_label: Label = $StateLabel if has_node("StateLabel") else null
@onready var timer_label: Label = $TimerLabel if has_node("TimerLabel") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

var _warning_active: bool = false
var _warning_timer: float = 0.0

func _ready() -> void:
	visible = false
	_connect_signals()

func _process(delta: float) -> void:
	if _warning_active:
		_warning_timer -= delta
		if _warning_timer <= 0:
			_hide_warning()

func _connect_signals() -> void:
	if EventBus and EventBus.has_signal("world_state_changed"):
		EventBus.world_state_changed.connect(_on_world_state_changed)
	if EventBus and EventBus.has_signal("world_swap_warning"):
		EventBus.world_swap_warning.connect(_on_swap_warning)

func _on_world_state_changed(from_state: int, to_state: int) -> void:
	_warning_active = false
	visible = true
	var state_name = "NORMAL" if to_state == 0 else "INVERTED"
	if state_label:
		state_label.text = "WORLD: %s" % state_name
	if animation_player and animation_player.has_animation("fade_in_out"):
		animation_player.play("fade_in_out")
	if get_tree():
		await get_tree().create_timer(3.0).timeout
		visible = false

func _on_swap_warning(seconds_remaining: float) -> void:
	_warning_active = true
	_warning_timer = seconds_remaining
	visible = true
	if timer_label:
		timer_label.text = "WORLD SWAP: %.1f" % seconds_remaining
		timer_label.visible = true
	if animation_player and animation_player.has_animation("pulse"):
		animation_player.play("pulse")

func _hide_warning() -> void:
	_warning_active = false
	if timer_label:
		timer_label.visible = false
	print("[WorldStateIndicator] Warning hidden")

func show_world_change(to_state: int) -> void:
	_on_world_state_changed(0, to_state)
