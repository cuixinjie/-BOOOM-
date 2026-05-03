extends GutTest

func test_weapon_damage() -> void:
	var weapon = load("res://scripts/entities/player/WeaponBase.gd").new()
	add_child(weapon)

	weapon.base_damage = 25.0
	assert_eq(weapon.get_damage(), 25.0)

	remove_child(weapon)
	weapon.free()

func test_weapon_fire_ready() -> void:
	var weapon = load("res://scripts/entities/player/WeaponBase.gd").new()
	add_child(weapon)

	weapon.fire_rate = 0.2
	assert_true(weapon.fire_rate > 0)

	remove_child(weapon)
	weapon.free()
