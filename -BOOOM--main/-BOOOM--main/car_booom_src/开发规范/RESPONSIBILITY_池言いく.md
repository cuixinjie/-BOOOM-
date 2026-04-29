# 池言いく — 职责边界文档

> 本模块负责人：**池言いく**
>
> 负责模块：玩家系统 / 武器系统 / 机车物理 / 输入系统 / 配件系统 / 抛锚修车

---

## 1. 职责概述

你负责**游戏中最核心的两个角色**——驾驶员和射击手的一切：如何移动、如何射击、如何升级、如何在危机时刻修复机车。

**核心原则**：你是玩家的"代理人"。所有玩家能直接操控的东西（WASD、鼠标、技能、武器）都归你管。确保输入响应及时、物理手感流畅、武器手感扎实。

---

## 2. 负责模块清单

```
scripts/
├── autoload/
│   └── InputManager.gd       # 输入管理器（维护接口）
├── entities/
│   ├── player/
│   │   ├── PlayerBase.gd     # 玩家基类
│   │   ├── Driver.gd         # 驾驶员
│   │   ├── Shooter.gd        # 射击手
│   │   ├── WeaponBase.gd     # 武器基类
│   │   ├── WeaponPistol.gd   # 手枪
│   │   ├── WeaponSMG.gd       # 冲锋枪
│   │   ├── WeaponShotgun.gd  # 霰弹枪
│   │   └── WeaponSniper.gd   # 狙击枪
│   └── vehicle/
│       ├── VehicleController.gd  # 载具控制器
│       ├── Motorcycle.gd        # 摩托车
│       ├── VehicleSkills.gd     # 载具技能系统
│       └── VehicleUpgrade.gd     # 载具升级
├── systems/
│   ├── combat/
│   │   ├── CombatSystem.gd      # 战斗系统
│   │   ├── WeaponSystem.gd      # 武器系统
│   │   ├── AmmoSystem.gd        # 弹药系统
│   │   └── AttachmentSystem.gd  # 配件系统
│   └── chase/
│       ├── ChaseSystem.gd       # 追兵系统
│       └── BreakdownRecovery.gd  # 抛锚修复系统
```

### 依赖关系图（你的视角）

```
你的模块依赖：
  ├── InputManager（你的）— 获取玩家输入数据
  ├── EventBus — 接收所有信号
  ├── ConfigManager — 读取武器/敌人配置
  ├── DamageSystem（长安旧梦）— 伤害结算
  ├── BulletFactory（长安旧梦）— 创建玩家子弹
  ├── SpawnSystem（长安旧梦）— 抛锚时清空弹幕
  ├── WorldStateSystem（长安旧梦）— 里世界切换时互换数据
  ├── ObjectPool（core）— 对象复用
  └── AudioManager（单例）— 播放音效

被你的模块依赖：
  ├── ShooterHUD（🙃）— 显示射击手 HUD（弹药数、技能冷却）
  ├── DriverHUD（🙃）— 显示驾驶员 HUD（血量、能量、技能）
  ├── ShopSystem（新街）— 商店购买武器/配件
  ├── RestPointManager（新街）— 躲藏点装备展示
  ├── RoleSwapSystem（长安旧梦）— 里世界职责互换
  ├── WorldStateSystem（长安旧梦）— 职责互换时获取装备数据
  └── ProgressionSystem（🙃）— 熟练度加点
```

---

## 3. 详细职责说明

### 3.1 输入管理器

**InputManager.gd — 输入管理器**

```gdscript
## InputManager — 统一管理玩家输入
##
## 功能说明：
## - 映射键盘/鼠标输入到游戏操作
## - 为驾驶员和射击手分别提供输入数据
## - 处理输入的归一化和灵敏度设置
## - 支持游戏手柄（预留）
##
## 对接注意事项：
## - Driver.gd 和 Shooter.gd 通过 get_driver_input() / get_shooter_input() 获取数据
## - 不在 InputManager 中处理游戏逻辑，只负责输入采集
## - 所有输入数据通过返回值传递，不持有实体引用
##
## 创建人：池言いく
## 创建日期：2026-04-28

class_name DriverInputData:
    var move_direction: Vector2   # WASD 移动方向（归一化）
    var sprint: bool              # Shift 氮气冲刺
    var skill: bool               # Q 技能
    var repair_charge: float      # 修车充能进度（0.0 - 1.0）
    var is_vehicle_broken: bool   # 当前是否处于抛锚状态

class_name ShooterInputData:
    var aim_direction: Vector2    # 方向键瞄准方向（归一化）
    var fire: bool                # 鼠标左键射击
    var reload: bool              # 鼠标右键换弹

# ===== 接口定义 =====
# get_driver_input() -> DriverInputData
#   返回驾驶员当前输入状态
#
# get_shooter_input() -> ShooterInputData
#   返回射击手当前输入状态
#
# is_action_pressed(action: String, player_id: int) -> bool
#   检查指定动作是否被按下（用于菜单等场景）
#
# get_mouse_position() -> Vector2
#   返回鼠标在游戏世界的坐标（射击手瞄准用）
#
# is_gamepad_connected() -> bool
#   检查是否有手柄连接
#
# set_input_sensitivity(sensitivity: float) -> void
#   设置鼠标灵敏度
# ===== 接口结束 =====
```

