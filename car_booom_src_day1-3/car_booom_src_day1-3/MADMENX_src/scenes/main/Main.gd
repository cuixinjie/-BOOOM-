extends Node2D

func _ready() -> void:
	print("[Main] Scene ready")
	_connect_event_signals()

func _connect_event_signals() -> void:
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.boss_phase_timeout.connect(_on_boss_timeout)

func _on_level_completed(level_id: int) -> void:
	print("[Main] Level ", level_id, " completed")
	GameManager.end_game(true)

func _on_boss_timeout() -> void:
	print("[Main] Boss timeout reached")
	GameManager.end_game(false)
