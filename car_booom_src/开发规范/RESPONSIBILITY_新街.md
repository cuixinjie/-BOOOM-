# 新街 — 职责边界文档

> 本模块负责人：**新街**
>
> 负责模块：场景框架 / 路段机制 / 特殊路段 / 商店系统 / 音效获取

---

## 1. 职责概述

你负责**游戏世界的框架与流通**——场景如何组织、路段如何切换、玩家如何在关卡中流动、以及货币如何转化为战斗力。

**核心原则**：你构建的是"容器"，其他模块在其中运行。确保这些容器有清晰的入口和出口，不对内部逻辑做假设。

---

## 2. 负责模块清单

### 2.1 场景与关卡系统

```
scripts/
├── autoload/
│   └── GameManager.gd          # 你负责维护
├── systems/
│   ├── level/
│   │   ├── LevelManager.gd      # 关卡管理器
│   │   ├── SegmentGenerator.gd  # 路段生成器
│   │   └── RestPointManager.gd  # 躲藏点管理
│   └── special/
│       └── SpecialSegmentManager.gd  # 特殊路段管理
scenes/
├── levels/
│   ├── Level01.tscn
│   ├── Level02.tscn
│   ├── Level03.tscn
│   └── rest_point.tscn
├── ui/
│   └── shop/
│       └── ShopUI.tscn
```

### 2.2 依赖关系图（你的视角）

```
你的模块依赖 → 被你的模块依赖

依赖方：
  ├── InputManager（获取关卡切换触发条件）
  ├── EventBus（监听所有系统信号）
  └── ConfigManager（读取关卡配置 JSON）

被依赖方：
  ├── CombatSystem（需要知道当前路段类型以调整敌人生成）
  ├── SpawnSystem（提供路段数据和控制生成节奏）
  ├── PlayerBase/Driver/Shooter（关卡开始/结束时的玩家状态管理）
  ├── ShopSystem（躲藏点商店需要知道当前关卡进度）
  ├── WorldStateSystem（里世界切换时需要知道当前路段状态）
  ├── ChaseSystem（需要知道当前路段以调整追兵逼近速度）
  └── EconomySystem（路段完成奖励的发放）
```

---

## 3. 详细职责说明

### 3.1 场景管理框架

**GameManager.gd — 游戏总管理器**

```gdscript
## GameManager — 管理游戏主状态和全局游戏逻辑
##
## 功能说明：
## - 管理游戏状态机（主菜单 → 游戏中 → 暂停 → 游戏结束）
## - 协调各系统初始化顺序
## - 提供全局游戏状态查询接口
##
## 对接注意事项：
## - LevelManager 通过 EventBus.game_started 启动关卡
## - ChaseSystem 通过 EventBus.game_over 触发失败流程
## - UI 层通过 get_game_state() 查询当前状态，不直接修改
## - 多人分支：所有玩家相关状态由 PlayerBase 管理，不在此文件中堆砌
##
## 创建人：新街
## 创建日期：2026-04-28

class_name GameManager
extends Node

## ===== 公开接口 =====
## get_game_state() -> GameState
##   返回当前游戏状态（MAIN_MENU / PLAYING / PAUSED / GAME_OVER）
##
## start_game(level_id: int = 1) -> void
##   开始指定关卡，切换状态到 PLAYING，发射 game_started 信号
##
## pause_game() -> void
##   暂停游戏，切换状态到 PAUSED
##
## resume_game() -> void
##   恢复游戏，切换状态回 PLAYING
##
## end_game(victory: bool) -> void
##   结束游戏，切换状态到 GAME_OVER，发射 game_over 信号
##
## restart_level() -> void
##   在当前关卡重新开始
##
## get_current_level_id() -> int
##   返回当前关卡 ID
## ===== 接口结束 =====
```

**状态机**：

```gdscript
enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER }
```

### 3.2 关卡管理器

**LevelManager.gd — 关卡管理器**

```gdscript
## LevelManager — 管理关卡流程、路段切换
##
## 功能说明：
## - 管理 3 个路段 + 躲藏点 + BOSS 的完整关卡流程
## - 控制路段时长（每段 3.5 分钟 + BOSS 战 3 分钟）
## - 触发路段完成事件和躲藏点进入事件
## - 管理路段难度曲线
##
## 对接注意事项：
## - 依赖 SpawnSystem，根据路段进度调整敌人生成节奏
## - 依赖 SegmentGenerator，指示何时生成下一路段
## - 依赖 RestPointManager，进入躲藏点时暂停游戏
## - 依赖 WorldStateSystem，里世界切换时保存/恢复路段状态
## - 依赖 ChaseSystem，路段完成时给予追兵距离奖励
## - 发出的信号：segment_completed / rest_point_entered / boss_spawned
##
## 创建人：新街
## 创建日期：2026-04-28

# 接口定义
# start_level(level_id: int) -> void
# next_segment() -> void
# enter_rest_point() -> void
# spawn_boss() -> void
# get_current_segment() -> int
# get_segment_progress() -> float  # 0.0 - 1.0
```

