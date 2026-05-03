## LivingEntity — 可存活实体（敌人专用）
class_name LivingEntity
extends Entity

var chase_range: float = 400.0
var attack_range: float = 200.0
var attack_cooldown: float = 1.0
var _attack_timer: float = 0.0

func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or is_invulnerable:
		return
	var final_damage = max(0, amount - armor * 0.1)
	current_health = max(0, current_health - final_damage)
	health_changed.emit(current_health, max_health)
	EventBus.bullet_hit.emit(self, source, final_damage)
	if current_health <= 0:
		die(source)

func is_living_entity() -> bool:
	return true
