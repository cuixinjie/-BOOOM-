## ProficiencyOrb — 熟练度球
##
## 功能说明：
## - 击杀敌人后掉落的熟练度奖励
## - 被拾取后增加武器熟练度
##
## 对接注意事项：
## - 通过 ObjectPool 管理，禁止直接 instance()
## - 拾取时需要知道当前武器类型，调用 WeaponProficiencySystem.add_proficiency_for_weapon
## - 默认由射击手拾取
##
## 创建人：cjs
## 创建日期：2026-05-06
## Day 4 任务：熟练度掉落系统

class_name ProficiencyOrb
extends Pickupable

var _weapon_type: String = "pistol"  # 默认武器类型
var _base_value: float = 5.0  # 基础熟练度值

func _ready() -> void:
	pickup_type = PickupType.ITEM
	value = int(_base_value)
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 0.8, 0.0, 1.0)  # 金黄色
	if has_node("CollisionShape2D"):
		var shape = $CollisionShape2D.shape
		if shape:
			shape.radius = 12.0

func set_weapon_type(weapon_type: String) -> void:
	_weapon_type = weapon_type

func set_value(new_value: float) -> void:
	_base_value = new_value
	value = int(new_value)

func on_pickup(picker: Node) -> void:
	# 查找射击手获取当前武器类型
	var shooter = _find_shooter(picker)
	if shooter and shooter.has_method("_get_current_weapon_type"):
		_weapon_type = shooter._get_current_weapon_type()
	elif shooter:
		# 使用 get() 安全获取属性（避免对 Node 调用 has()）
		var weapon_id = shooter.get("current_weapon_id")
		if weapon_id != null and weapon_id is String and not weapon_id.is_empty():
			if WeaponProficiencySystem:
				_weapon_type = WeaponProficiencySystem.get_weapon_type_from_id(weapon_id)
		else:
			# 使用默认武器类型
			_weapon_type = "pistol"
	else:
		# 没有找到射击手，使用默认武器类型
		_weapon_type = "pistol"
	
	# 添加熟练度
	if WeaponProficiencySystem:
		WeaponProficiencySystem.add_proficiency_for_weapon(_weapon_type, _base_value)
		print("[ProficiencyOrb] Collected ", _base_value, " proficiency for ", _weapon_type)
	
	# 播放音效
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("proficiency_pickup")
	EventBus.proficiency_gained.emit(_base_value)

## 查找射击手节点
func _find_shooter(picker: Node) -> Node:
	if picker is Node:
		# 检查是否是Shooter
		if picker is Shooter:
			return picker
		
		# 检查父节点
		if picker.get_parent() and picker.get_parent() is Shooter:
			return picker.get_parent()
		
		# 检查是否有shooter子节点
		for child in picker.get_children():
			if child is Shooter:
				return child
		
		# 查找场景中的Shooter
		var shooters = get_tree().get_nodes_in_group("shooter")
		if not shooters.is_empty():
			return shooters[0]
		
		# 尝试在root查找
		var root = get_tree().root
		if root:
			var all_nodes = root.get_children()
			for node in all_nodes:
				var shooter_node = _search_for_shooter(node)
				if shooter_node:
					return shooter_node
	
	return null

func _search_for_shooter(node: Node) -> Node:
	if node is Shooter:
		return node
	for child in node.get_children():
		var result = _search_for_shooter(child)
		if result:
			return result
	return null
