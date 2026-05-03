# DroneBasic -基础无人机
class_name DroneBasic
extends EnemyBase

func _ready() -> void:
	enemy_type = "drone_basic"
	max_health = 30.0
	current_health = max_health
	move_speed = 80.0
	chase_range = 350.0
	attack_range = 250.0
	attack_cooldown = 2.0
	attack_damage = 8.0
	score_value = 10
	entity_name = "DroneBasic"

	super._ready()

func perform_attack() -> void:
	if not is_instance_valid(target_node):
		return
	attack_triggered.emit()
	AudioManager.play_sfx("enemy_attack")
	var dir = (target_node.global_position - global_position).normalized()
	BulletFactory.create_enemy_bullet("enemy_basic", dir, attack_damage)
