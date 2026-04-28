extends GutTest

func test_economy_initialization() -> void:
	var economy = EconomySystem.new()
	
	assert_eq(economy.get_coins(), 0, "Initial coins should be 0")

func test_add_coins() -> void:
	var economy = EconomySystem.new()
	economy.add_coins(100)
	
	assert_eq(economy.get_coins(), 100, "Coins should be 100 after adding")

func test_spend_coins() -> void:
	var economy = EconomySystem.new()
	economy.add_coins(100)
	var result = economy.spend_coins(50)
	
	assert_eq(result, true, "Spend should succeed with enough coins")
	assert_eq(economy.get_coins(), 50, "Coins should be 50 after spending")

func test_cannot_afford() -> void:
	var economy = EconomySystem.new()
	economy.add_coins(30)
	
	assert_eq(economy.can_afford(50), false, "Should not be able to afford 50 with only 30 coins")

func test_shop_purchase() -> void:
	var economy = EconomySystem.new()
	var shop = ShopSystem.new()
	
	economy.add_coins(500)
	var result = economy.attempt_purchase("smg", 500)
	
	assert_eq(result, true, "Purchase should succeed")
	assert_eq(economy.get_coins(), 0, "Coins should be 0 after full purchase")