### 3.2 驾驶员

**Driver.gd — 驾驶员**

```gdscript
## Driver — 驾驶员角色
##
## 功能说明：
## - 处理驾驶员输入（WASD 移动、Shift 冲刺、Q 技能）
## - 控制摩托车移动（伪3D追尾视角）
## - 管理机车血量、能量、耐力
## - 处理路面障碍碰撞响应
## - 处理抛锚与修车
##
## 对接注意事项：
## - VehicleController（你的）负责实际移动逻辑，Driver 是控制器
## - InputManager（你的）提供输入数据
## - DamageSystem（长安旧梦）计算障碍碰撞伤害
## - EventBus.vehicle_damaged 发射给 UI（🙃）和 ChaseSystem（新街）
## - EventBus.vehicle_breakdown 发射给 BreakdownRecovery（你的）
## - EventBus.vehicle_repaired 发射给 ChaseSystem（追兵奖励距离）
## - 里世界职责互换时，Driver 变为 Shooter，接收 RoleSwapSystem 的装备数据
## - 修车充能由 BreakdownRecovery（你的）处理，Driver 负责检测 Q 键长按
##
## 创建人：池言いく
## 创建日期：2026-04-28

# ===== 接口定义 =====
# get_vehicle_health() -> float
#   返回当前机车血量（两人共享）
#
# get_max_health() -> float
#   返回最大血量
#
# take_damage(amount: float) -> void
#   使机车受到伤害（通过 DamageSystem）
#
# get_energy() -> float
#   返回当前能量值
#
# consume_energy(amount: float) -> bool
#   消耗能量，成功返回 true，能量不足返回 false
#
# get_stamina() -> int
#   返回当前耐力点数
#
# use_stamina() -> bool
#   消耗1点耐力用于冲刺，成功返回 true
#
# is_stamina_empty() -> bool
#   返回耐力是否为空
#
# trigger_breakdown() -> void
#   触发抛锚（血量归零时自动调用）
#
# start_repair() -> void
#   开始修车（长按 Q）
#
# update_repair(delta: float) -> void
#   更新修车进度（在 BreakdownRecovery 中调用）
#
# cancel_repair() -> void
#   取消修车（松开 Q 或充能被打断）
#
# get_driver_data() -> Dictionary
#   返回驾驶员当前装备/技能数据（供 RoleSwapSystem 使用）
#
# apply_driver_data(data: Dictionary) -> void
#   应用驾驶员数据（供 RoleSwapSystem 使用，里世界职责互换）
# ===== 接口结束 =====
```

### 3.3 射击手

**Shooter.gd — 射击手**

