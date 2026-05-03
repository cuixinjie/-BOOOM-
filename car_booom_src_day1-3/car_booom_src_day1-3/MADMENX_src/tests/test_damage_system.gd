extends GutTest

func test_damage_calculation() -> void:
	var damage_system = load("res://scripts/core/DamageSystem.gd").new()
	add_child(damage_system)

	var base_damage = 10.0
	var result = damage_system.calculate_damage(base_damage)
	assert_eq(result, base_damage)

	remove_child(damage_system)
	damage_system.free()

func test_damage_modifiers() -> void:
	var damage_system = load("res://scripts/core/DamageSystem.gd").new()
	add_child(damage_system)

	var modifiers = [{"multiplier": 2.0}, {"flat": 5.0}]
	var result = damage_system.calculate_damage(10.0, modifiers)
	assert_eq(result, 25.0)

	remove_child(damage_system)
	damage_system.free()
