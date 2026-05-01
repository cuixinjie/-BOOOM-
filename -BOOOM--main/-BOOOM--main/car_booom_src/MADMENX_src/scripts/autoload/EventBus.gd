## EventBus — 全局事件总线
##
## 功能说明：
## - 提供模块间解耦通信机制
## - 所有跨模块信号定义在此
## - 禁止直接 get_node() 获取其他模块引用
##
## 对接注意事项：
## - 所有模块间通信必须通过此信号
## - 信号命名遵循 snake_case 规范
##
## 创建人：cjs
## 创建日期：2026-04-28

class_name EventBus
extends Node

# ===== 战斗信号 =====
signal enemy_killed(enemy: Node, killer: Node)
signal bullet_hit(target: Node, bullet: Node, damage: float)
signal player_damaged(player: Node, damage: float)
signal vehicle_damaged(damage: float)
signal vehicle_repaired(amount: float)

# ===== 游戏状态信号 =====
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(victory: bool)
signal segment_completed(segment_id: int)
signal rest_point_entered()
signal boss_spawned(boss: Node)
signal boss_phase_changed(phase: int)

# ===== 里世界信号 =====
signal world_state_changed(from_state: int, to_state: int)
signal role_swap_triggered(driver_id: int, shooter_id: int)
signal shield_state_inverted()
signal world_swap_warning()

# ===== 经济信号 =====
signal coin_collected(amount: int)
signal energy_collected(amount: int)
signal proficiency_gained(amount: float)
signal level_up(new_level: int)
signal shop_purchased(item_id: String, cost: int)

# ===== 追兵信号 =====
signal chase_distance_changed(distance: float)
signal vehicle_breakdown()
signal repair_started()
signal repair_progress_changed(progress: float)
signal repair_completed()
signal repair_failed()
signal chase_caught()

# ===== 玩家输入信号 =====
signal driver_input_changed(input_data: Dictionary)
signal shooter_input_changed(input_data: Dictionary)
signal weapon_fired(weapon_id: String)
signal weapon_reloaded(weapon_id: String)
signal ammo_type_changed(ammo_type: String)

# ===== 特殊路段信号 =====
signal special_segment_started(segment_type: String)
signal special_segment_completed(segment_type: String)
signal special_segment_failed(segment_type: String)
signal road_width_changed(new_width: float)
signal emp_activated()
signal emp_deactivated()
signal fog_activated()
signal fog_deactivated()

# ===== 物品掉落信号 =====
signal item_picked_up(item: Node, picker: Node)
signal drop_spawned(drop: Node, position: Vector2)