```gdscript
## Shooter — 射击手角色
##
## 功能说明：
## - 处理射击手输入（方向键瞄准、鼠标射击/换弹）
## - 管理当前武器和弹药
## - 管理弹药类型和配件效果
## - 抛锚时展开护盾保护驾驶员修车
##
## 对接注意事项：
## - WeaponSystem（你的）管理武器切换和射击逻辑
## - BulletFactory（长安旧梦）创建子弹
## - AmmoSystem（你的）管理弹夹和换弹
## - EventBus.weapon_fired / weapon_reloaded 发射给 ShooterHUD（🙃）
## - 抛锚时 Shooter 展开护盾，由 BreakdownRecovery（你的）控制护盾逻辑
## - 里世界职责互换时，Shooter 变为 Driver，接收 RoleSwapSystem 的装备数据
##
## 创建人：池言いく
## 创建日期：2026-04-28

# ===== 接口定义 =====
# get_current_weapon() -> WeaponBase
#   返回当前装备的武器
#
# switch_weapon(weapon_id: String) -> bool
#   切换武器，成功返回 true（需要背包中有该武器）
#
# fire(direction: Vector2) -> void
#   向指定方向射击
#
# reload() -> void
#   手动换弹
#
# get_ammo_in_magazine() -> int
#   返回当前弹夹剩余弹药
#
# is_reloading() -> bool
#   返回当前是否处于换弹中
#
# get_aim_direction() -> Vector2
#   返回当前瞄准方向
#
# deploy_shield() -> void
#   展开护盾（抛锚时自动调用）
#
# get_shooter_data() -> Dictionary
#   返回射击手当前武器/弹药/配件数据（供 RoleSwapSystem 使用）
#
# apply_shooter_data(data: Dictionary) -> void
#   应用射击手数据（供 RoleSwapSystem 使用，里世界职责互换）
# ===== 接口结束 =====
```

### 3.4 载具控制器

**VehicleController.gd — 载具控制器**

```gdscript
## VehicleController — 载具控制器
##
## 功能说明：
## - 管理摩托车本体（不是角色，是物理载体）
## - 处理伪3D追尾视角的移动逻辑
## - 管理机车与路面的交互
## - 处理障碍碰撞响应
##
## 对接注意事项：
## - 依赖 InputManager 获取移动输入
## - 依赖 DamageSystem 计算碰撞伤害
## - EventBus.road_obstacle_hit 发射给 EnemyBike（新街的路障系统）
## - 里世界道路变窄时，通过 EventBus.road_width_changed 调整可移动范围
##
## 创建人：池言いく
## 创建日期：2026-04-28

# 移动参数（可配置）
const BASE_SPEED = 200.0
const SPRINT_MULTIPLIER = 1.5
const ROAD_WIDTH = 800.0  # 默认道路宽度
const LOW_HEALTH_SPEED_PENALTY = 0.5  # 低血量时速度惩罚系数
```

### 3.5 机车技能系统

**VehicleSkills.gd — 载具技能系统**

```gdscript
## VehicleSkills — 载具技能系统
##
## 功能说明：
## - 管理5个机车主动技能
## - 技能：耐力恢复 / 能量护盾 / 电子干扰 / 维修无人机 / 攻击无人机
## - 处理技能冷却和能量消耗
##
## 对接注意事项：
## - Driver（你的）调用 use_skill(skill_id) 触发技能
## - EMP 干扰期间，WeaponSystem（你的）监听 EventBus.emp_activated 生效
## - 能量护盾由 DamageSystem（长安旧梦）读取当前护盾状态
## - 维修/攻击无人机由 SpawnSystem（长安旧梦）生成
## - EventBus.skill_used 发射给 ShooterHUD（🙃）显示冷却
##
## 创建人：池言いく
## 创建日期：2026-04-28

# 技能表
enum VehicleSkill {
    STAMINA_RECOVERY = 0,  # 耐力恢复：消耗20能量，3秒内回复耐力
    ENERGY_SHIELD = 1,     # 能量护盾：消耗25能量，生成临时护盾
    ELECTRONIC_JAM = 2,    # 电子干扰：消耗20能量，周围敌人攻击失效
    REPAIR_DRONE = 3,      # 维修无人机：消耗25能量，召唤无人机自动回血
    ATTACK_DRONE = 4       # 攻击无人机：消耗35能量，召唤无人机自动攻击
}

# ===== 接口定义 =====
# use_skill(skill_id: VehicleSkill) -> bool
#   使用技能，能量足够返回 true
#
# is_skill_ready(skill_id: VehicleSkill) -> bool
#   检查技能是否就绪（能量足够 + 冷却完毕）
#
# get_skill_cooldown(skill_id: VehicleSkill) -> float
#   返回技能冷却时间（秒）
#
# get_skill_energy_cost(skill_id: VehicleSkill) -> float
#   返回技能能量消耗
#
# activate_energy_shield() -> void
#   激活能量护盾
#
# deactivate_energy_shield() -> void
#   停用能量护盾
#
# is_shield_active() -> bool
#   返回护盾是否激活
#
# on_emp_activated() -> void
#   EMP干扰生效回调（装弹速度-50%，技能无法使用）
#
# on_emp_deactivated() -> void
#   EMP干扰结束回调
# ===== 接口结束 =====
```

