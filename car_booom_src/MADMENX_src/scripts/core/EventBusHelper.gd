## EventBus 事件处理工具
##
## 功能说明：
## - 提供便捷的事件监听和取消方法
## - 支持自动连接和断开
##
## 对接注意事项：
## - 作为 EventBus 的辅助工具使用
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name EventBusHelper
extends Node

static func connect_signal(signal_name: StringName, callback: Callable) -> void:
	if EventBus.has_signal(signal_name):
		if not EventBus.is_connected(signal_name, callback):
			EventBus.connect(signal_name, callback)

static func disconnect_signal(signal_name: StringName, callback: Callable) -> void:
	if EventBus.has_signal(signal_name):
		if EventBus.is_connected(signal_name, callback):
			EventBus.disconnect(signal_name, callback)

static func emit_signal_name(signal_name: StringName, args: Array = []) -> void:
	if EventBus.has_signal(signal_name):
		match args.size():
			0:
				EventBus.emit_signal(signal_name)
			1:
				EventBus.emit_signal(signal_name, args[0])
			2:
				EventBus.emit_signal(signal_name, args[0], args[1])
			3:
				EventBus.emit_signal(signal_name, args[0], args[1], args[2])
			_:
				EventBus.emit_signal(signal_name, args)
