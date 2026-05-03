## EventBusHelper — 事件总线辅助工具
##
## 功能说明：
## - 提供 EventBus 的便捷封装
## - 支持条件监听和一次性监听
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name EventBusHelper
extends Node

# 一次性监听：信号触发一次后自动断开
func once_from(source: Object, signal_name: String, callback: Callable) -> void:
	if not source:
		return
	var method_name = callback.get_method()
	if source.has_signal(signal_name) and source.has_method(method_name):
		source.connect(signal_name, callback, Object.CONNECT_ONE_SHOT)

# 延迟监听：等待指定秒数后监听一次
func listen_after(delay: float, source: Object, signal_name: String, callback: Callable) -> void:
	await get_tree().create_timer(delay).timeout
	if source and source.has_signal(signal_name):
		source.connect(signal_name, callback, Object.CONNECT_ONE_SHOT)

# 批量连接信号
func connect_all(signal_pairs: Array) -> void:
	for pair in signal_pairs:
		if pair.size() >= 3:
			var source: Object = pair[0]
			var sig: String = pair[1]
			var slot: Callable = pair[2]
			var flags: int = CONNECT_PERSIST if pair.size() > 3 and pair[3] else 0
			if source and source.has_signal(sig):
				source.connect(sig, slot, flags)

# 批量断开信号
func disconnect_all(signal_pairs: Array) -> void:
	for pair in signal_pairs:
		if pair.size() >= 3:
			var source: Object = pair[0]
			var sig: String = pair[1]
			var slot: Callable = pair[2]
			if source and source.has_signal(sig) and source.is_connected(sig, slot):
				source.disconnect(sig, slot)
