## MathUtils — 数学工具类
##
## 功能说明：
## - 提供常用数学计算工具
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name MathUtils

static func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * clampf(t, 0.0, 1.0)

static func inverse_lerp(a: float, b: float, value: float) -> float:
	if a == b:
		return 0.0
	return clampf((value - a) / (b - a), 0.0, 1.0)

static func smooth_step(a: float, b: float, t: float) -> float:
	t = clampf((t - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func move_toward(current: float, target: float, delta: float) -> float:
	if abs(target - current) <= delta:
		return target
	return current + sign(target - current) * delta

static func angle_distance(from: float, to: float) -> float:
	var diff = fmod(to - from, TAU)
	return fmod(2.0 * diff, TAU) - diff

static func random_range(min_val: float, max_val: float) -> float:
	return randf_range(min_val, max_val)

static func random_int(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)

static func random_choice(array: Array):
	return array[randi() % array.size()]

static func weighted_random_choice(choices: Dictionary) -> Variant:
	var total_weight = 0.0
	for weight in choices.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative = 0.0
	
	for key in choices.keys():
		cumulative += choices[key]
		if random_value <= cumulative:
			return key
	
	return choices.keys()[0]

static func clamp_vector2(vec: Vector2, min_val: float, max_val: float) -> Vector2:
	return Vector2(clampf(vec.x, min_val, max_val), clampf(vec.y, min_val, max_val))

static func approach_vector2(current: Vector2, target: Vector2, delta: float) -> Vector2:
	return Vector2(move_toward(current.x, target.x, delta), move_toward(current.y, target.y, delta))

static func rotate_vector(vec: Vector2, angle: float) -> Vector2:
	return vec.rotated(angle)

static func look_at_direction(from: Vector2, to: Vector2) -> float:
	return (to - from).normalized().angle()
