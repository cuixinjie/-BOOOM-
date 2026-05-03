# 🙃 (cjs) — 职责边界文档

> 本模块负责人：**🙃 (cjs)**
>
> 负责模块：UI系统 / 数值平衡 / 全流程对接 / 音效总成 / 美术资源对接

---

## 1. 职责概述

你是**全局整合者**——你的任务是把所有模块串联成完整的游戏体验。你负责所有玩家能"看到"的东西（UI、HUD、视觉反馈）、所有数值是否合理、以及所有模块之间的对接是否顺畅。

**核心原则**：你站在所有模块的"前面"，代表玩家的视角。确保信息传达清晰、反馈及时、对接无误。

---

## 2. 负责模块清单

```
scripts/
├── autoload/
│   ├── AudioManager.gd    # 音频管理器（你维护接口）
│   └── ConfigManager.gd   # 配置管理器（你维护接口）
├── systems/
│   └── economy/
│       ├── EconomySystem.gd     # 经济系统
│       ├── DropSystem.gd        # 掉落系统（长安旧梦维护）
│       └── ProgressionSystem.gd # 成长系统
├── ui/
│   ├── HUDController.gd        # HUD 总控制器
│   ├── DriverHUD.gd             # 驾驶员 HUD
│   ├── ShooterHUD.gd            # 射击手 HUD
│   ├── ShopUI.gd               # 商店界面（新街维护 ShopSystem，你维护 UI 布局）
│   ├── MenuController.gd        # 菜单控制器
│   └── UIComponents/
│       ├── HealthBar.gd
│       ├── AmmoDisplay.gd
│       ├── SkillCooldown.gd
│       ├── InventorySlot.gd
│       └── WorldStateIndicator.gd
```

### 依赖关系图（你的视角）

```
你的模块依赖：
  ├── EventBus — 监听所有系统信号
  ├── ConfigManager — 读取所有 JSON 配置
  ├── AudioManager — 播放音效
  ├── GameManager（新街）— 查询游戏状态
  ├── ShopSystem（新街）— 获取商店商品数据
  └── 所有实体的状态（通过 EventBus 获取）

被你的模块依赖：
  ├── 全部模块 — 所有系统通过 EventBus 向你发送状态更新
  ├── 美术组 — 资源命名和路径规范由你定义
  └── 长安旧梦 — 击杀敌人后掉落 UI、里世界状态指示
```

---

## 3. 详细职责说明

### 3.1 HUD 系统

**HUDController.gd — HUD 总控制器**

```gdscript
## HUDController — HUD 总控制器
##
## 功能说明：
## - 管理驾驶员和射击手的 HUD 显示
## - 协调两个 HUD 之间的信息同步
## - 处理分屏布局
## - 处理游戏状态变化时的 HUD 切换
##
## 对接注意事项：
## - DriverHUD 和 ShooterHUD 是子节点，由本控制器统一管理
## - EventBus 信号驱动所有 HUD 更新
## - GameManager（新街）控制 HUD 的显示/隐藏（主菜单隐藏，游戏时显示）
##
## 创建人：🙃
## 创建日期：2026-04-28

# ===== 接口定义 =====
# show_hud() -> void
#   显示 HUD（游戏开始时调用）
#
# hide_hud() -> void
#   隐藏 HUD（主菜单/游戏结束时调用）
#
# update_driver_hud(data: DriverHUDData) -> void
#   更新驾驶员 HUD 数据
#
# update_shooter_hud(data: ShooterHUDData) -> void
#   更新射击手 HUD 数据
#
# show_game_over_screen(victory: bool) -> void
#   显示游戏结束画面
#
# show_pause_menu() -> void
#   显示暂停菜单
# ===== 接口结束 =====
```

**DriverHUD.gd — 驾驶员 HUD**

```gdscript
## DriverHUD — 驾驶员 HUD
##
## 功能说明：
## - 显示机车血量条
## - 显示能量条
## - 显示耐力点数
## - 显示追兵距离指示
## - 显示当前路段进度
## - 显示里世界状态指示
##
## 对接注意事项：
## - EventBus.vehicle_damaged / vehicle_repaired → 更新血量条
## - EventBus.energy_collected → 更新能量条
## - EventBus.skill_used → 更新技能冷却
## - EventBus.chase_distance_changed → 更新追兵距离指示器颜色
## - EventBus.world_state_changed → 更新里世界状态指示
## - EventBus.segment_completed → 更新路段进度
## - HealthBar 组件显示血量，使用红/黄/绿渐变色
## - 耐力点数用图标表示（充能时图标发光）
## - 追兵距离用箭头表示（距离越近越红）
##
## 创建人：🙃
## 创建日期：2026-04-28

# HUD 布局（左半屏）
# [追兵距离箭头]          [路段进度条]
# [血量条]                [能量条]
# [耐力图标 x1]           [技能图标 x5]
# [金币] [熟练度]
```

