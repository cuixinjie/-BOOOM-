## Driver — 驾驶员角色
##
## 功能说明：
## - 车辆驾驶员控制器
## - 负责车辆移动、闪避、加速
##
## 对接注意事项：
## - 继承自 Entity 基类
## - 输入通过 EventBus.driver_input_changed 接收
## - 车辆控制通过 Vehicle 类
##
## 创建人：长安旧梦
## 创建日期：2026-04-29

class_name Driver
extends Entity

var vehicle: Node = null

var dodge_cooldown: float = 2.0
var _dodge_timer: float = 0.0
var _is_dodging: bool = false
var dodge_speed: float = 600.0
var dodge_duration: float = 0.3

var nitro_amount: float = 100.0
var max_nitro: float = 100.0
var nitro_consumption_rate: float = 20.0

var is_boosting: bool = false

## 技能槽 1–3 对应 VehicleSkills 默认注册的 id（与 InputManager skill_1/2/3 一致）
const _SKILL_ID_BY_SLOT: Array[String] = ["", "nitro", "shield", "repair"]

func _ready() -> void:
	super._ready()
	player_role = PlayerRole.DRIVER
	player_id = 1
	max_health = 100.0
	current_health = max_health
	move_speed = 200.0
	is_active = true
	is_dead = false
	is_invulnerable = false
	visible = true
	_is_player_entity = true
	set_process(false)
	set_physics_process(true)
	# 连接驾驶员输入信号
	EventBus.driver_input_changed.connect(_on_driver_input_changed)

func set_vehicle(v: Node) -> void:
	vehicle = v

## 触发载具技能；成功释放返回 true（冷却中或未绑定载具返回 false）
func use_skill(slot: int) -> bool:
	if vehicle == null:
		return false
	if slot < 1 or slot >= _SKILL_ID_BY_SLOT.size():
		return false
	var skill_id: String = _SKILL_ID_BY_SLOT[slot]
	var vs := vehicle.get_node_or_null("VehicleSkills") as VehicleSkills
	if vs == null:
		return false
	if not vs.is_skill_ready(skill_id):
		return false
	vs.activate_skill(skill_id)
	return true

func _on_world_state_changed(_from_state: int, to_state: int) -> void:
	if to_state == 1:
		shield_active = not shield_active

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	_update_dodge_cooldown(delta)
	_update_boost(delta)
	if _input_data.get("skill_1", false):
		use_skill(1)
	if _input_data.get("skill_2", false):
		use_skill(2)
	if _input_data.get("skill_3", false):
		use_skill(3)
	if _is_dodging:
		return
	var move_dir = _input_data.get("move_direction", Vector2.ZERO)
	var speed = move_speed
	if is_boosting:
		speed *= 1.5
	if vehicle:
		vehicle.apply_driver_input(move_dir, speed, delta)
	if _input_data.get("is_sprinting", false) and nitro_amount > 0:
		start_boost()

func start_boost() -> void:
	if nitro_amount <= 0:
		return
	is_boosting = true

func _update_dodge_cooldown(delta: float) -> void:
	if _dodge_timer > 0:
		_dodge_timer -= delta

func _update_boost(delta: float) -> void:
	if is_boosting and nitro_amount > 0:
		nitro_amount -= nitro_consumption_rate * delta
		if nitro_amount <= 0:
			is_boosting = false
			nitro_amount = 0

func _on_driver_input_changed(data: Dictionary) -> void:
	_input_data = data

func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or is_invulnerable:
		return
	var final_damage = max(0, amount - armor * 0.1)
	current_health = max(0, current_health - final_damage)
	health_changed.emit(current_health, max_health)
	if _is_player_entity:
		EventBus.player_damaged.emit(self, final_damage)
	else:
		EventBus.bullet_hit.emit(self, source, final_damage)
	if current_health <= 0:
		die(source)

func get_nitro_ratio() -> float:
	return nitro_amount / max_nitro if max_nitro > 0 else 0.0

func is_player() -> bool:
	return true

func set_player_role(role: int) -> void:
	player_role = role as PlayerRole
	print("[Driver] Role set to: ", "DRIVER" if role == 0 else "SHOOTER")
