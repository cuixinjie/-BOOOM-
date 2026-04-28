# 长安旧梦 — 职责边界文档

> 本模块负责人：**长安旧梦**
>
> 负责模块：敌人系统 / BOSS系统 / AI行为 / 弹幕生成 / 里世界切换逻辑

---

## 1. 职责概述

你负责**游戏中所有的威胁与挑战**——敌人如何行动、弹幕如何生成、BOSS 如何战斗、以及表/里世界切换时的规则变化。

**核心原则**：你是所有"会动、会攻击、会死亡"的东西的主人。确保敌人有清晰的行为模式、伤害判定精准、里世界切换逻辑无歧义。

---

## 2. 负责模块清单

```
scripts/
├── autoload/
│   └── WorldStateManager.gd   # 里世界状态管理（长安旧梦 + 新街共同维护接口）
├── core/
│   └── DamageSystem.gd        # 伤害计算系统
├── entities/
│   ├── enemy/
│   │   ├── EnemyBase.gd        # 敌人基类
│   │   ├── DroneBasic.gd       # 弹幕无人机
│   │   ├── DroneLaser.gd        # 激光无人机
│   │   ├── DroneHealer.gd     # 治疗无人机
│   │   ├── EnemyBike.gd        # 对冲摩托车
│   │   └── BossBase.gd        # BOSS基类
│   └── bullet/
│       ├── BulletBase.gd       # 子弹基类
│       ├── BulletPlayer.gd    # 玩家子弹
│       ├── BulletEnemy.gd     # 敌人弹幕
│       └── BulletFactory.gd   # 子弹工厂
├── systems/
│   ├── level/
│   │   └── SpawnSystem.gd     # 敌人生成系统
│   └── world/
│       ├── WorldStateSystem.gd  # 里世界切换系统
│       ├── WorldEffects.gd      # 世界切换特效（音效）
│       └── RoleSwapSystem.gd    # 职责互换系统
```

### 依赖关系图（你的视角）

```
你的模块依赖：
  ├── InputManager（敌人行为需要知道玩家位置）
  ├── EventBus（接收所有系统信号）
  ├── ConfigManager（读取 enemy_stats.json）
  └── DamageSystem（你维护，供其他系统使用）

被你的模块依赖：
  ├── LevelManager（新街）— 读取你的 SpawnSystem 获取敌人生成节奏
  ├── LevelManager（新街）— 里世界切换时需调用你的 WorldStateSystem
  ├── BulletFactory — 子弹生成需要你的工厂类
  ├── Shooter（池言いく）— 玩家子弹发射依赖 BulletFactory
  ├── CombatSystem — 伤害结算依赖 DamageSystem
  ├── WorldStateSystem — 里世界切换时需调用你的 RoleSwapSystem
  ├── VehicleController（池言いく）— 敌人伤害机车时发射 vehicle_damaged 信号
  └── UI（🙃）— 击杀显示需知道敌人类型
```

---

## 3. 详细职责说明

### 3.1 伤害计算系统

**DamageSystem.gd — 伤害计算系统**

```gdscript
## DamageSystem — 统一的伤害计算逻辑
##
## 功能说明：
## - 计算所有伤害（玩家射击敌人、敌人弹幕伤害机车、碰撞伤害等）
## - 处理伤害修正（护甲、弹药类型加成、武器配件加成）
## - 提供伤害结算接口给所有系统调用
##
## 对接注意事项：
## - 所有系统必须通过此系统结算伤害，禁止绕过
## - CombatSystem（池言いく）调用此系统进行武器伤害计算
## - BulletBase（你的）调用此系统进行弹幕伤害结算
## - EnemyBase（你的）调用此系统进行接触伤害结算
## - 里世界无敌反转也通过此系统处理（护盾状态标记）
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

# ===== 接口定义 =====
# calculate_damage(base_damage: float, modifier: Dictionary) -> float
#   输入：基础伤害 + 修正参数（弹药类型、配件加成、弱点加成等）
#   输出：最终伤害值
#
# apply_damage(target: Node, damage_info: Dictionary) -> void
#   输入：目标节点 + 伤害信息字典
#   伤害信息包含：source（伤害来源）、amount（数值）、type（类型）、flags（标记）
#   自动判断目标类型并调用对应处理逻辑
#
# calculate_elemental_damage(source: Node, target: Node, element: String) -> float
#   计算元素伤害（毒弹、爆炸弹等持续效果）
#
# is_invulnerable(target: Node) -> bool
#   查询目标当前是否无敌（里世界反转状态）
#
# set_invulnerable_state(target: Node, state: bool) -> void
#   设置目标无敌状态（由 WorldStateSystem 调用）
#
# is_target_in_shield_state(target: Node) -> bool
#   查询目标当前是否处于护盾保护状态
# ===== 接口结束 =====
```

