## InputManager — 输入管理器
##
## 功能说明：
## - 统一管理玩家输入
## - 将物理输入映射为游戏操作
## - 支持驾驶员和射击手两套输入
##
## 对接注意事项：
## - 被 Player/Driver/Shooter 依赖
## - 输入数据通过 EventBus.driver_input_changed / shooter_input_changed 广播
##
## 创建人：cjs（主）、池言いく（接口规范）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

extends Node

class DriverInputData:
	var move_direction: Vector2 = Vector2.ZERO
	var is_sprinting: bool = false
	var skill_1_pressed: bool = false
	var skill_2_pressed: bool = false
	var skill_3_pressed: bool = false

class ShooterInputData:
	var aim_direction: Vector2 = Vector2.ZERO
	var is_firing: bool = false
	var is_reloading: bool = false
	var mouse_position: Vector2 = Vector2.ZERO

var _driver_input: DriverInputData = DriverInputData.new()
var _shooter_input: ShooterInputData = ShooterInputData.new()

# ===== 接口定义 =====
## get_driver_input() -> DriverInputData
##   返回驾驶员输入数据
##
## get_shooter_input() -> ShooterInputData
##   返回射击手输入数据
##
## get_mouse_position() -> Vector2
##   返回鼠标位置（屏幕坐标）
##
## is_action_pressed(action: String) -> bool
##   检查指定动作是否被按下
## ===== 接口结束 =====

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_update_driver_input()
	_update_shooter_input()
	_check_pause_input()

func _update_driver_input() -> void:
	var new_input = DriverInputData.new()

	# 移动方向
	var move_vec = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		move_vec.y -= 1
	if Input.is_action_pressed("move_down"):
		move_vec.y += 1
	if Input.is_action_pressed("move_left"):
		move_vec.x -= 1
	if Input.is_action_pressed("move_right"):
		move_vec.x += 1

	new_input.move_direction = move_vec.normalized()
	new_input.is_sprinting = Input.is_action_pressed("sprint")
	new_input.skill_1_pressed = Input.is_action_just_pressed("skill_1")
	new_input.skill_2_pressed = Input.is_action_just_pressed("skill_2")
	new_input.skill_3_pressed = Input.is_action_pressed("skill_3")

	if _input_changed(_driver_input, new_input):
		_driver_input = new_input
		EventBus.driver_input_changed.emit({
			"move_direction": _driver_input.move_direction,
			"is_sprinting": _driver_input.is_sprinting,
			"skill_1": _driver_input.skill_1_pressed,
			"skill_2": _driver_input.skill_2_pressed,
			"skill_3": _driver_input.skill_3_pressed
		})

func _update_shooter_input() -> void:
	var new_input = ShooterInputData.new()

	# 瞄准方向（键盘）
	var aim_vec = Vector2.ZERO
	if Input.is_action_pressed("shooter_up"):
		aim_vec.y -= 1
	if Input.is_action_pressed("shooter_down"):
		aim_vec.y += 1
	if Input.is_action_pressed("shooter_left"):
		aim_vec.x -= 1
	if Input.is_action_pressed("shooter_right"):
		aim_vec.x += 1

	new_input.aim_direction = aim_vec.normalized()
	new_input.is_firing = Input.is_action_pressed("fire")
	new_input.is_reloading = Input.is_action_just_pressed("reload")
	new_input.mouse_position = get_viewport().get_mouse_position()

	if _input_changed(_shooter_input, new_input):
		_shooter_input = new_input
		EventBus.shooter_input_changed.emit({
			"aim_direction": _shooter_input.aim_direction,
			"is_firing": _shooter_input.is_firing,
			"is_reloading": _shooter_input.is_reloading,
			"mouse_position": _shooter_input.mouse_position
		})

func _check_pause_input() -> void:
	if Input.is_action_just_pressed("pause"):
		if GameManager.is_playing():
			GameManager.pause_game()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			GameManager.resume_game()

func _input_changed(old_input, new_input) -> bool:
	if old_input is DriverInputData:
		return (old_input.move_direction != new_input.move_direction or
			old_input.is_sprinting != new_input.is_sprinting or
			old_input.skill_1_pressed != new_input.skill_1_pressed or
			old_input.skill_2_pressed != new_input.skill_2_pressed or
			old_input.skill_3_pressed != new_input.skill_3_pressed)
	if old_input is ShooterInputData:
		return (old_input.aim_direction != new_input.aim_direction or
			old_input.is_firing != new_input.is_firing or
			old_input.is_reloading != new_input.is_reloading or
			old_input.mouse_position != new_input.mouse_position)
	return false

func get_driver_input() -> DriverInputData:
	return _driver_input

func get_shooter_input() -> ShooterInputData:
	return _shooter_input

func get_mouse_position() -> Vector2:
	return get_viewport().get_mouse_position()

func is_action_pressed(action: String) -> bool:
	return Input.is_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)
