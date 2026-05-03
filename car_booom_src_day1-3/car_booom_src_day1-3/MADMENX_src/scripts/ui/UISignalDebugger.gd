## UISignalDebugger — EventBus信号调试器
##
## 功能说明：
## - 监控所有EventBus信号的收发
## - 用于开发调试
##
## 创建人：cjs
## 创建日期：2026-04-29

extends Control

@onready var log_container: VBoxContainer = $ScrollContainer/LogContainer if has_node("ScrollContainer/LogContainer") else null
@onready var toggle_button: Button = $ToggleButton if has_node("ToggleButton") else null
@onready var clear_button: Button = $ClearButton if has_node("ClearButton") else null
@onready var filter_input: LineEdit = $FilterEdit if has_node("FilterEdit") else null

var max_log_lines: int = 100
var is_enabled: bool = true
var signal_filter: String = ""
var _log_count: int = 0

func _ready() -> void:
	_connect_signals()
	visible = false
	if toggle_button:
		toggle_button.pressed.connect(_on_toggle)
	if clear_button:
		clear_button.pressed.connect(_on_clear)
	if filter_input:
		filter_input.text_changed.connect(_on_filter_changed)

func _connect_signals() -> void:
	if not EventBus:
		return
	for signal_name in [
		"enemy_killed", "bullet_hit", "player_damaged", "vehicle_damaged",
		"coin_collected", "energy_collected", "world_state_changed",
		"segment_completed", "level_completed", "game_over"
	]:
		if EventBus.has_signal(signal_name):
			EventBus.connect(signal_name, _on_signal_received.bind(signal_name))

func _on_toggle() -> void:
	visible = not visible

func _on_clear() -> void:
	if not log_container:
		return
	for child in log_container.get_children():
		child.queue_free()
	_log_count = 0

func _on_filter_changed(text: String) -> void:
	signal_filter = text.to_lower()

func _on_signal_received(sig_name, arg1=null, arg2=null, arg3=null, arg4=null) -> void:
	if not is_enabled:
		return
	var display_name = sig_name
	var args = []
	if arg1 != null:
		args = [arg1]
		if arg2 != null:
			args.append(arg2)
			if arg3 != null:
				args.append(arg3)
				if arg4 != null:
					args.append(arg4)
	if signal_filter != "" and display_name.to_lower() not in signal_filter:
		return
	if not log_container:
		return
	if _log_count >= max_log_lines:
		var oldest = log_container.get_child(0)
		if oldest:
			oldest.queue_free()
	_log_count += 1

	var label = Label.new()
	var msg = "[%s] %s" % [Time.get_time_string_from_system(), display_name]
	if args.size() > 0:
		msg += " -> %s" % str(args[0])
		if args.size() > 1:
			msg += ", %s" % str(args[1])
		if args.size() > 2:
			msg += ", %s" % str(args[2])
		if args.size() > 3:
			msg += ", %s" % str(args[3])
	label.text = msg
	log_container.add_child(label)