### 3.2 敌人生成系统

**SpawnSystem.gd — 敌人生成系统**

```gdscript
## SpawnSystem — 敌人生成系统
##
## 功能说明：
## - 根据路段难度曲线动态调度敌人生成
## - 管理敌人生成点和生成节奏
## - 提供敌人生成接口给 LevelManager 调用
##
## 对接注意事项：
## - LevelManager（新街）通过 spawn_enemy(type, position) 触发生成
## - ObjectPool（core）用于对象复用
## - EnemyBase（你的）提供敌人类注册
## - 里世界切换时自动调整无敌状态（调用 WorldStateSystem）
## - 敌人生成位置由 LevelManager 提供，不在 SpawnSystem 硬编码
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

# ===== 接口定义 =====
# spawn_enemy(type: String, position: Vector2) -> Node
#   从对象池获取并初始化敌人，返回敌人节点引用
#
# spawn_enemy_wave(wave_config: Dictionary) -> Array
#   批量生成一波敌人，返回敌人节点数组
#
# despawn_enemy(enemy: Node) -> void
#   归还敌人到对象池
#
# set_difficulty_curve(progress: float) -> void
#   设置难度曲线进度（0.0 - 1.0），影响敌人生成密度
#
# get_active_enemy_count() -> int
#   返回当前存活敌人数量
#
# clear_all_enemies() -> void
#   清除所有存活敌人（用于抛锚清屏）
# ===== 接口结束 =====
```

**敌人生成节奏配置**（`enemy_stats.json` 中管理）：

```json
{
  "spawn_patterns": {
    "segment_1": {
      "base_interval": 8.0,
      "min_interval": 4.0,
      "enemy_pool": ["drone_basic"],
      "max_concurrent": 12
    },
    "segment_2": {
      "base_interval": 6.0,
      "min_interval": 3.0,
      "enemy_pool": ["drone_basic", "drone_healer", "drone_laser", "missile"],
      "max_concurrent": 18
    },
    "segment_3": {
      "base_interval": 4.0,
      "min_interval": 2.0,
      "enemy_pool": ["drone_basic", "drone_healer", "drone_laser", "missile", "enemy_bike"],
      "max_concurrent": 24
    }
  }
}
```

### 3.3 敌人基类与各类型实现

**EnemyBase.gd — 敌人基类**

```gdscript
## EnemyBase — 敌人基类
##
## 功能说明：
## - 所有敌人的公共逻辑（血量、移动、死亡）
## - 里世界无敌状态标记
## - 提供 AI 行为接口供子类实现
##
## 对接注意事项：
## - BulletPlayer（你的）命中时通过 DamageSystem 计算伤害
## - ShooterHUD（🙃）需要显示敌人血条
## - DropSystem（你的）生成死亡掉落
## - EventBus.enemy_killed 由 EnemyBase 发射，包含敌人类型便于掉落判断
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

# ===== 接口定义 =====
# take_damage(damage: float, source: Node) -> void
#   接受伤害，自动触发无敌状态检查
#
# die(killer: Node) -> void
#   死亡处理：发射 enemy_killed 信号、触发掉落、返回对象池
#
# set_invulnerable(state: bool) -> void
#   设置无敌状态（由 WorldStateSystem 调用）
#
# get_enemy_type() -> String
#   返回敌人类型标识，用于掉落系统和 UI
#
# is_in_world() -> bool
#   返回 true 表示当前在世界表层（废土），false 表示里世界（沃土）
# ===== 接口结束 =====
```

**各敌人类型详细行为**：

