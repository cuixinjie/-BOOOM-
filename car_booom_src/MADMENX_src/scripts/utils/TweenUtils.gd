## TweenUtils — 动画工具类
##
## 功能说明：
## - 提供补间动画工具
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name TweenUtils

static func fade_in(node: CanvasItem, duration: float = 0.3) -> Tween:
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)
	return tween

static func fade_out(node: CanvasItem, duration: float = 0.3) -> Tween:
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	return tween

static func move_to(node: Node2D, target: Vector2, duration: float, transition: Tween.EaseType = Tween.EASE_OUT) -> Tween:
	var tween = node.create_tween()
	tween.tween_property(node, "position", target, duration).set_ease(transition)
	return tween

static func move_by(node: Node2D, offset: Vector2, duration: float, transition: Tween.EaseType = Tween.EASE_OUT) -> Tween:
	var tween = node.create_tween()
	var target = node.position + offset
	tween.tween_property(node, "position", target, duration).set_ease(transition)
	return tween

static func scale_to(node: Node, target_scale: Vector2, duration: float, transition: Tween.EaseType = Tween.EASE_OUT) -> Tween:
	var tween = node.create_tween()
	tween.tween_property(node, "scale", target_scale, duration).set_ease(transition)
	return tween

static func rotate_to(node: Node2D, target_angle: float, duration: float, transition: Tween.EaseType = Tween.EASE_OUT) -> Tween:
	var tween = node.create_tween()
	tween.tween_property(node, "rotation", target_angle, duration).set_ease(transition)
	return tween

static func pulse_scale(node: Node, scale_factor: float = 1.2, duration: float = 0.1) -> Tween:
	var tween = node.create_tween().set_loops()
	tween.tween_property(node, "scale", node.scale * scale_factor, duration)
	tween.tween_property(node, "scale", node.scale / scale_factor, duration)
	return tween

static func shake(node: Node2D, intensity: float = 5.0, duration: float = 0.3) -> Tween:
	var tween = node.create_tween()
	var original = node.position
	var elapsed = 0.0
	
	while elapsed < duration:
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original + offset, duration / 10.0)
		elapsed += duration / 10.0
	
	tween.tween_property(node, "position", original, duration / 10.0)
	return tween

static func color_to(node: CanvasItem, target_color: Color, duration: float) -> Tween:
	var tween = node.create_tween()
	tween.tween_property(node, "modulate", target_color, duration)
	return tween

static func animate_progress_bar(bar: ProgressBar, target_value: float, duration: float) -> Tween:
	var tween = bar.create_tween()
	tween.tween_property(bar, "value", target_value, duration)
	return tween

static func sequence(node: Node, actions: Array) -> void:
	for action in actions:
		if action is Callable:
			await action.call()
		elif action is float:
			await node.get_tree().create_timer(action).timeout