**路段流程**：

```
关卡开始
    │
    ▼
路段 1（3.5min）──► 躲藏点（暂停）──► 路段 2（3.5min）──► 躲藏点
    │                                      │
    │                                      ▼
    │                               路段 3（3.5min）
    │                                      │
    │                                      ▼
    └──► 特殊路段（30%概率，每段最多一种）◄───┘
                                        │
                                        ▼
                                    BOSS 战（3min）
                                        │
                                        ▼
                                    游戏结束
```

**路段难度曲线配置**（在 `level_config.json` 中管理）：

```json
{
  "segment_1": {
    "duration_seconds": 210,
    "enemy_density": "low",
    "enemy_types": ["drone_basic"],
    "obstacle_frequency": "low",
    "special_segment_chance": 0.3
  },
  "segment_2": {
    "duration_seconds": 210,
    "enemy_density": "medium",
    "enemy_types": ["drone_basic", "drone_healer", "drone_laser", "missile"],
    "obstacle_frequency": "medium",
    "special_segment_chance": 0.3
  },
  "segment_3": {
    "duration_seconds": 210,
    "enemy_density": "high",
    "enemy_types": ["drone_basic", "drone_healer", "drone_laser", "missile", "enemy_bike"],
    "obstacle_frequency": "high",
    "special_segment_chance": 0.3
  }
}
```

### 3.3 路段生成器

**SegmentGenerator.gd — 路段生成器**

```gdscript
## SegmentGenerator — 管理路段内容生成
##
## 功能说明：
## - 根据配置生成路段内容（障碍分布、敌人生成点）
## - 管理特殊路段的触发和持续时间（1.5分钟）
## - 提供路段完成判定
##
## 对接注意事项：
## - 依赖 RoadObstacle.gd（池言いく）生成路面障碍
## - 依赖 SpawnSystem（长安旧梦）提供敌人生成点
## - 特殊路段效果通过 EventBus 通知相关系统
## - 美术背景切换信号发给 WorldStateSystem
##
## 创建人：新街
## 创建日期：2026-04-28

# 特殊路段类型
enum SpecialSegmentType { NONE, ROAD_NARROW, EMP, VISION_FOG }

# 接口
# generate_segment(segment_id: int, difficulty: String) -> void
# trigger_special_segment(type: SpecialSegmentType) -> void
# end_special_segment() -> void
# get_current_obstacles() -> Array
```

**三种特殊路段的触发方式**：

| 路段类型 | 触发信号 | 持续时间 | 影响系统 |
|:--------|:---------|:--------|:---------|
| 道路变窄 | `SpecialSegmentManager.trigger("road_narrow")` | 90s | Driver（车道宽度） + RoadObstacle |
| EMP干扰 | `SpecialSegmentManager.trigger("emp")` | 90s | WeaponSystem（装填速度） + VehicleSkills |
| 视野遮蔽 | `SpecialSegmentManager.trigger("vision_fog")` | 90s | ShooterHUD（迷雾覆盖） + 敌人发现率 |

### 3.4 躲藏点管理器

**RestPointManager.gd — 躲藏点管理**

```gdscript
## RestPointManager — 管理躲藏点功能
##
## 功能说明：
## - 进入躲藏点时暂停游戏并显示 UI
## - 提供职责互换入口
## - 提供商店入口
## - 允许玩家离开躲藏点继续关卡
##
## 对接注意事项：
## - 依赖 ShopSystem（你的 ShopUI.gd），商店界面集成在此
## - 依赖 RoleSwapSystem（长安旧梦的 WorldStateSystem），职责互换逻辑
## - 依赖 EconomySystem，奖励预览和发放
## - 依赖 VehicleUpgrade（池言いく），显示当前升级状态
##
## 创建人：新街
## 创建日期：2026-04-28

# 接口
# enter_rest_point() -> void    # 暂停游戏，显示躲藏点 UI
# exit_rest_point() -> void     # 恢复游戏，继续路段
# open_shop() -> void           # 打开商店界面
# swap_roles() -> void          # 互换驾驶员/射击手
# get_upgrade_points() -> int   # 返回可用的升级点数
```

### 3.5 商店系统

**ShopSystem.gd / ShopUI.gd — 商店系统与界面**

