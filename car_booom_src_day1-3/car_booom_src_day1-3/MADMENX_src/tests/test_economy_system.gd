extends GutTest

func test_economy_add_coins() -> void:
	EconomySystem.reset()
	EconomySystem.add_coins(100)
	assert_eq(EconomySystem.get_coins(), 100)

func test_economy_spend_coins() -> void:
	EconomySystem.reset()
	EconomySystem.add_coins(100)
	var success = EconomySystem.spend_coins(50)
	assert_true(success)
	assert_eq(EconomySystem.get_coins(), 50)

	var fail = EconomySystem.spend_coins(100)
	assert_false(fail)

func test_economy_energy() -> void:
	EconomySystem.reset()
	EconomySystem.add_energy(50.0)
	assert_eq(EconomySystem.get_energy(), 50.0)
