## ColorUtils — 颜色工具类
##
## 功能说明：
## - 提供颜色处理工具
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name ColorUtils

static func interpolate(c1: Color, c2: Color, t: float) -> Color:
	return c1.lerp(c2, clampf(t, 0.0, 1.0))

static func from_hex(hex: String) -> Color:
	if hex.begins_with("#"):
		hex = hex.substr(1)
	var r = int(hex.substr(0, 2), 16) / 255.0
	var g = int(hex.substr(2, 2), 16) / 255.0
	var b = int(hex.substr(4, 2), 16) / 255.0
	return Color(r, g, b, 1.0)

static func to_hex(color: Color) -> String:
	return "#%02X%02X%02X" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]

static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))

static func darker(color: Color, amount: float = 0.2) -> Color:
	return color.darkened(amount)

static func lighter(color: Color, amount: float = 0.2) -> Color:
	return color.lightened(amount)

static func saturate(color: Color, amount: float) -> Color:
	var h = color.h
	var s = clampf(color.s + amount, 0.0, 1.0)
	var v = color.v
	return Color.from_hsv(h, s, v, color.a)

static func hue_shift(color: Color, degrees: float) -> Color:
	var h = fmod(color.h + degrees / 360.0, 1.0)
	if h < 0:
		h += 1.0
	return Color.from_hsv(h, color.s, color.v, color.a)

static func health_color(percent: float) -> Color:
	if percent >= 0.6:
		return Color.GREEN
	elif percent >= 0.3:
		return Color.YELLOW
	else:
		return Color.RED

static func world_state_color(is_inverted: bool) -> Color:
	if is_inverted:
		return Color.PURPLE
	return Color.CYAN