```gdscript
## ShopSystem — 管理商店逻辑
##
## 功能说明：
## - 管理商品列表和价格
## - 处理购买逻辑（金币扣除、物品发放）
## - 验证购买条件（金钱足够、背包空间）
##
## 对接注意事项：
## - 依赖 EconomySystem（🙈）获取金币数量
## - 依赖 WeaponSystem（池言いく）进行武器购买和装备
## - 依赖 VehicleUpgrade（池言いく）进行载具升级购买
## - 依赖 AttachmentSystem（池言いく）进行配件购买
## - 依赖 DropSystem（长安旧梦）提供商店商品刷新
## - 购买成功发射 shop_purchased 信号
##
## 创建人：新街
## 创建日期：2026-04-28

## ShopUI — 商店界面控制
##
## 功能说明：
## - 显示商品列表和价格
## - 显示玩家当前金币
## - 处理购买按钮交互
## - 音效反馈（购买成功/失败）
##
## 对接注意事项：
## - 美术提供商品图标（见美术规范中的交接约定）
## - 商品数据由 ShopSystem 驱动，UI 只负责展示
## - 子弹图标和武器图标来自 assets/art/bullets/ 和 assets/art/weapons/
```

**商店数据结构**（由 ConfigManager 加载）：

```json
{
  "shop_items": [
    { "id": "weapon_smg", "type": "weapon", "price": 250, "data": "smg" },
    { "id": "weapon_shotgun", "type": "weapon", "price": 350, "data": "shotgun" },
    { "id": "weapon_sniper", "type": "weapon", "price": 450, "data": "sniper" },
    { "id": "attachment_stabilizer_basic", "type": "attachment", "price": 80, "data": "stabilizer_1" },
    { "id": "ammo_armor_piercing", "type": "ammo", "price": 120, "data": "armor_piercing" },
    { "id": "consumable_health", "type": "consumable", "price": 50, "data": "health_potion" }
  ]
}
```

### 3.6 音效获取（Day 7）

**Day 7 任务**：从 Freesound 下载并整理音效。

| 音效类型 | 文件命名规范 | 存放路径 |
|:--------|:------------|:---------|
| 射击音效 | `sfx_shoot_[weapon].ogg` | `assets/audio/sfx/` |
| 命中音效 | `sfx_hit_[target].ogg` | `assets/audio/sfx/` |
| 爆炸音效 | `sfx_explosion_[size].ogg` | `assets/audio/sfx/` |
| 环境音 | `bgm_[world_state].ogg` | `assets/audio/bgm/` |

---

## 4. 职责边界（必须遵守）

### 4.1 你可以修改的文件

```
scripts/autoload/GameManager.gd
scripts/systems/level/
scripts/systems/special/SpecialSegmentManager.gd
scripts/systems/economy/ShopSystem.gd
scripts/ui/ShopUI.gd
scripts/ui/MenuController.gd
scenes/levels/*.tscn
scenes/ui/shop/*.tscn
scenes/main/Main.tscn
assets/configs/level_config.json
assets/configs/shop_items.json
assets/audio/
```

### 4.2 你**绝对不能**修改的文件

> **如有修改需求，必须与对应负责人协商，经 review 后再合入。**

```
scripts/entities/player/           # 池言いく 负责
scripts/entities/vehicle/          # 池言いく 负责
scripts/systems/combat/            # 池言いく + 长安旧梦 负责
scripts/systems/world/             # 长安旧梦 负责
scripts/entities/enemy/            # 长安旧梦 负责
scripts/entities/bullet/           # 长安旧梦 负责
scripts/core/DamageSystem.gd       # 长安旧梦 负责
scripts/core/ObjectPool.gd         # 通用工具，可提出 issue
scripts/autoload/EventBus.gd       # 通用信号定义，需全体协商
scripts/autoload/InputManager.gd  # 长安旧梦 负责维护接口定义
```

### 4.3 特殊路段：需对接的系统

| 特殊路段 | 需要你通知的系统 | 通过什么方式通知 |
|:---------|:----------------|:----------------|
| 道路变窄 | VehicleController（池言いく） | `EventBus.emit("road_width_changed", width_ratio)` |
| EMP干扰 | WeaponSystem + VehicleSkills（池言いく） | `EventBus.emit("emp_activated")` / `EventBus.emit("emp_deactivated")` |
| 视野遮蔽 | ShooterHUD（🙃） | `EventBus.emit("fog_activated", coverage_ratio)` |

### 4.4 躲藏点：需对接的系统