**ShooterHUD.gd — 射击手 HUD**

```gdscript
## ShooterHUD — 射击手 HUD
##
## 功能说明：
## - 显示当前武器图标
## - 显示弹药数量（当前/最大）
## - 显示弹药类型图标
## - 显示换弹进度条
## - 显示武器瞄准方向指示
## - 显示狙击枪瞄准预判线
## - 霰弹枪显示扇形覆盖区域
##
## 对接注意事项：
## - EventBus.weapon_fired → 播放射击动画
## - EventBus.weapon_reloaded → 播放换弹动画 + 更新弹药显示
## - EventBus.ammo_type_changed → 更新弹药类型图标
## - EventBus.repair_progress_changed → 修车进度条（在驾驶员 HUD 显示）
## - Shooter（池言いく）提供瞄准方向用于绘制瞄准指示
## - 瞄准方向用十字线表示（狙击枪用红线，霰弹枪用扇形）
## - 弹药数量用数字+图标表示，红色表示低弹药
## - 霰弹枪扇形覆盖区域用半透明红色填充
##
## 创建人：🙃
## 创建日期：2026-04-28

# HUD 布局（右半屏）
# [武器图标]              [弹药类型图标]
# [弹药数量: 6 / 6]      [换弹进度条]
# [瞄准指示]              [扇形覆盖（霰弹枪）]
# [预判线（狙击枪）]
```

### 3.2 经济系统

**EconomySystem.gd — 经济系统**

```gdscript
## EconomySystem — 经济系统
##
## 功能说明：
## - 管理金币的获取和消耗
## - 提供金币余额查询
## - 处理购买验证
## - 发射金币变化信号供 HUD 更新
##
## 对接注意事项：
## - EventBus.coin_collected 监听金币获取（由长安旧梦的 DropSystem 发射）
## - ShopSystem（新街）调用 deduct_coins() 进行购买
## - EventBus.shop_purchased 发射金币变化供 HUD 更新
## - 金币余额由 HUD（你的）显示
##
## 创建人：🙃
## 创建日期：2026-04-28

# ===== 接口定义 =====
# get_coins() -> int
#   返回当前金币数量
#
# add_coins(amount: int) -> void
#   增加金币，发射 coin_collected 信号
#
# deduct_coins(amount: int) -> bool
#   扣除金币，成功返回 true（金币不足返回 false）
#
# can_afford(cost: int) -> bool
#   检查是否足够购买
# ===== 接口结束 =====
```

### 3.3 成长系统

**ProgressionSystem.gd — 成长系统**

```gdscript
## ProgressionSystem — 成长系统
##
## 功能说明：
## - 管理熟练度积累
## - 处理升级逻辑
## - 管理升级点分配
## - 应用加点强化效果
##
## 对接注意事项：
## - EventBus.proficiency_gained 监听熟练度获取（由长安旧梦的 DropSystem 发射）
## - EventBus.level_up 发射升级事件
## - 升级面板在躲藏点显示（RestPointManager 新街 触发）
## - 加点强化效果通过装备数据影响 WeaponBase（池言いく）和 VehicleController（池言いく）
## - EventBus.skill_points_changed 发射给 HUD 显示可用点数
##
## 创建人：🙃
## 创建日期：2026-04-28

# ===== 接口定义 =====
# get_current_level() -> int
#   返回当前等级
#
# get_proficiency() -> float
#   返回当前熟练度（0.0 - 1.0）
#
# add_proficiency(amount: float) -> void
#   增加熟练度，升级时自动重置并发放升级点
#
# spend_upgrade_point(skill_id: String, upgrade_level: int) -> bool
#   消耗升级点进行加点，成功返回 true
#
# reset_upgrade_points() -> void
#   重置所有升级点（消耗金币）
#
# get_upgrade_bonus(skill_id: String) -> Dictionary
#   返回指定技能的加点加成
#   例如：{ "damage": 0.15, "fire_rate": 0.0, "range": 0.1 }
#
# get_available_points() -> int
#   返回可用的升级点数
# ===== 接口结束 =====
```

