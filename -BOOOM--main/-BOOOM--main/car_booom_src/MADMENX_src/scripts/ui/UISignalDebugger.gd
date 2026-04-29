## UISignalDebugger — UI 信号调试工具
##
## 功能说明：
## - 实时监控所有 UI 相关信号的收发
## - 记录信号历史便于调试
## - 提供信号连接状态报告
##
## 使用方法：
## - 在项目启动时添加到 Autoload
## - 或在调试时手动实例化
##
## 创建人：cjs
## 创建日期：2026-04-29

class_name UISignalDebugger
extends Node

const MAX_HISTORY: int = 100

signal signal_received(signal_name: String, data: Array)
signal connection_report(report: Dictionary)

var _signal_history: Array[Dictionary] = []
var _connection_status: Dictionary = {}
var _is_monitoring: bool = false
var _monitored_signals: Array[String] = [
	"vehicle_damaged",
	"vehicle_repaired",
	"weapon_fired",
	"weapon_reloaded",
	"coin_collected",
	"energy_collected",
	"world_state_changed",
	"chase_distance_changed",
	"game_started",
	"game_paused",
	"game_resumed",
	"game_over",
	"segment_completed",
	"rest_point_entered",
	"boss_spawned",
	"repair_progress_changed",
	"repair_completed",
	"proficiency_gained",
	"level_up"
]

func _ready() -> void:
	print("[UISignalDebugger] Ready")
	_initialize_connection_tracking()

func _initialize_connection_tracking() -> void:
	for signal_name in _monitored_signals:
		_connection_status[signal_name] = {
			"connected": false,
			"receiver_count": 0,
			"last_received": 0.0,
			"received_count": 0
		}

func start_monitoring() -> void:
	if _is_monitoring:
		return
	
	_is_monitoring = true
	_connect_all_signals()
	print("[UISignalDebugger] Monitoring started")

func stop_monitoring() -> void:
	if not _is_monitoring:
		return
	
	_is_monitoring = false
	_disconnect_all_signals()
	print("[UISignalDebugger] Monitoring stopped")

func _connect_all_signals() -> void:
	for signal_name in _monitored_signals:
		_connect_signal(signal_name)

func _disconnect_all_signals() -> void:
	for signal_name in _monitored_signals:
		_disconnect_signal(signal_name)

func _connect_signal(signal_name: String) -> void:
	if not EventBus.has_signal(signal_name):
		return
	
	var method_name = "_on_signal_" + signal_name
	if has_method(method_name):
		EventBus.connect(signal_name, Callable(self, method_name))

func _disconnect_signal(signal_name: String) -> void:
	if not EventBus.has_signal(signal_name):
		return
	
	var method_name = "_on_signal_" + signal_name
	if has_method(method_name) and EventBus.is_connected(signal_name, Callable(self, method_name)):
		EventBus.disconnect(signal_name, Callable(self, method_name))

func _record_signal(signal_name: String, data: Array) -> void:
	var entry = {
		"time": Time.get_ticks_msec(),
		"signal": signal_name,
		"data": data
	}
	
	_signal_history.push_front(entry)
	if _signal_history.size() > MAX_HISTORY:
		_signal_history.pop_back()
	
	if _connection_status.has(signal_name):
		_connection_status[signal_name]["received_count"] += 1
		_connection_status[signal_name]["last_received"] = Time.get_ticks_msec()
	
	signal_received.emit(signal_name, data)

func _on_signal_vehicle_damaged(damage: float) -> void:
	_record_signal("vehicle_damaged", [damage])

func _on_signal_vehicle_repaired(amount: float) -> void:
	_record_signal("vehicle_repaired", [amount])

func _on_signal_weapon_fired(weapon_id: String) -> void:
	_record_signal("weapon_fired", [weapon_id])

func _on_signal_weapon_reloaded(weapon_id: String) -> void:
	_record_signal("weapon_reloaded", [weapon_id])

func _on_signal_coin_collected(amount: int) -> void:
	_record_signal("coin_collected", [amount])

func _on_signal_energy_collected(amount: int) -> void:
	_record_signal("energy_collected", [amount])

func _on_signal_world_state_changed(from_state: int, to_state: int) -> void:
	_record_signal("world_state_changed", [from_state, to_state])

func _on_signal_chase_distance_changed(distance: float) -> void:
	_record_signal("chase_distance_changed", [distance])

func _on_signal_game_started() -> void:
	_record_signal("game_started", [])

func _on_signal_game_paused() -> void:
	_record_signal("game_paused", [])

func _on_signal_game_resumed() -> void:
	_record_signal("game_resumed", [])

func _on_signal_game_over(victory: bool) -> void:
	_record_signal("game_over", [victory])

func _on_signal_segment_completed(segment_id: int) -> void:
	_record_signal("segment_completed", [segment_id])

func _on_signal_rest_point_entered() -> void:
	_record_signal("rest_point_entered", [])

func _on_signal_boss_spawned(boss: Node) -> void:
	_record_signal("boss_spawned", [boss.name if boss else "null"])

func _on_signal_repair_progress_changed(progress: float) -> void:
	_record_signal("repair_progress_changed", [progress])

func _on_signal_repair_completed() -> void:
	_record_signal("repair_completed", [])

func _on_signal_proficiency_gained(amount: float) -> void:
	_record_signal("proficiency_gained", [amount])

func _on_signal_level_up(new_level: int) -> void:
	_record_signal("level_up", [new_level])

func get_signal_history() -> Array[Dictionary]:
	return _signal_history.duplicate()

func get_signal_history_filtered(signal_name: String) -> Array[Dictionary]:
	return _signal_history.filter(func(entry): return entry["signal"] == signal_name)

func get_connection_report() -> Dictionary:
	var report = {
		"monitoring": _is_monitoring,
		"monitored_count": _monitored_signals.size(),
		"signals": _connection_status.duplicate(),
		"total_received": _signal_history.size()
	}
	connection_report.emit(report)
	return report

func print_report() -> void:
	var report = get_connection_report()
	print("\n=== UI Signal Debug Report ===")
	print("Monitoring: ", report["monitoring"])
	print("Monitored signals: ", report["monitored_count"])
	print("Total signals received: ", report["total_received"])
	print("\nSignal Status:")
	for signal_name in _monitored_signals:
		var status = _connection_status.get(signal_name, {})
		var received = status.get("received_count", 0)
		var last = status.get("last_received", 0)
		if received > 0:
			var elapsed = (Time.get_ticks_msec() - last) / 1000.0
			print("  [OK] %s: %d times (%.1fs ago)" % [signal_name, received, elapsed])
		else:
			print("  [--] %s: not received yet" % signal_name)
	print("============================\n")

func clear_history() -> void:
	_signal_history.clear()
	for signal_name in _connection_status:
		_connection_status[signal_name]["received_count"] = 0
		_connection_status[signal_name]["last_received"] = 0.0

func simulate_signal(signal_name: String, data: Array = []) -> void:
	match signal_name:
		"vehicle_damaged":
			EventBus.vehicle_damaged.emit(data[0] if data.size() > 0 else 10.0)
		"coin_collected":
			EventBus.coin_collected.emit(data[0] if data.size() > 0 else 10)
		"world_state_changed":
			EventBus.world_state_changed.emit(0, 1)
		"game_started":
			EventBus.game_started.emit()
		"game_over":
			EventBus.game_over.emit(data[0] if data.size() > 0 else false)
		"weapon_fired":
			EventBus.weapon_fired.emit(data[0] if data.size() > 0 else "pistol")
		_:
			print("[UISignalDebugger] Unknown signal: ", signal_name)