```gdscript
## DroneBasic — 弹幕无人机
## 行为：低空飞行（固定Y轴小范围浮动），每4秒发射一轮弹幕
## 威胁：数量多，射手主要清理对象

## DroneLaser — 激光无人机
## 行为：悬停，0.8s 预警后发射横向激光柱（持续0.8s），重复
## 威胁：驾驶员需观察激光区域躲避

## DroneHealer — 治疗无人机
## 行为：不攻击，在空中缓慢移动，治疗范围内友军（每秒3%最大HP）
## 威胁：优先击杀目标，阻止其治疗其他敌人

## EnemyBike — 对冲摩托车
## 行为：4秒内从远处高速接近机车，接近末段1.5秒红色警告区
##       接近过程中附带3发弹幕（3点/发）
## 威胁：高血量高伤害，射手全程可射击，需要驾驶员配合走位

## BossBase — BOSS 基类
## 行为：三阶段：
##   - 阶段1（100%-60%）：单一弹幕模式
##   - 阶段2（60%-30%）：弹幕加强 + 肘击地面
##   - 阶段3（30%-0%）：全弹幕 + 肘击 + 踩地板（地面塌陷）
```

### 3.4 子弹系统

**BulletFactory.gd — 子弹工厂**

```gdscript
## BulletFactory — 子弹工厂
##
## 功能说明：
## - 统一管理所有子弹的创建和配置
## - 支持多种弹药类型的子弹生成
## - 处理子弹生命周期管理
##
## 对接注意事项：
## - WeaponBase（池言いく）调用此工厂创建玩家子弹
## - EnemyBase（你的）调用此工厂创建敌人弹幕
## - ObjectPool（core）管理子弹对象复用
## - 弹药类型修改通过 ConfigManager 读取配置，不在此文件中硬编码
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

# ===== 接口定义 =====
# create_player_bullet(weapon_id: String, position: Vector2, direction: Vector2, ammo_type: String) -> Node
#   创建玩家子弹，应用武器属性和弹药类型效果
#
# create_enemy_bullet(type: String, position: Vector2, direction: Vector2) -> Node
#   创建敌人弹幕
#
# apply_ammo_effect(bullet: Node, ammo_type: String) -> void
#   为子弹应用弹药类型效果（穿甲/爆炸/毒弹等）
# ===== 接口结束 =====
```

### 3.5 里世界切换系统

**WorldStateSystem.gd — 里世界切换系统**

```gdscript
## WorldStateSystem — 里世界切换系统
##
## 功能说明：
## - 管理表世界（废土）和里世界（沃土）的切换
## - 处理无敌状态反转（核心机制）
## - 协调职责互换
## - 协调场景美术切换（发送信号给 LevelManager）
## - 协调音效切换（发送信号给 AudioManager）
##
## 对接注意事项：
## - LevelManager（新街）监听 world_state_changed 并执行场景切换
## - RoleSwapSystem（你的）处理双人职责互换
## - DamageSystem（你的）处理无敌状态标记
## - AudioManager（单例）监听 world_state_changed 切换环境音
## - WorldEffects（你的）处理转场视觉特效
## - 触发来源：全局定时器 + 精英击杀 + BOSS阶段转换
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

## WorldState — 世界状态枚举
enum WorldState { SURFACE = 0, INVERSE = 1 }

# ===== 接口定义 =====
# get_current_world() -> WorldState
#   返回当前世界状态
#
# trigger_world_swap() -> void
#   手动触发世界切换（由 EventBus 调用）
#
# invert_shield_states() -> void
#   反转所有敌人的护盾状态（里世界核心机制）
#   逻辑：
#   1. 遍历所有敌人
#   2. 如果敌人当前有护盾 → 移除护盾
#   3. 如果敌人当前无护盾 → 添加护盾
#   4. 标记敌人，确保连续两次切换中同一敌人不会处于同一状态
#
# swap_player_roles() -> void
#   互换驾驶员和射击手职责
#   1. 交换 Driver 和 Shooter 节点引用
#   2. 同步切换装备和弹药类型
#   3. 发送 role_swap_triggered 信号
#
# get_inverted_shield_state(enemy_type: String, original_state: bool) -> bool
#   根据规则计算反转后的护盾状态
# ===== 接口结束 =====
```

**无敌反转规则详解**：

```
切换前状态：
  - drone_basic: 无护盾 → 可被击落
  - drone_healer: 无护盾 → 可被击落
  - drone_laser: 无护盾 → 可被击落
  - enemy_bike: 无护盾 → 可被击落

切换后（反转）：
  - drone_basic: 有护盾 → 无敌，不可被击落
  - drone_healer: 有护盾 → 无敌，不可被击落
  - drone_laser: 有护盾 → 无敌，不可被击落
  - enemy_bike: 有护盾 → 无敌，不可被击落

再次切换（再次反转）：
  - 所有敌人恢复原始状态
```