| 功能 | 对接方 | 对接方式 |
|:-----|:-------|:---------|
| 打开商店 | ShopSystem（你的） | 内部调用 |
| 职责互换 | WorldStateSystem（长安旧梦） | `EventBus.emit("role_swap_requested")` |
| 升级加点 | ProgressionSystem（🙃） | `EventBus.emit("rest_point_entered")` → ProgressionSystem 显示加点面板 |
| 能量恢复 | VehicleController（池言いく） | `EventBus.emit("energy_restored", amount)` |
| 状态重置 | 各系统 | 各自监听 `rest_point_entered` 进行重置 |

---

## 5. Day-by-Day 开发计划

### Day 1

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 场景框架搭建 | — | `scenes/main/Main.tscn` |
| 基础对象池 | — | `scripts/core/ObjectPool.gd`（框架） |
| 关卡结构框架 | — | `scripts/systems/level/LevelManager.gd`（骨架） |
| 障碍数据框架 | ConfigManager | `scripts/systems/level/RoadObstacle.gd`（接口占位） |

### Day 2

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 里世界切换（场景替换） | WorldStateSystem（长安旧梦提供切换信号） | `LevelManager` 接入场景切换 |
| 特殊路段框架 | — | `scripts/systems/special/SpecialSegmentManager.gd` |
| 障碍生成配置 | RoadObstacle（池言いく） | `assets/configs/level_config.json` |

### Day 3

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 全场景联调 | 所有系统就绪 | 集成测试 |
| 特殊路段逻辑 | SpawnSystem（长安旧梦）+ 特效（美术） | `SpecialSegmentManager.gd` 完整实现 |
| Checkpoint #1 验收 | — | 核心循环跑通 |

### Day 5

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 商店完整逻辑 | EconomySystem（🙃）+ 武器系统（池言いく） | `ShopSystem.gd` + `ShopUI.gd` |
| 配件系统对接 | AttachmentSystem（池言いく） | ShopUI 配件页 |

### Day 7

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 音效资源获取 | Freesound | `assets/audio/sfx/` + `assets/audio/bgm/` |
| 音效集成 | AudioManager | `AudioManager` 接入新音效 |

### Day 8

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 数值调优 | 长安旧梦 + 池言いく + 🙃 | `level_config.json` 最终版 |
| 里世界转场 | WorldStateSystem（长安旧梦） | 转场动画接入 |

---

## 6. 与其他成员的接口约定

### 6.1 与 长安旧梦 的接口

| 你的需求 | 你发给长安旧梦 | 长安旧梦 发给你 |
|:---------|:--------------|:--------------|
| 路段敌人生成 | 提供路段类型和密度参数 | 敌人生成位置和行为配置 |
| BOSS 登场 | `boss_spawned` 信号 | BOSS 节点引用 |
| 里世界切换 | `world_state_changed` 信号 | 无敌状态是否反转 |
| 敌人刷新节奏 | 提供路段进度 `0.0–1.0` | 按密度曲线生成敌人数量的配置 |

### 6.2 与 池言いく 的接口

| 你的需求 | 你发给池言いく | 池言いく 发给你 |
|:---------|:--------------|:--------------|
| 躲藏点功能 | `rest_point_entered` 信号 | 玩家装备数据用于商店展示 |
| 障碍生成 | 提供路段难度曲线 | 障碍节点引用 |
| 特殊路段 | EMP/视野事件信号 | 装填速度/视野数据变化 |
| 商店购买 | 无 | 武器/配件/弹药购买成功通知 |

### 6.3 与 🙃 的接口

| 你的需求 | 你发给 🙃 | 🙃 发给你 |
|:---------|:---------|:---------|
| 商店 UI | `shop_purchased` 信号（金币变化） | 商店界面功能需求 |
| 路段完成 | `segment_completed` 信号 | 奖励预览 UI 需求 |
| 游戏状态 | `game_started` / `game_over` 等信号 | 状态 UI 需求 |
| 特殊路段 | 事件信号 | 特效 UI 需求（里世界预警边框等） |

---

## 7. 常见对接问题与处理方式

| 问题场景 | 处理方式 |
|:---------|:---------|
| 需要知道敌人在哪个位置 | 通过 `EventBus.emit("enemy_spawned", position)` 监听，不直接获取 SpawnSystem 引用 |
| 需要知道玩家当前武器 | 通过 `EventBus.emit("weapon_changed", weapon_id)` 监听，不直接获取 Shooter 引用 |
| 需要控制敌人生成节奏 | 在 `level_config.json` 中配置，由 SpawnSystem 读取，你只控制路段时长 |
| 商店需要知道玩家有什么装备 | 池言いく 会在 `rest_point_entered` 时通过信号发送装备数据，ShopUI 只展示 |
| 躲藏点需要恢复能量 | 你发出 `rest_point_entered`，各系统自行监听并恢复状态 |

---

*本文档版本：1.0*
*最后更新：2026-04-28*
*维护者：新街*
