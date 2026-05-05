## AmmoStackingValidator — 弹药 × 配件叠加验算（QA / 联调）
##
## 功能说明：
## - 读取 weapon_stats.json 中的 ammo_* / attachment_*，给出期望伤害倍数与备注
## - 不替代运行时逻辑；与 BulletFactory.apply_ammo_effect 口径对齐
##
## 创建人：长安旧梦
## 创建日期：2026-05-05

class_name AmmoStackingValidator
extends RefCounted


static func validate_combo(weapon_id: String, ammo_key: String, attachment_ids: Array = []) -> Dictionary:
	var ammo_stats: Dictionary = ConfigMgr.get_weapon_stats(_norm_ammo(ammo_key))
	var weapon_stats: Dictionary = ConfigMgr.get_weapon_stats(weapon_id)
	var notes: Array = []
	var damage_mult: float = float(ammo_stats.get("damage_multiplier", 1.0))
	var spread_mult: float = 1.0
	var reload_delta: float = 0.0
	var pierce_extra: int = int(ammo_stats.get("extra_pierce", 0))

	for aid in attachment_ids:
		var ast: Dictionary = ConfigMgr.get_weapon_stats(str(aid))
		if ast.is_empty():
			notes.append("unknown_attachment:" + str(aid))
			continue
		damage_mult *= float(ast.get("damage_multiplier", 1.0))
		spread_mult *= float(ast.get("spread_multiplier", 1.0))
		reload_delta += float(ast.get("reload_time_delta", 0.0))

	var valid := true
	var allowed: Array = ammo_stats.get("allowed_weapon_types", []) as Array
	var wcat: String = String(weapon_stats.get("type", ""))
	if allowed.size() > 0:
		valid = wcat in allowed
		if not valid:
			notes.append("ammo_not_allowed_for_weapon_type:" + wcat)

	return {
		"valid": valid,
		"weapon_id": weapon_id,
		"ammo_key": _norm_ammo(ammo_key),
		"expected_damage_multiplier": damage_mult,
		"expected_spread_multiplier": spread_mult,
		"reload_time_delta_sum": reload_delta,
		"extra_pierce_from_ammo": pierce_extra,
		"notes": notes,
	}


static func _norm_ammo(key: String) -> String:
	if key.is_empty():
		return "ammo_standard"
	if key.begins_with("ammo_"):
		return key
	return "ammo_" + key