### 3.4 菜单系统

**MenuController.gd — 菜单控制器**

```gdscript
## MenuController — 菜单控制器
##
## 功能说明：
## - 管理主菜单、暂停菜单、死亡画面、通关画面
## - 处理菜单导航
## - 处理游戏状态切换
##
## 对接注意事项：
## - EventBus.game_started → 关闭主菜单
## - EventBus.game_paused → 显示暂停菜单
## - EventBus.game_over → 显示死亡/通关画面
## - EventBus.rest_point_entered → 允许访问暂停菜单功能
## - GameManager（新街）调用 show_menu() / hide_menu()
##
## 创建人：🙃
## 创建日期：2026-04-28
```

### 3.5 UI 组件

**UIComponents/*.gd — UI 组件库**

```gdscript
## HealthBar — 血量条组件
##
## 功能：显示血量，支持动画和颜色变化
## - 血量 > 60%：绿色
## - 血量 30-60%：黄色
## - 血量 < 30%：红色 + 脉动动画
##
## SkillCooldown — 技能冷却组件
##
## 功能：显示技能冷却进度
## - 冷却中显示遮罩动画
## - 冷却完毕发光提示
## - 能量不足显示灰色
##
## AmmoDisplay — 弹药显示组件
##
## 功能：显示当前弹药数量
## - 数字格式：当前/最大
## - 低弹药（<20%）红色闪烁
## - 换弹时显示进度条
##
## WorldStateIndicator — 里世界状态指示器
##
## 功能：显示当前世界状态
## - 表世界（废土）：紫色边框
## - 里世界（沃土）：绿色边框
## - 切换预警：边框闪烁
##
## InventorySlot — 背包格子组件
##
## 功能：显示物品格子
## - 空格子：灰色边框
## - 有物品：显示图标
## - 选中状态：金色边框
```

### 3.6 音频管理器

**AudioManager.gd — 音频管理器**

```gdscript
## AudioManager — 音频管理器
##
## 功能说明：
## - 管理所有音频播放（SFX、BGM、环境音）
## - 提供播放接口给所有系统调用
## - 管理音量设置
## - 处理 BGM 淡入淡出
##
## 对接注意事项：
## - 所有系统通过 AudioManager 播放音效，禁止直接使用 AudioStreamPlayer
## - EventBus.world_state_changed → 切换环境音（废土风声 ↔ 沃土鸟鸣）
## - EventBus.game_started → 播放 BGM
## - EventBus.game_paused → 暂停 BGM
## - EventBus.enemy_killed → 播放击杀音效
## - EventBus.weapon_fired → 播放对应武器射击音效
## - EventBus.vehicle_damaged → 播放受伤音效
## - EventBus.boss_phase_changed → 播放 BOSS 咆哮
## - 音效文件名规范：见美术规范
##
## 创建人：🙃
## 创建日期：2026-04-28

# ===== 接口定义 =====
# play_sfx(sfx_name: String, volume_db: float = 0.0) -> void
#   播放音效（通过 EventBus 或直接调用）
#
# play_bgm(bgm_name: String, fade: bool = true) -> void
#   播放背景音乐（可选淡入淡出）
#
# stop_bgm(fade: bool = true) -> void
#   停止背景音乐
#
# play_environmental(env_name: String) -> void
#   播放环境音（废土风声 / 沃土鸟鸣）
#
# set_volume(category: String, volume: float) -> void
#   设置音量（category: master/sfx/bgm）
#
# pause_all() -> void
#   暂停所有音频（游戏暂停时调用）
#
# resume_all() -> void
#   恢复所有音频（游戏恢复时调用）
# ===== 接口结束 =====
```

### 3.7 配置管理器

**ConfigManager.gd — 配置管理器**

```gdscript
## ConfigManager — 配置管理器
##
## 功能说明：
## - 统一管理所有 JSON 配置文件的加载
## - 提供配置查询接口
## - 缓存已加载配置
##
## 对接注意事项：
## - 所有模块通过 ConfigManager 读取配置，禁止直接 load() JSON
## - 配置文件路径规范：assets/configs/*.json
##
## 创建人：🙃
## 创建日期：2026-04-28

# ===== 接口定义 =====
# get_weapon_stats(weapon_id: String) -> Dictionary
#   获取武器属性配置
#
# get_enemy_stats(enemy_id: String) -> Dictionary
#   获取敌人属性配置
#
# get_level_config(level_id: int) -> Dictionary
#   获取关卡配置
#
# get_shop_items() -> Array
#   获取商店商品列表
#
# get_spawn_patterns(segment_id: int) -> Dictionary
#   获取敌人生成模式
#
# reload_config(config_name: String) -> void
#   重新加载指定配置（用于编辑器调试）
# ===== 接口结束 =====
```

---

## 4. 职责边界（必须遵守）

### 4.1 你可以修改的文件

```
scripts/autoload/AudioManager.gd
scripts/autoload/ConfigManager.gd
scripts/systems/economy/
scripts/ui/
scripts/ui/UIComponents/
```

### 4.2 你**绝对不能**修改的文件

> **如有修改需求，必须与对应负责人协商，经 review 后再合入。**

```
scripts/entities/player/           # 池言いく 负责
scripts/entities/vehicle/          # 池言いく 负责
scripts/entities/enemy/             # 长安旧梦 负责
scripts/entities/bullet/            # 长安旧梦 负责
scripts/core/DamageSystem.gd        # 长安旧梦 负责
scripts/systems/world/              # 长安旧梦 负责
scripts/systems/level/             # 新街 负责
scripts/autoload/GameManager.gd    # 新街 负责
scripts/autoload/InputManager.gd   # 池言いく 负责
scripts/autoload/EventBus.gd       # 需全体协商
scripts/core/ObjectPool.gd         # 通用工具，可提出 issue
```

### 4.3 对接协调职责

作为全局对接者，你的额外职责：

| 对接关系 | 你的协调工作 |
|:---------|:-----------|
| 程序 ↔ 美术 | 定义资源命名规范、路径规范、动画命名规范 |
| 新街 ↔ 长安旧梦 | 确认 SpawnSystem 接口和 LevelManager 调用方式 |
| 新街 ↔ 池言いく | 确认 RestPointManager 和 装备数据传递方式 |
| 长安旧梦 ↔ 池言いく | 确认 DamageSystem 接口和 BulletFactory 调用方式 |
| 所有模块 ↔ 音效 | 统一 AudioManager 接口，所有人通过你播放音效 |

---

## 5. Day-by-Day 开发计划

### Day 1

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 基础 UI 框架（HUD 布局） | 其他成员提供 HUD 数据结构 | `HUDController.gd` + `DriverHUD.gd` + `ShooterHUD.gd` |
| AI 代码质量标准文档 | — | `AI_CODE_REVIEW_STANDARDS.md` |
| AI 生成代码 review 流程 | — | review 流程说明 |
| 音效目录规范定义 | — | 音效文件命名规范文档 |

### Day 2

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 里世界预警系统 | `WorldStateSystem`（长安旧梦）信号 | `WorldStateIndicator.gd` |
| 商店画面框架 | `ShopSystem`（新街） | `ShopUI.gd` 布局骨架 |
| 通关画面框架 | `GameManager`（新街） | `MenuController.gd` |
| 全流程 UI 对接测试 | 所有系统信号 | 集成测试 |

### Day 3

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| Day 1–2 bug 修复 | 各系统 | Bug 修复 |
| 全流程 UI 验证 | 所有系统 | 集成测试 |
| 对接问题汇总 | — | 对接问题记录文档 |

### Day 4

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 金币掉落系统 | `DropSystem`（长安旧梦） | `EconomySystem.gd` |
| 能量球掉落系统 | `DropSystem`（长安旧梦） | `EconomySystem.gd` |
| 熟练度掉落系统 | `DropSystem`（长安旧梦） | `ProgressionSystem.gd` |
| HUD 更新逻辑 | EventBus 信号 | HUD 更新逻辑 |

### Day 5

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 全系统集成测试 | 所有系统 | 集成测试 |
| Day 1–4 bug 修复 | 各系统反馈 | Bug 修复 |
| 数值初步平衡 | 所有数值配置 | `weapon_stats.json` / `enemy_stats.json` 调优 |

### Day 6

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 完整流程测试 | 所有系统 | 从头到尾通关一次 |
| 核心 bug 修复 | 测试结果 | Bug 修复 |
| 白盒 → 正式美术资源替换 | 美术组 Day 5 交付 | 资源替换 |

### Day 7

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 受伤屏幕效果 | — | 红色边缘闪烁 + 血条抖动 |
| 低血量警报 | `vehicle_damaged` 信号 | 屏幕脉动 + 模糊 |
| HUD 最终调优 | 所有模块反馈 | UI 优化 |
| 所有音效整理归类 | 新街（Day 7 任务） | 音效目录整理 |
| 音效系统接入验证 | AudioManager | 音效接入测试 |

### Day 8

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 全系统集成测试 | — | 集成测试 |
| 帧率稳定性检查 | — | 性能分析 |
| Day 1–7 bug 修复 | — | Bug 修复 |
| 后处理最终调优 | 美术后处理配置 | 后处理效果接入 |
| 屏幕震动效果接入 | — | 屏幕震动系统 |

### Day 10–11

| 任务 | 依赖 | 产出文件 |
|:-----|:-----|:---------|
| 全流程 UI 最终检查 | — | 最终检查清单 |
| 存档/设置功能 | — | 设置界面（如时间允许） |
| 帧率最终检查 | — | 性能优化 |
| 全系统最终测试 | — | 最终测试报告 |
| Windows exe 打包 | — | 构建测试 |

---

## 6. 对接检查清单（你的核心职责）

每次集成时，你必须验证以下内容：

### 6.1 信号对接检查

| 信号 | 发射方 | 监听方（你负责验证） | 验证点 |
|:-----|:-------|:-------------------|:-------|
| `vehicle_damaged` | 池言いく | DriverHUD | 血量条正确减少 |
| `vehicle_repaired` | 池言いく | DriverHUD | 血量条正确增加 |
| `weapon_fired` | 池言いく | ShooterHUD | 弹药数正确减少 |
| `weapon_reloaded` | 池言いく | ShooterHUD | 弹药数重置 |
| `enemy_killed` | 长安旧梦 | — | 击杀显示正确 |
| `world_state_changed` | 长安旧梦 | WorldStateIndicator | 世界状态指示正确 |
| `segment_completed` | 新街 | — | 进度更新正确 |
| `coin_collected` | 长安旧梦 | DriverHUD | 金币数正确增加 |
| `chase_distance_changed` | 池言いく | DriverHUD | 距离指示正确 |
| `repair_progress_changed` | 池言いく | DriverHUD | 修车进度条正确 |

### 6.2 UI 数据验证

| HUD 元素 | 数据来源 | 验证点 |
|:---------|:---------|:-------|
| 血量条 | Driver.get_vehicle_health() | 数值和颜色正确 |
| 能量条 | Driver.get_energy() | 数值正确 |
| 耐力点数 | Driver.get_stamina() | 图标数量正确 |
| 弹药数 | Shooter.get_ammo_in_magazine() | 数值正确 |
| 武器图标 | Shooter.get_current_weapon() | 图标对应武器 |
| 弹药类型 | Shooter.get_ammo_type() | 图标对应类型 |
| 金币数 | EconomySystem.get_coins() | 数值正确 |
| 熟练度 | ProgressionSystem.get_proficiency() | 进度条正确 |
| 等级 | ProgressionSystem.get_current_level() | 数字正确 |
| 追兵距离 | ChaseSystem.get_chase_distance() | 颜色正确 |

### 6.3 数值平衡检查（Day 5 开始）

| 检查项 | 标准 |
|:-------|:-----|
| 弹幕无人机血量 | 霰弹枪 5 发内击杀 / 手枪 2-3 发击杀 |
| 路段 1 密度 | 射手能处理，不会漏太多 |
| 路段 3 密度 | 有压力但不至于是弹幕地狱 |
| 商店价格 | 金币掉落速度能支撑合理购买频率 |
| 技能能量消耗 | 能量获取速度能支撑技能使用频率 |

---

## 7. 常见对接问题与处理方式

| 问题场景 | 处理方式 |
|:---------|:---------|
| HUD 不更新 | 检查 EventBus 信号是否正确连接，使用 debug 模式打印信号发射 |
| 数值显示不同步 | 检查数据更新顺序，确保发射信号在数据更新之后 |
| 美术资源路径错误 | 检查资源路径是否符合规范（snake_case，res:// 开头） |
| 音效无法播放 | 检查 AudioManager 是否初始化，检查文件格式（ogg） |
| BGM 不切换 | EventBus.world_state_changed 监听是否正确，检查环境音路径 |
| 低血量警报一直触发 | 检查血量阈值设置（≤30%）和脉动动画触发条件 |
| 修车进度条不显示 | 检查 BreakdownRecovery 是否有正确发射 repair_progress_changed |
| 商店 UI 布局错位 | 检查分屏设置（左右各占 50%），确保锚点设置正确 |

---

*本文档版本：1.0*
*最后更新：2026-04-28*
*维护者：🙃 (cjs)*
