extends GutTest

func test_weapon_stats_loading() -> void:
	var pistol_stats = ConfigManager.get_weapon_stats("pistol")
	
	assert_ne(pistol_stats, {}, "Pistol stats should not be empty")
	assert_eq(pistol_stats.get("damage"), 10, "Pistol damage should be 10")

func test_ammo_calculation() -> void:
	var weapon = WeaponBase.new()
	weapon.weapon_id = "pistol"
	weapon.magazine_size = 6
	
	var status = weapon.get_ammo_status()
	
	assert_eq(status["current"], 6, "Initial ammo should equal magazine size")

func test_reload_mechanics() -> void:
	var weapon = WeaponBase.new()
	weapon.weapon_id = "pistol"
	weapon.magazine_size = 6
	
	weapon.fire(Vector2.RIGHT)
	var status = weapon.get_ammo_status()
	
	assert_eq(status["current"], 5, "Ammo should decrease after firing")