### 3.6 职责互换系统

**RoleSwapSystem.gd — 职责互换系统**

```gdscript
## RoleSwapSystem — 职责互换系统
##
## 功能说明：
## - 处理驾驶员和射击手的职责互换
## - 同步切换装备、武器、弹药类型
## - 管理互换动画和过渡逻辑
##
## 对接注意事项：
## - WorldStateSystem（你的）触发里世界时调用 swap_roles()
## - Shooter（池言いく）提供武器数据用于互换
## - Driver（池言いく）提供技能数据用于互换
## - AmmoSystem（池言いく）提供弹药类型数据用于互换
## - 互换完成后发射 role_swap_triggered 信号
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

# ===== 接口定义 =====
# swap_roles() -> void
#   执行职责互换
#
# get_driver_data() -> Dictionary
#   获取驾驶员当前装备/技能数据
#
# get_shooter_data() -> Dictionary
#   获取射击手当前装备/武器/弹药数据
#
# apply_driver_equipment(data: Dictionary) -> void
#   将数据应用到新驾驶员（原本的射击手）
#
# apply_shooter_equipment(data: Dictionary) -> void
#   将数据应用到新射击手（原本的驾驶员）
# ===== 接口结束 =====
```

### 3.7 掉落系统

**DropSystem.gd — 掉落系统**

```gdscript
## DropSystem — 掉落系统
##
## 功能说明：
## - 管理敌人死亡后的掉落（硬币、能量球、熟练度）
## - 处理特殊掉落（武器、配件、弹药箱）
## - 管理掉落概率和数量配置
##
## 对接注意事项：
## - EnemyBase（你的）死亡时调用 DropSystem
## - ProgressionSystem（🙃）接收熟练度掉落
## - EconomySystem（🙃）接收金币掉落
## - VehicleController（池言いく）接收能量球
##
## 创建人：长安旧梦
## 创建日期：2026-04-28

# 掉落配置
const COIN_DROP_MIN = 5
const COIN_DROP_MAX = 8
const ENERGY_ORB_AMOUNT = 3
const ENERGY_ORB_ELITE_AMOUNT = 10
```

---

## 4. 职责边界（必须遵守）

### 4.1 你可以修改的文件

```
scripts/core/DamageSystem.gd
scripts/entities/enemy/
scripts/entities/bullet/
scripts/systems/world/
scripts/systems/level/SpawnSystem.gd
scripts/systems/economy/DropSystem.gd
assets/configs/enemy_stats.json
assets/configs/weapon_stats.json  # 敌人攻击相关部分
```

### 4.2 你**绝对不能**修改的文件

> **如有修改需求，必须与对应负责人协商，经 review 后再合入。**

```
scripts/entities/player/           # 池言いく 负责
scripts/entities/vehicle/         # 池言いく 负责
scripts/systems/combat/           # 池言いく 负责
scripts/systems/economy/          # 🙃 负责（DropSystem 除外）
scripts/ui/                        # 🙃 负责
scripts/autoload/GameManager.gd   # 新街 负责
scripts/autoload/InputManager.gd  # 池言いく 负责维护接口
scripts/autoload/EventBus.gd      # 需全体协商
scripts/core/ObjectPool.gd        # 通用工具，可提出 issue
scripts/core/StateMachine.gd       # 通用工具，可提出 issue
```

### 4.3 与其他成员的接口约定

#### 与 池言いく 的接口

| 你发给池言いく | 池言いく 发给你 |
|:-------------|:--------------|
| `enemy_killed`（敌人死亡，掉落数据） | 玩家武器数据（用于子弹工厂配置） |
| 敌人弹幕伤害信息 | 玩家武器属性（用于伤害计算） |
| — | 驾驶员血量（用于判断敌人攻击是否命中） |

**关键接口**：`DamageSystem.apply_damage()` — 所有伤害通过此接口结算

#### 与 新街 的接口

| 你发给新街 | 新街 发给你 |
|:----------|:----------|
| 敌人生成节奏（读取 level_config.json） | 路段类型和难度曲线 |
| `boss_spawned` 信号 | BOSS 场景节点引用（你需要将其加入战斗系统） |
| `world_state_changed` 信号 | 无（你自己处理） |
| 敌人生成点位置 | 从 `SpawnSystem.spawn_enemy()` 获取 |