### 3.6 抛锚修复系统

**BreakdownRecovery.gd — 抛锚修复系统**

```gdscript
## BreakdownRecovery — 抛锚修复系统
##
## 功能说明：
## - 管理抛锚状态的完整流程
## - 控制驾驶员修车充能
## - 控制射击手护盾
## - 处理无人机干扰充能逻辑
## - 管理10秒倒计时
##
## 对接注意事项：
## - Driver（你的）触发 trigger_breakdown() 启动此系统
## - SpawnSystem（长安旧梦）清空所有弹幕：SpawnSystem.clear_all_enemies()
## - Shooter（你的）展开护盾：Shooter.deploy_shield()
## - ChaseSystem（新街）监听 repair_progress_changed / repair_failed
## - 无人机靠近降低充能进度：在 update_repair() 中处理
## - EventBus.repair_started / repair_progress_changed / repair_completed / repair_failed
##
## 创建人：池言いく
## 创建日期：2026-04-28

# ===== 接口定义 =====
# start_breakdown_recovery() -> void
#   开始抛锚修复流程
#
# update_repair_process(delta: float) -> void
#   每帧更新修车进度
#   逻辑：
#   1. 如果 Q 键按住 → 增加充能进度（理想5秒填满）
#   2. 如果有无人机接触 → 减少充能进度
#   3. 检查是否超时（10秒）
#
# cancel_repair() -> void
#   取消修车（无人机接触打断）
#
# get_repair_progress() -> float
#   返回修车进度（0.0 - 1.0）
#
# get_time_remaining() -> float
#   返回剩余时间（10秒倒计时）
#
# is_repair_in_progress() -> bool
#   返回是否正在修车
#
# complete_repair() -> void
#   修车完成，恢复30%血量
#
# fail_repair() -> void
#   修车超时失败，触发游戏失败
# ===== 接口结束 =====
```

### 3.7 武器系统

**WeaponBase.gd / WeaponSystem.gd — 武器基类与系统**

```gdscript
## WeaponBase — 武器基类
##
## 功能说明：
## - 所有武器的公共逻辑（射击、换弹、弹药管理）
## - 各武器子类实现独特行为（霰弹枪散射、狙击枪预判线等）
##
## 对接注意事项：
## - BulletFactory（长安旧梦）创建子弹
## - AmmoSystem（你的）管理弹夹和换弹逻辑
## - AttachmentSystem（你的）应用配件效果
## - EventBus.weapon_fired / weapon_reloaded / ammo_type_changed
##
## 创建人：池言いく
## 创建日期：2026-04-28

# 各武器特点
# 手枪（Pistol）：单发精准，6发弹夹，1.5秒换弹
# 冲锋枪（SMG）：连发，20发弹夹，1.5秒换弹，子弹散布大
# 霰弹枪（Shotgun）：扇形散射5发，6发弹夹，2.0秒换弹，每发独立判定
# 狙击枪（Sniper）：单发高伤，4发弹夹，1.8秒换弹，1秒射击间隔，瞄准红线
```

**AttachmentSystem.gd — 配件系统**

```gdscript
## AttachmentSystem — 配件系统
##
## 功能说明：
## - 管理已安装的配件
## - 计算配件对武器属性的加成
## - 配件与弹药类型叠加生效
##
## 对接注意事项：
## - ShopSystem（新街）购买配件
## - WeaponBase（你的）应用配件效果
## - 配件数据存储在 VehicleUpgrade（你的）中
##
## 创建人：池言いく
## 创建日期：2026-04-28

# 配件表
enum Attachment {
    STABILIZER_BASIC,
    STABILIZER_ADVANCED,
    STABILIZER_ULTIMATE,
    MUZZLE_BRAKE_BASIC,
    MUZZLE_BRAKE_ADVANCED,
    EXTENDED_MAG_BASIC,
    EXTENDED_MAG_ADVANCED,
    TRACKING_MODULE_BASIC,
    TRACKING_MODULE_ADVANCED
}
```

**AmmoSystem.gd — 弹药系统**

