extends GutTest

func test_damage_calculation() -> void:
	var damage_system = DamageSystem.new()
	
	var base_damage = 10.0
	var result = damage_system.calculate_damage(base_damage)
	
	assert_eq(result, base_damage, "Base damage should equal input")

func test_damage_with_modifier() -> void:
	var damage_system = DamageSystem.new()
	
	var base_damage = 10.0
	var modifiers = [{"multiplier": 2.0}]
	var result = damage_system.calculate_damage(base_damage, modifiers)
	
	assert_eq(result, 20.0, "Damage with 2x multiplier should be 20")

func test_critical_damage() -> void:
	var damage_system = DamageSystem.new()
	
	var damage_info = DamageSystem.DamageInfo.new(null, 10.0, "physical")
	damage_info.is_critical = true
	damage_info.critical_multiplier = 1.5
	
	var result = damage_system.calculate_damage(damage_info.base_damage)
	
	assert_almost_eq(result, 15.0, 0.1, "Critical damage should be 1.5x")

func test_coin_collection() -> void:
	GameManager.add_coins(100)
	
	assert_eq(GameManager.get_coins(), 100, "Coins should be 100 after adding")

func test_enemy_stats_loading() -> void:
	var stats = ConfigManager.get_enemy_stats("drone_basic")
	
	assert_ne(stats, {}, "Drone basic stats should not be empty")
	assert_eq(stats.get("tier"), 1, "Drone tier should be 1")