#### 与 🙃 的接口

| 你发给 🙃 | 🙃 发给你 |
|:---------|:---------|
| `enemy_killed`（敌人类型） | UI 需求：击杀显示、敌人血条位置 |
| `world_state_changed`（世界切换） | 里世界状态 UI 指示器需求 |
| `boss_phase_changed`（BOSS阶段） | BOSS 血条 UI 需求 |

---

## 5. Day-by-Day 开发计划

### Day 1

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 子弹 ↔ 无人机碰撞检测 | ObjectPool（core） | `BulletBase.gd` + `EnemyBase.gd` |
| 伤害判定系统 | ConfigManager | `DamageSystem.gd` |
| 无人机血量与死亡逻辑 | — | `EnemyBase.gd` + `DroneBasic.gd` |
| AI 辅助生成弹幕无人机骨架 | — | 骨架代码（review 后合入） |

### Day 2

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 激光无人机 | `DamageSystem` | `DroneLaser.gd`（横向激光柱逻辑） |
| 导弹敌人 | `BulletFactory` | `EnemyMissile.gd`（飞行轨迹 + 爆炸） |
| 治疗无人机 | — | `DroneHealer.gd`（治疗范围逻辑） |
| SpawnSystem 完善 | `LevelManager`（新街提供路段数据） | `SpawnSystem.gd` |

### Day 3

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| BOSS 登场触发 | `LevelManager` | `BossBase.gd` |
| BOSS 第一阶段 | `BulletFactory` | BOSS 弹幕逻辑 |
| BOSS 第二/三阶段 | `WorldStateSystem` | 肘击 + 踩地板逻辑 |
| BOSS 里世界切换 | `WorldStateSystem` | BOSS 阶段切换触发里世界 |
| WorldStateSystem | `EventBus` | `WorldStateSystem.gd` |
| RoleSwapSystem | `Shooter/Driver`（池言いく） | `RoleSwapSystem.gd` |

### Day 4

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 无人机刷新节奏 | `level_config.json` | `SpawnSystem` 完善 |
| 敌人类型动态调度 | `SpawnSystem` | `SpawnSystem` 完善 |
| 对冲摩托车 AI | `BulletFactory` | `EnemyBike.gd` |
| AI 辅助生成摩托车骨架 | — | 骨架代码（review 后合入） |

### Day 5

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 弹药类型系统 | `BulletFactory` + `ConfigManager` | 弹药效果实现 |
| 弹药类型叠加生效验证 | `CombatSystem`（池言いく） | 联调测试 |
| 配件与弹药叠加验证 | `CombatSystem`（池言いく） | 联调测试 |

### Day 7

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 敌人攻击音效接入 | Freesound 资源 | `EnemyBase.gd` 音效触发 |
| 里世界切换音效接入 | `WorldStateSystem` | `WorldEffects.gd` |

### Day 8

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| BGM 获取与集成 | BGM 资源 | `AudioManager` 接入 |
| BOSS 咆哮音效 | BOSS 咆哮音频资源 | `BossBase.gd` 接入 |
| BOSS 行为最终检查 | — | Bug 修复 |

---

## 6. 常见对接问题与处理方式

| 问题场景 | 处理方式 |
|:---------|:---------|
| 玩家子弹打不中敌人 | 检查 BulletPlayer 和 EnemyBase 的碰撞层设置是否匹配 |
| 里世界切换后敌人无敌但没显示护盾 | EnemyBase 需要在 `set_invulnerable()` 时更新视觉 |
| BOSS 弹幕影响驾驶员视线 | 弹幕视觉（子弹拖尾、发光）由 BulletEnemy.gd 控制，不归你管 |
| 抛锚时需要清空所有弹幕 | `SpawnSystem.clear_all_enemies()` + `BulletFactory.clear_all_bullets()` |
| 职责互换后武器数据丢失 | RoleSwapSystem 保存/恢复 Shooter 的 WeaponBase 引用和弹药类型 |
| 敌人弹幕从哪发出 | 由 EnemyBase 子类定义，BulletFactory 根据敌人类型创建对应弹幕 |

---

*本文档版本：1.0*
*最后更新：2026-04-28*
*维护者：长安旧梦*