```gdscript
## AmmoSystem — 弹药系统
##
## 功能说明：
## - 管理弹夹和弹药
## - 处理换弹逻辑
## - 应用弹药类型效果
##
## 对接注意事项：
## - 弹药无限（只有弹夹容量限制）
## - 弹药类型在躲藏点切换（消耗10-20金）
## - 弹药类型效果通过 BulletFactory（长安旧梦）应用到子弹
##
## 创建人：池言いく
## 创建日期：2026-04-28

# 弹药类型
enum AmmoType {
    NORMAL,          # 普通弹
    ARMOR_PIERCING,  # 穿甲弹：穿透1/2个目标
    EXPLOSIVE,       # 爆炸弹：范围伤害
    POISON,          # 毒弹：持续伤害
    ELECTROMAGNETIC, # 电磁弹：目标瘫痪
    FRAGMENT,        # 子母弹：分裂
    SNIPER           # 狙击弹：伤害+显示弹道
}
```

### 3.8 追兵系统

**ChaseSystem.gd — 追兵系统**

```gdscript
## ChaseSystem — 追兵系统
##
## 功能说明：
## - 管理追兵与机车的距离
## - 追兵持续逼近，玩家需要不断前进保持安全距离
## - 提供距离指示（红箭头）
## - 处理追兵追上触发游戏失败
##
## 对接注意事项：
## - EventBus.chase_distance_changed 发射给 ShooterHUD（🙃）显示距离
## - EventBus.segment_completed（新街）触发时给予追兵距离奖励
## - EventBus.repair_completed（你的 BreakdownRecovery）给予追兵距离奖励
## - EventBus.repair_failed（你的 BreakdownRecovery）触发 chase_caught
## - 抛锚时启动 10 秒倒计时
##
## 创建人：池言いく
## 创建日期：2026-04-28

# ===== 接口定义 =====
# get_chase_distance() -> float
#   返回追兵与机车的距离（0.0 = 被追上，1.0 = 最远安全）
#
# get_distance_color() -> Color
#   返回距离指示颜色（根据距离计算，红 = 危险）
#
# add_distance_reward(amount: float) -> void
#   给予追兵距离奖励（路段完成/修车完成）
#
# start_pressure_mode() -> void
#   启动压力模式（抛锚时，追兵加速逼近）
#
# check_catch() -> bool
#   检查是否被追上
# ===== 接口结束 =====
```

---

## 4. 职责边界（必须遵守）

### 4.1 你可以修改的文件

```
scripts/autoload/InputManager.gd
scripts/entities/player/
scripts/entities/vehicle/
scripts/systems/combat/
scripts/systems/chase/
scripts/core/StateMachine.gd  # 通用工具
```

### 4.2 你**绝对不能**修改的文件

> **如有修改需求，必须与对应负责人协商，经 review 后再合入。**

```
scripts/entities/enemy/              # 长安旧梦 负责
scripts/entities/bullet/             # 长安旧梦 负责
scripts/core/DamageSystem.gd         # 长安旧梦 负责
scripts/systems/world/              # 长安旧梦 负责
scripts/systems/level/              # 新街 负责
scripts/systems/economy/            # 🙃 负责
scripts/ui/                          # 🙃 负责
scripts/autoload/EventBus.gd        # 需全体协商
scripts/autoload/GameManager.gd    # 新街 负责
scripts/core/ObjectPool.gd          # 通用工具，可提出 issue
```

### 4.3 与其他成员的接口约定

#### 与 长安旧梦 的接口

| 你发给长安旧梦 | 长安旧梦 发给你 |
|:-------------|:--------------|
| 武器属性数据（用于 BulletFactory 配置子弹） | 敌人位置数据（用于伤害判定） |
| 玩家子弹命中敌人 → `DamageSystem.apply_damage()` | 敌人无敌状态（用于判断是否可击杀） |
| — | 敌人类型（用于掉落判断） |

**关键接口**：
- `BulletFactory.create_player_bullet()` — 创建玩家子弹
- `DamageSystem.apply_damage()` — 所有伤害结算

#### 与 新街 的接口

| 你发给新街 | 新街 发给你 |
|:----------|:----------|
| `rest_point_entered` 信号触发时发送玩家装备数据 | 躲藏点 UI 需求（装备展示） |
| `segment_completed` → `ChaseSystem.add_distance_reward()` | 路段完成信号 |
| 商店购买武器/配件/弹药 | 商店逻辑（你的 ShopUI 调用新街的 ShopSystem） |

#### 与 🙃 的接口

