## DroneLaser — 激光无人机
##
## 功能说明：
## - 发射激光攻击
## - 有预警和持续时间
##
## 对接注意事项：
## - 场景文件：scenes/entities/enemies/DroneLaser.tscn
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

class_name DroneLaser
extends EnemyBase

@export var laser_warn_time: float = 0.8
@export var laser_duration: float = 0.8
@export var laser_damage: float = 15.0

enum LaserState {
	IDLE,
	WINDUP,
	FIRING,
	COOLDOWN
}

var _laser_state: LaserState = LaserState.IDLE
var _laser_timer: float = 0.0
var _laser_target: Vector2 = Vector2.ZERO
var _laser_line: Node = null

func _ready() -> void:
	super._ready()
	enemy_type = "drone_laser"
	damage = laser_damage
	print("[DroneLaser] Initialized")

func _update_ai(delta: float) -> void:
	super._update_ai(delta)
	
	match _laser_state:
		LaserState.IDLE:
			_laser_timer -= delta
			if _laser_timer <= 0:
				_start_laser()
		LaserState.WINDUP:
			_laser_timer -= delta
			if _laser_timer <= 0:
				_fire_laser()
		LaserState.FIRING:
			_laser_timer -= delta
			if _laser_timer <= 0:
				_end_laser()
		LaserState.COOLDOWN:
			_laser_timer -= delta
			if _laser_timer <= 0:
				_laser_state = LaserState.IDLE
				_laser_timer = attack_interval

func _start_laser() -> void:
	_laser_state = LaserState.WINDUP
	_laser_timer = laser_warn_time
	if _target:
		_laser_target = _target.global_position
	print("[DroneLaser] Laser charging...")

func _fire_laser() -> void:
	_laser_state = LaserState.FIRING
	_laser_timer = laser_duration
	print("[DroneLaser] Laser firing!")

func _end_laser() -> void:
	_laser_state = LaserState.COOLDOWN
	_laser_timer = 0.5
	print("[DroneLaser] Laser cooldown")
