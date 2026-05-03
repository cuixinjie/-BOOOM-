extends Node2D

signal game_started
signal back_to_menu

@onready var menu: Control = $MenuLayer/Menu
@onready var hud_layer: CanvasLayer = $HUD
@onready var pause_menu: Control = $PauseMenu

var _game_world: Node = null
var _player: Node = null
var _driver: Node = null
var _shooter: Node = null

func _ready() -> void:
	menu.visible = true
	hud_layer.visible = false
	pause_menu.visible = false
	$MenuLayer/Menu/VBox/StartButton.pressed.connect(start_game)
	$MenuLayer/Menu/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	$PauseMenu/Panel/VBox/ResumeButton.pressed.connect(resume_game)
	$HUD/DriverHUD/VBox/ShopButton.pressed.connect(_on_shop_button_pressed)
	print("[Main] Ready")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		elif GameManager.current_state == GameManager.GameState.PLAYING:
			pause_game()

func start_game() -> void:
	print("[Main] Starting game")
	menu.visible = false
	hud_layer.visible = true
	GameManager.start_game()
	_load_game_world()

func _load_game_world() -> void:
	if _game_world != null:
		return

	var level_path = "res://scenes/levels/Level01.tscn"
	if not ResourceLoader.exists(level_path):
		push_error("[Main] Level scene not found: " + level_path)
		return

	var level_scene = load(level_path)
	_game_world = level_scene.instantiate()
	_game_world.name = "GameWorld"
	_game_world.add_to_group("GameWorld")
	add_child(_game_world)

	# 创建机车
	var vehicle_path = "res://scenes/entities/vehicles/Motorcycle.tscn"
	if ResourceLoader.exists(vehicle_path):
		var vehicle_scene = load(vehicle_path)
		_player = vehicle_scene.instantiate()
		_player.name = "Player"
		_player.add_to_group("Player")
		_game_world.add_child(_player)

		var vehicle_spawn = _game_world.get_node_or_null("VehicleSpawn")
		if vehicle_spawn:
			_player.global_position = vehicle_spawn.global_position
		print("[Main] Vehicle spawned at ", _player.global_position)

	# 创建驾驶员 (Driver)
	var driver_path = "res://scenes/entities/player/Driver.tscn"
	if ResourceLoader.exists(driver_path):
		var driver_scene = load(driver_path)
		_driver = driver_scene.instantiate()
		_driver.name = "Driver"
		_driver.add_to_group("Driver")
		_game_world.add_child(_driver)
		if _player and _player.has_method("set_driver"):
			_player.set_driver(_driver)
		if _driver.has_method("set_vehicle"):
			_driver.set_vehicle(_player)
		print("[Main] Driver spawned and bound to vehicle")

	# 创建射击手 (Shooter)
	var shooter_path = "res://scenes/entities/player/Shooter.tscn"
	if ResourceLoader.exists(shooter_path):
		var shooter_scene = load(shooter_path)
		_shooter = shooter_scene.instantiate()
		_shooter.name = "Shooter"
		_shooter.add_to_group("Shooter")
		_game_world.add_child(_shooter)
		if _player and _player.has_method("set_shooter"):
			_player.set_shooter(_shooter)
		print("[Main] Shooter spawned and bound to vehicle")

	# 初始化子弹工厂
	_initialize_bullet_factory()

	# 初始化对象池
	_initialize_object_pools()

	# 启动里世界自动切换计时器
	_start_world_state()

	# 初始化敌人生成
	_initialize_enemy_spawning()

	print("[Main] Game world loaded")

func _initialize_bullet_factory() -> void:
	# BulletFactory 应该已经在 autoload 中注册
	if not _game_world.has_node("BulletFactory"):
		var bullet_factory = Node.new()
		bullet_factory.set_script(load("res://scripts/entities/bullet/BulletFactory.gd"))
		bullet_factory.name = "BulletFactory"
		_game_world.add_child(bullet_factory)
		print("[Main] BulletFactory initialized")

func _initialize_object_pools() -> void:
	# 预初始化对象池
	var pools_to_create = [
		{"name": "Bullet_player_basic", "path": "res://scenes/entities/bullets/BulletPlayer.tscn"},
		{"name": "BulletEnemy_enemy_basic", "path": "res://scenes/entities/bullets/BulletEnemy.tscn"},
		{"name": "Enemy_drone_basic", "path": "res://scenes/entities/enemies/DroneBasic.tscn"},
		{"name": "Enemy_drone_laser", "path": "res://scenes/entities/enemies/DroneLaser.tscn"},
		{"name": "Enemy_drone_healer", "path": "res://scenes/entities/enemies/DroneHealer.tscn"},
		{"name": "Enemy_enemy_bike", "path": "res://scenes/entities/enemies/EnemyBike.tscn"},
		{"name": "Coin", "path": "res://scenes/entities/pickups/Coin.tscn"},
		{"name": "EnergyOrb", "path": "res://scenes/entities/pickups/EnergyOrb.tscn"},
		{"name": "ObstacleBarrier", "path": "res://scenes/entities/obstacles/ObstacleBarrier.tscn"},
		{"name": "ObstaclePothole", "path": "res://scenes/entities/obstacles/ObstaclePothole.tscn"},
		{"name": "ObstacleLarge", "path": "res://scenes/entities/obstacles/ObstacleLarge.tscn"},
	]

	for pool_info in pools_to_create:
		if ObjectPool and ObjectPool.has_method("create_pool"):
			ObjectPool.create_pool(pool_info["name"], pool_info["path"], 5)
			print("[Main] Created pool: ", pool_info["name"])

func _start_world_state() -> void:
	if WorldStateManager and WorldStateManager.has_method("start_auto_swap_timer"):
		WorldStateManager.start_auto_swap_timer()
		print("[Main] WorldStateManager timer started")

func _initialize_enemy_spawning() -> void:
	# 让关卡管理器开始关卡
	var level_manager = _game_world.get_node_or_null("LevelManager")
	if level_manager and level_manager.has_method("start_level"):
		level_manager.start_level("Level01")
		print("[Main] Level started")

	# 启动追兵系统
	var chase_system = _game_world.get_node_or_null("ChaseSystem")
	if chase_system and chase_system.has_method("start_chase"):
		chase_system.start_chase()
		print("[Main] Chase system started")

func pause_game() -> void:
	get_tree().paused = true
	pause_menu.visible = true
	GameManager.pause_game()

func resume_game() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	GameManager.resume_game()

func return_to_menu() -> void:
	get_tree().paused = false
	menu.visible = true
	hud_layer.visible = false
	pause_menu.visible = false
	if _game_world:
		_game_world.queue_free()
		_game_world = null
		_player = null
		_driver = null
		_shooter = null

func _on_quit_pressed() -> void:
	print("[Main] Quit pressed")
	get_tree().quit()

func _on_shop_button_pressed() -> void:
	if hud_layer:
		hud_layer.toggle_shop()
	print("[Main] Shop toggled")
