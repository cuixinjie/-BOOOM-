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
## 创建人：cjs（主）、长安旧梦（扩展）
## 创建日期：2026-04-28
## 合并日期：2026-05-02

extends Node

# ===== 战斗信号 =====
signal enemy_killed(enemy: Node, killer: Node)
signal bullet_hit(target: Node, bullet: Node, damage: float)
signal player_damaged(player: Node, damage: float)
signal player_died(player: Node, killer: Node)
signal vehicle_damaged(damage: float)
signal vehicle_repaired(amount: float)
signal vehicle_speed_changed(speed: float)

# ===== 游戏状态信号 =====
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(victory: bool)
signal segment_completed(segment_id: int)
signal segment_changed(segment_id: int)
signal level_completed(level_id: int)
signal segment_started(segment_id: int)
signal rest_point_entered()
signal rest_point_exited()
signal boss_spawned(boss: Node)
signal boss_phase_changed(phase: int)

# ===== 里世界信号 =====
signal world_state_changed(from_state: int, to_state: int)
signal role_swap_triggered(driver_id: int, shooter_id: int)
signal shield_state_inverted()
signal world_swap_warning(seconds_remaining: float)
signal world_tint_changed(color: Color)
signal world_background_changed(theme: String)

# ===== 经济信号 =====
signal coin_collected(amount: int)
signal energy_collected(amount: int)
signal proficiency_gained(amount: float)
signal level_up(new_level: int)
signal shop_purchased(item_id: String, cost: int)
signal score_changed(score: int)

# ===== 追兵信号 =====
signal chase_distance_changed(distance: float)
signal vehicle_breakdown()
signal repair_started()
signal repair_progress_changed(progress: float)
signal repair_completed()
signal repair_failed()
signal chase_caught()

# ===== 游戏流程请求信号 =====
signal game_pause_requested()
signal game_resume_requested()
signal game_restart_requested()
signal level_start_requested(level_id: String)

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
signal special_segment_trigger_requested(segment_type: int, duration: float)
signal road_width_changed(new_width: float)
signal emp_activated()
signal emp_deactivated()
signal fog_activated(coverage_ratio: float)
signal fog_deactivated()

# ===== 关卡控制信号 =====
signal segment_content_ready(segment_id: int, obstacle_density: String)
signal segment_cleared()
signal spawn_config_ready(enemies: Array, spawn_rate: float)
signal spawn_stop_requested()
signal spawn_boss_requested(boss_type: String)
signal all_enemies_cleared()
signal rest_point_enter_requested()
signal rest_point_exit_requested()
signal chase_reward_requested(amount: float)
signal boss_phase_timeout()

# ===== 商店信号 =====
signal shop_purchase_requested(item_id: String)

# ===== 音效信号 =====
signal sfx_requested(sfx_name: String)

# ===== 屏幕效果信号 =====
signal screen_shake_requested(duration: float, intensity: float)

# ===== 障碍生成信号 =====
signal obstacles_generate_requested(segment_id: int, difficulty: String)
signal obstacles_clear_requested()

# ===== 物品掉落信号 =====
signal item_picked_up(item: Node, picker: Node)
signal drop_spawned(drop: Node, position: Vector2)