| 你发给 🙃 | 🙃 发给你 |
|:---------|:---------|
| `vehicle_damaged` / `vehicle_repaired` | 驾驶员 HUD 更新需求 |
| `weapon_fired` / `weapon_reloaded` / `ammo_type_changed` | 射击手 HUD 更新需求 |
| `skill_used` | 技能冷却显示需求 |
| `repair_progress_changed` | 修车进度条 UI 需求 |
| `chase_distance_changed` | 追兵距离指示 UI 需求 |

---

## 5. Day-by-Day 开发计划

### Day 1

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 输入系统接入 | InputManager | `InputManager.gd` |
| 机车移动控制 | InputManager + VehicleController | `Motorcycle.gd` + `VehicleController.gd` |
| 射击系统 | BulletFactory（长安旧梦） | `Shooter.gd` + `WeaponPistol.gd` |
| HUD 预制体 | ShooterHUD + DriverHUD（🙃） | 血条/能量条/耐力条节点 |
| 路面障碍碰撞响应 | DamageSystem（长安旧梦） | `VehicleController.gd` 碰撞逻辑 |

### Day 2

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 5个机车技能 | `VehicleSkills.gd` | 技能实现 |
| 追兵距离系统框架 | EventBus | `ChaseSystem.gd` |
| 抛锚特殊机制 | SpawnSystem（长安旧梦） + Shooter | `BreakdownRecovery.gd` |
| 机车死亡与重试 | BreakdownRecovery | 重试逻辑 |
| 躲藏点框架 | RestPointManager（新街） | 职责切换入口 |

### Day 3

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 核心循环全流程联调 | 所有系统 | 集成测试 |
| 抛锚修车 10s 倒计时 | BreakdownRecovery | 完整实现 |
| 追兵追赶机制 | ChaseSystem | 完整实现 |
| 职责互换对接 | RoleSwapSystem（长安旧梦） | 装备数据同步 |

### Day 4

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 手枪完整实现 | BulletFactory | `WeaponPistol.gd` |
| 冲锋枪 | BulletFactory + ConfigManager | `WeaponSMG.gd` |
| 霰弹枪 | BulletFactory（散射逻辑） | `WeaponShotgun.gd` |
| 狙击枪 | BulletFactory（预判线） | `WeaponSniper.gd` |

### Day 5

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 熟练度积累 + 升级 | ProgressionSystem（🙃） | 熟练度逻辑 |
| 升级加点系统 | — | 加点逻辑 |
| 配件系统 | ShopSystem（新街） | `AttachmentSystem.gd` |
| 武器系统完整验证 | 所有系统 | 联调测试 |

### Day 6

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 武器系统最终验证 | — | Bug 修复 |
| 成长系统完整验证 | — | Bug 修复 |

### Day 7

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 机车受伤音效 | Freesound 资源 | `VehicleController.gd` 音效触发 |
| 氮气冲刺音效 | Freesound 资源 | 音效触发 |
| 技能释放音效 | Freesound 资源 | `VehicleSkills.gd` 音效触发 |

### Day 8

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 内存优化 | ObjectPool | 对象池检查 |
| 粒子特效接入 | 美术粒子资源 | 爆炸/命中粒子接入 |
| 数值调优验证 | 新街 | 联调 |

---

## 6. 常见对接问题与处理方式

| 问题场景 | 处理方式 |
|:---------|:---------|
| 子弹射出去但没有碰撞 | 检查 BulletPlayer 和 EnemyBase 的 collision_layer/mask 是否匹配 |
| 换弹时无法射击 | AmmoSystem 需要正确处理换弹状态，射击时检查 `is_reloading()` |
| 霰弹枪散射方向不对 | `WeaponShotgun.gd` 中计算散射角度，基准是 Shooter 的 `aim_direction` |
| 狙击枪预判线显示不正确 | 预判线由 ShooterHUD（🙃）绘制，Shooter 提供目标 1 秒后的预测位置 |
| 抛锚时护盾展开但没挡住攻击 | DamageSystem 需要检查 Shooter 的护盾状态，`DamageSystem.is_shield_active()` |
| 里世界职责互换后武器丢失 | RoleSwapSystem 在互换前保存 Shooter 的当前武器 ID，互换后重新加载 |
| 能量护盾被打破后无法再次展开 | 2 秒冷却由 BreakdownRecovery 控制，check cooldown before deploying |
| EMP 期间技能按钮仍然可用 | VehicleSkills 监听 `EventBus.emp_activated`，激活时 `use_skill()` 直接返回 false |

---

*本文档版本：1.0*
*最后更新：2026-04-28*
*维护者：池言いく*
