# MADMEN — Pull Request 审查标准

> 本文档是项目管理员（你）用于审查团队成员 PR 的标准文件。
>
> 所有 AI 辅助代码审查时必须遵循本文档。
>
> **维护者**：管理员（你）
>
> **版本**：1.0
>
> **更新日期**：2026-04-30

---

## 目录

1. [审查流程概览](#1-审查流程概览)
2. [团队成员职责速查表](#2-团队成员职责速查表)
3. [代码质量标准](#3-代码质量标准)
4. [架构层级检查](#4-架构层级检查)
5. [跨模块通信检查](#5-跨模块通信检查)
6. [接口一致性检查](#6-接口一致性检查)
7. [配置数据检查](#7-配置数据检查)
8. [数值策划一致性检查](#8-数值策划一致性检查)
9. [边界条件与异常处理检查](#9-边界条件与异常处理检查)
10. [信号链路验证](#10-信号链路验证)
11. [性能与优化检查](#11-性能与优化检查)
12. [文档与注释检查](#12-文档与注释检查)
13. [Git 规范检查](#13-git-规范检查)
14. [按模块类型的审查重点](#14-按模块类型的审查重点)
15. [审查结论标准](#15-审查结论标准)

---

## 1. 审查流程概览

```
PR 提交
    │
    ▼
┌─────────────────────────────────────────────┐
│ 第一步：基础检查                              │
│ - 文件路径是否正确                           │
│ - 是否修改了禁止修改的文件                   │
│ - Commit 消息格式是否规范                    │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ 第二步：代码质量检查                          │
│ - 命名规范遵守情况                           │
│ - 架构层级是否违规                           │
│ - 跨模块通信是否通过 EventBus               │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ 第三步：功能正确性检查                        │
│ - 接口定义与实现是否一致                     │
│ - 数值与策划案是否一致                       │
│ - 边界条件和异常处理                         │
│ - 信号链路是否完整                           │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ 第四步：性能与最佳实践                        │
│ - 对象池使用情况                             │
│ - 硬编码检查                                 │
│ - 调试代码残留检查                           │
└─────────────────────────────────────────────┘
    │
    ▼
    审查结论
```

---

## 2. 团队成员职责速查表

| 成员 | 负责模块 | 可修改的文件 | 禁止修改的文件 |
|:-----|:---------|:------------|:--------------|
| **新街** | 场景/关卡/商店 | `GameManager.gd`、`LevelManager.gd`、`SegmentGenerator.gd`、`SpecialSegmentManager.gd`、`ShopSystem.gd`、场景文件 `.tscn`、`level_config.json` | `scripts/entities/player/`、`scripts/entities/vehicle/`、`scripts/systems/combat/`、`scripts/systems/world/` |
| **长安旧梦** | 敌人/BOSS/AI/里世界 | `DamageSystem.gd`、`EnemyBase.gd`、各敌人脚本、`SpawnSystem.gd`、`WorldStateSystem.gd`、`RoleSwapSystem.gd`、`enemy_stats.json` | `scripts/entities/player/`、`scripts/entities/vehicle/`、`scripts/systems/combat/`、`scripts/systems/economy/`、`scripts/ui/` |
| **池言いく** | 玩家/武器/物理 | `InputManager.gd`、`Driver.gd`、`Shooter.gd`、武器脚本、`VehicleController.gd`、`BreakdownRecovery.gd`、`ChaseSystem.gd`、`WeaponSystem.gd` | `scripts/entities/enemy/`、`scripts/entities/bullet/`、`scripts/systems/world/`、`scripts/systems/economy/`、`scripts/ui/` |
| **cjs** | UI/经济/对接 | `HUDController.gd`、`DriverHUD.gd`、`ShooterHUD.gd`、`EconomySystem.gd`、`ProgressionSystem.gd`、`AudioManager.gd`、`ConfigManager.gd`、`ShopUI.gd` | `scripts/entities/player/`、`scripts/entities/vehicle/`、`scripts/entities/enemy/` |

---

## 3. 代码质量标准

### 3.1 命名规范检查

| 类型 | 规范 | 正确示例 | 错误示例 |
|:-----|:-----|:---------|:---------|
| 类名 | PascalCase | `VehicleController` | `vehicle_controller`、`vehicleController` |
| 变量/函数 | snake_case | `current_health`、`get_vehicle_health()` | `currentHealth`、`getVehicleHealth()` |
| 常量 | SCREAMING_SNAKE | `MAX_SPEED`、`RELOAD_TIME` | `maxSpeed`、`MAX_SPEED_VALUE` |
| 信号 | snake_case | `enemy_killed`、`vehicle_damaged` | `enemyKilled`、`EnemyKilled` |
| 枚举类型 | PascalCase | `WorldState`、`AmmoType` | `world_state`、`WORLD_STATE` |
| 枚举值 | SCREAMING_SNAKE | `SURFACE`、`INVERSE` | `surface`、`Surface` |
| 文件名 | 与类名一致，`.gd` | `VehicleController.gd` | `vehicle_controller.gd`、`VehicleController.gdscript` |
| 场景节点名 | snake_case，末尾带类型缩写 | `player_motorcycle`、`enemy_drone_basic` | `PlayerMotorcycle`、`EnemyDroneBasic` |

### 3.2 脚本头部模板检查

每个 `.gd` 脚本必须包含以下格式的文档头：

```gdscript
## [模块名称] — [一句话描述]
##
## 功能说明：
## - [功能点1]
## - [功能点2]
##
## 对接注意事项：
## - [本模块被哪些模块依赖]
## - [本模块依赖哪些模块]
##
## 创建人：[姓名]
## 创建日期：[YYYY-MM-DD]

class_name [ClassName]
extends [ParentClass]
# ... 实现代码 ...
```

**检查点**：
- [ ] 有完整的模块描述
- [ ] 有功能说明列表
- [ ] 有对接注意事项
- [ ] 有创建人和日期
- [ ] `class_name` 与文件名一致

---

## 4. 架构层级检查

### 4.1 层级依赖规则

```
┌──────────────────────────────────────────┐
│           Autoload（单例层）               │  可访问：Autoload, Core
├──────────────────────────────────────────┤
│           Core（核心层）                   │  可访问：Autoload, Core
├──────────────────────────────────────────┤
│           Systems（系统层）                │  可访问：Autoload, Core, Systems
├──────────────────────────────────────────┤
│           Entities（实体层）               │  可访问：Autoload, Core
├──────────────────────────────────────────┤
│           UI（界面层）                     │  可访问：Autoload, Core
└──────────────────────────────────────────┘
```

**常见违规示例**：

| 违规类型 | 错误代码 | 正确做法 |
|:---------|:---------|:---------|
| System 访问 Entity | `SpawnSystem` 中直接调用 `Driver.gd` 的方法 | 通过 `EventBus.emit_signal()` |
| Entity 访问 UI | `EnemyBase` 中直接修改 `DriverHUD.gd` 的血条 | 通过 `EventBus.enemy_killed.emit()` |
| UI 访问 System | `ShopUI` 中直接修改 `SpawnSystem` 的敌人生成节奏 | 通过 `EventBus` 信号 |
| 跨层直接引用 | `WeaponBase` 中 `get_node("/root/SpawnSystem")` | 通过 `EventBus` 或依赖注入 |

### 4.2 文件位置检查

| 文件位置 | 应在目录 | 不应在目录 |
|:---------|:---------|:-----------|
| `GameManager.gd` | `scripts/autoload/` | `scripts/systems/` |
| `DamageSystem.gd` | `scripts/core/` | `scripts/systems/` |
| `SpawnSystem.gd` | `scripts/systems/level/` | `scripts/systems/world/` |
| `Driver.gd` | `scripts/entities/player/` | `scripts/systems/` |
| `HUDController.gd` | `scripts/ui/` | `scripts/systems/` |

---

## 5. 跨模块通信检查

### 5.1 EventBus 使用规范

**必须通过 EventBus 通信的场景**：
- 实体 → UI（如敌人死亡更新金币）
- 系统 → 实体（如关卡完成触发奖励）
- 实体 → 系统（如玩家输入通知系统）
- 任何跨模块的状态变化通知

**检查点**：
- [ ] 跨模块通信使用 `EventBus.emit_signal()` 或 `EventBus.[signal_name].emit()`
- [ ] 监听使用 `EventBus.[signal_name].connect()`
- [ ] 不存在直接 `get_node()` 获取其他模块引用用于方法调用

**正确示例**：
```gdscript
# 敌人死亡时发射信号
EventBus.enemy_killed.emit(enemy, killer)

# HUD 监听信号
func _ready():
    EventBus.enemy_killed.connect(_on_enemy_killed)
```

**错误示例**：
```gdscript
# 禁止：直接获取其他模块引用
var economy = get_node("/root/EconomySystem")
economy.add_coins(10)

# 禁止：直接调用其他实体的方法
other_entity.take_damage(damage)
```

### 5.2 EventBus 信号定义位置

所有 EventBus 信号必须在 `scripts/autoload/EventBus.gd` 中定义。

**检查点**：
- [ ] 新增信号在 `EventBus.gd` 中定义
- [ ] 信号名称符合 snake_case 规范
- [ ] 信号参数类型正确

---

## 6. 接口一致性检查

### 6.1 接口定义规范

每个模块必须在脚本头部明确声明公开接口：

```gdscript
## ===== 接口定义 =====
## get_vehicle_health() -> float
##   返回当前机车血量
##
## take_damage(amount: float) -> void
##   使机车受到伤害，会触发 vehicle_damaged 信号
##
## repair(amount: float) -> void
##   修复机车，回复指定血量
## ===== 接口结束 =====
```

### 6.2 检查点

- [ ] 接口在脚本头部有明确定义
- [ ] 接口文档包含参数说明和返回值类型
- [ ] 实现与文档一致
- [ ] 副作用（如发射信号）在文档中说明

### 6.3 各模块核心接口速查

**池言いく的模块**：

| 模块 | 关键接口 |
|:-----|:---------|
| Driver | `get_vehicle_health()`, `take_damage()`, `trigger_breakdown()` |
| Shooter | `fire(direction)`, `reload()`, `get_ammo_in_magazine()` |
| InputManager | `get_driver_input()`, `get_shooter_input()` |
| BreakdownRecovery | `start_breakdown_recovery()`, `update_repair(delta)` |
| ChaseSystem | `get_chase_distance()`, `add_distance_reward()` |

**长安旧梦的模块**：

| 模块 | 关键接口 |
|:-----|:---------|
| DamageSystem | `calculate_damage()`, `apply_damage()` |
| SpawnSystem | `spawn_enemy()`, `clear_all_enemies()` |
| WorldStateSystem | `get_current_world()`, `invert_shield_states()` |
| BulletFactory | `create_player_bullet()`, `create_enemy_bullet()` |

**新街的模块**：

| 模块 | 关键接口 |
|:-----|:---------|
| LevelManager | `start_level()`, `enter_rest_point()`, `spawn_boss()` |
| SegmentGenerator | `generate_segment()`, `trigger_special_segment()` |
| ShopSystem | `purchase_item()`, `get_item_list()` |

**cjs的模块**：

| 模块 | 关键接口 |
|:-----|:---------|
| HUDController | `show_hud()`, `update_driver_hud()` |
| EconomySystem | `get_coins()`, `add_coins()`, `deduct_coins()` |
| ProgressionSystem | `get_proficiency()`, `add_proficiency()` |

---

## 7. 配置数据检查

### 7.1 JSON 配置文件规范

**必须使用 JSON 配置的场景**：
- 武器属性（`weapon_stats.json`）
- 敌人属性（`enemy_stats.json`）
- 关卡配置（`level_config.json`）
- 商店商品（`shop_items.json`）

**检查点**：
- [ ] 数值配置在 JSON 文件中，不是硬编码
- [ ] JSON 键名符合 snake_case 规范
- [ ] JSON 文件通过 `ConfigManager` 加载，不直接 `load()`
- [ ] 代码中引用的 JSON 键名与文件中的键名完全一致

**正确示例**：
```gdscript
var weapon_config = ConfigManager.get_weapon_stats("pistol")
var damage = weapon_config["damage"]  # 使用 JSON 中的值
```

**错误示例**：
```gdscript
const PISTOL_DAMAGE = 10  # 硬编码数值
var damage = PISTOL_DAMAGE
```

### 7.2 配置加载规范

```gdscript
# 正确：通过 ConfigManager 加载
var config = ConfigManager.get_weapon_stats(weapon_id)

# 错误：直接加载 JSON
var config = JSON.parse_string(FileAccess.get_file_as_string("res://..."))
```

---

## 8. 数值策划一致性检查

### 8.1 武器数值（策划案标准）

| 武器 | 伤害 | 弹夹 | 换弹时间 | 特殊 |
|:-----|:-----|:-----|:---------|:-----|
| 手枪 | 10 | 6 | 1.5s | 精准单点 |
| 冲锋枪 | 8 | 20 | 1.5s | 连发高射速 |
| 霰弹枪 | 5×5 | 6 | 2.0s | 45度散射 |
| 狙击枪 | 40 | 4 | 1.8s | 1秒间隔、瞄准线 |

### 8.2 敌人数值（策划案标准）

| 敌人 | 血量 | 伤害 | 特殊 |
|:-----|:-----|:-----|:-----|
| 弹幕无人机 | 20 | 5/4s | 无护盾 |
| 治疗无人机 | 15 | 0 | 治疗3%/s |
| 激光无人机 | 40 | 8 | 0.8s预警 |
| 对冲摩托车 | 80 | 15 | 3发弹幕 |

### 8.3 技能数值（策划案标准）

| 技能 | 能量消耗 | 冷却 |
|:-----|:---------|:-----|
| 耐力恢复 | 20 | — |
| 能量护盾 | 25 | — |
| 电子干扰 | 20 | — |
| 维修无人机 | 25 | — |
| 攻击无人机 | 35 | — |

### 8.4 其他关键数值

| 项目 | 数值 |
|:-----|:-----|
| 抛锚修车倒计时 | 10秒 |
| 理想修车时间 | 5秒 |
| 修车恢复血量 | 30% |
| 护盾恢复冷却 | 2秒 |
| 里世界预警时间 | 2秒 |
| 霰弹枪散射角度 | 45度 |

**检查点**：
- [ ] 代码中的数值与策划案一致
- [ ] JSON 配置中的数值与策划案一致
- [ ] 不同文件中同一数值保持一致

---

## 9. 边界条件与异常处理检查

### 9.1 必须处理的边界条件

| 场景 | 预期行为 | 检查点 |
|:-----|:---------|:-------|
| 弹药打空时射击 | 提示"弹药不足"或自动换弹 | [ ] 处理了 `ammo <= 0` 的情况 |
| 能量不足时使用技能 | 技能不触发，提示"能量不足" | [ ] 检查了 `energy >= cost` |
| 耐力耗尽时冲刺 | 冲刺不触发 | [ ] 检查了 `stamina > 0` |
| 血量临界值 | 边界值（0、最大值）正确处理 | [ ] 检查了 `health <= 0` 和 `health >= max_health` |
| 数组/字典访问 | 检查索引/键存在 | [ ] 有边界检查或 `has()` 检查 |
| 空值处理 | 使用前检查是否为 null | [ ] 有 null 检查 |
| 除零检查 | 除法运算前检查分母 | [ ] 有 `divisor != 0` 检查 |

### 9.2 异常返回值检查

```gdscript
# 函数应明确返回成功/失败
func deduct_coins(amount: int) -> bool:
    if coins < amount:
        return false  # 明确返回失败
    coins -= amount
    return true

func consume_energy(amount: float) -> bool:
    if energy < amount:
        return false
    energy -= amount
    return true
```

**检查点**：
- [ ] 条件不满足时返回 false 而非静默失败
- [ ] 调用方检查了返回值

---

## 10. 信号链路验证

### 10.1 核心信号链路

**敌人被击杀 → 完整链路**：
```
BulletPlayer 命中
    ↓
DamageSystem.apply_damage()
    ↓
EnemyBase.take_damage() → 血量归零
    ↓
DropSystem 生成掉落
    ↓
EventBus.enemy_killed.emit()
    ↓
→ EconomySystem.add_coins()
→ HUD 显示击杀
→ ProgressionSystem.add_proficiency()
```

**检查点**：
- [ ] 链路每个节点都正确发射/监听信号
- [ ] 信号的参数正确传递
- [ ] 链路无断点

### 10.2 机车受伤 → 完整链路**：
```
弹幕/障碍 命中机车
    ↓
DamageSystem.apply_damage()
    ↓
VehicleController 扣血
    ↓
EventBus.vehicle_damaged.emit()
    ↓
→ DriverHUD 更新血量
→ ChaseSystem 记录距离
    ↓
血量归零 → BreakdownRecovery 触发
```

### 10.3 里世界切换 → 完整链路**：
```
定时器触发 / 精英击杀 / BOSS阶段
    ↓
WorldStateSystem.trigger_world_swap()
    ↓
→ WorldStateSystem.invert_shield_states()
→ WorldStateSystem.swap_player_roles()
    ↓
EventBus.world_state_changed.emit()
    ↓
→ LevelManager 切换背景
→ AudioManager 切换环境音
→ WorldStateIndicator 更新
```

**检查点**：
- [ ] 每个信号的发射者正确
- [ ] 每个信号的监听者正确
- [ ] 信号参数类型和数量匹配

---

## 11. 性能与优化检查

### 11.1 对象池使用检查

**必须使用 ObjectPool 的对象**：
- 子弹（BulletPlayer、BulletEnemy）
- 敌人（所有 EnemyBase 子类）
- 粒子特效
- 掉落物（Coin、EnergyOrb）

**检查点**：
- [ ] 子弹创建使用 `ObjectPool.get_object()`
- [ ] 子弹销毁使用 `ObjectPool.return_object()`
- [ ] 敌人创建/销毁同理
- [ ] 禁止在 `_process()` 或 `_physics_process()` 中 `instance()`

**正确示例**：
```gdscript
var bullet = ObjectPool.get_object("player_bullet", "res://...")
bullet.global_position = position
bullet.direction = direction
bullet.visible = true
```

**错误示例**：
```gdscript
var bullet = preload("res://...").instantiate()  # 禁止
```

### 11.2 硬编码检查

**禁止硬编码的项目**：
- 武器伤害值
- 敌人血量
- 能量消耗
- 冷却时间
- 文件路径（应使用常量或 `res://`）

### 11.3 调试代码检查

**检查点**：
- [ ] 无 `print()` 残留（调试后可保留少量关键日志）
- [ ] 无 `push_warning`/`push_error` 用于非错误情况
- [ ] 无注释掉的调试代码

---

## 12. 文档与注释检查

### 12.1 必要注释

| 位置 | 要求 |
|:-----|:-----|
| 文件头部 | 必须有模块说明文档 |
| 公开接口 | 必须有参数和返回值说明 |
| 复杂逻辑 | 关键步骤必须注释 |
| 信号使用 | 连接处必须注释说明用途 |
| 魔法数字 | 含义不明确的数字必须注释 |

### 12.2 注释质量标准

**好的注释**：
```gdscript
# 霰弹枪扇形散射：45度范围均匀分布5发
for i in range(5):
    var angle = base_angle + (i - 2) * (45.0 / 4.0) * deg_to_rad
```

**不好的注释**：
```gdscript
# 循环
for i in range(5):
    var angle = base_angle + (i - 2) * (45.0 / 4.0) * deg_to_rad
```

---

## 13. Git 规范检查

### 13.1 分支命名

| 分支类型 | 命名格式 | 示例 |
|:---------|:---------|:-----|
| 功能分支 | `feature/[模块名]-[成员]` | `feature/weapon-system-池言いく` |
| Bug修复 | `fix/[问题描述]` | `fix/ammo-display-bug` |
| 美术资源 | `art/[资源类型]` | `art/character-sprites` |

### 13.2 Commit 消息格式

```
[模块] 简短描述（不超过50字）

详细说明（可选，超过10字）

Co-Authored-By: 成员名 <邮箱>
```

**检查点**：
- [ ] 使用 `[模块]` 前缀
- [ ] 描述不超过50字
- [ ] 有详细的变更说明
- [ ] 有 Co-Authored-By

### 13.3 PR 描述检查

PR 必须包含：
- [ ] 实现了什么（功能点清单）
- [ ] 涉及的文件列表
- [ ] 对接检查清单确认
- [ ] 需要其他成员确认的对接点

---

## 14. 按模块类型的审查重点

### 14.1 实体模块（Enemy/Player/Vehicle）

**重点检查**：
- [ ] `take_damage()` 正确调用 `DamageSystem`
- [ ] 死亡时发射 `enemy_killed` 信号
- [ ] 无敌状态通过 `DamageSystem` 管理
- [ ] 正确使用对象池

### 14.2 系统模块（System层）

**重点检查**：
- [ ] 不直接访问 Entity 层
- [ ] 通过 EventBus 与其他模块通信
- [ ] 配置数据来自 JSON

### 14.3 UI 模块

**重点检查**：
- [ ] 不直接访问 System/Entity 层
- [ ] 通过 EventBus 监听状态变化
- [ ] HUD 数据显示与底层数据一致

### 14.4 子弹模块

**重点检查**：
- [ ] 碰撞检测使用正确的 layer/mask
- [ ] 伤害计算通过 `DamageSystem`
- [ ] 使用对象池管理生命周期

---

## 15. 审查结论标准

### 15.1 通过标准（PR 可合并）

所有检查项必须通过：

| 类别 | 必须通过项 |
|:-----|:----------|
| 基础 | 文件路径正确、不修改禁止文件、Commit规范 |
| 质量 | 命名规范、脚本头部文档 |
| 架构 | 无跨层访问、无禁止依赖 |
| 通信 | 跨模块通信使用EventBus |
| 接口 | 定义与实现一致 |
| 配置 | JSON配置、非硬编码 |
| 数值 | 与策划案一致 |
| 边界 | 异常处理完整 |
| 信号 | 链路完整 |
| 性能 | 正确使用对象池 |
| 文档 | 注释完整清晰 |

### 15.2 条件通过（需标注）

以下情况可条件通过，但必须在 PR 描述中说明：

| 情况 | 要求 |
|:-----|:-----|
| 临时 hack | PR 中说明原因，标注 TODO 后续重构 |
| 依赖未完成模块 | 说明依赖关系，承诺后续对接 |
| 性能待优化 | 标注性能问题，承诺后续优化 |

### 15.3 不通过标准（PR 需修改）

| 问题 | 处理 |
|:-----|:-----|
| 架构违规（跨层访问） | 必须修复 |
| 未使用 EventBus | 必须修复 |
| 硬编码关键数值 | 必须修复 |
| 接口定义缺失 | 必须修复 |
| 信号链路断裂 | 必须修复 |
| 修改禁止文件 | 撤销修改 |
| Commit 格式错误 | 重新提交 |

### 15.4 审查意见模板

```
## PR 审查意见

**PR**: [标题]
**作者**: [成员]
**模块**: [涉及模块]

### 审查结果
- [ ] 通过
- [ ] 条件通过（需说明）
- [ ] 不通过

### 问题列表

#### 必须修复
1. [问题描述]
   - 位置：[文件:行号]
   - 原因：[为什么需要修复]
   - 建议：[如何修复]

2. ...

#### 建议优化
1. [建议描述]

### 确认项
- [ ] 代码规范
- [ ] 架构层级
- [ ] 接口一致性
- [ ] 配置规范
- [ ] 数值正确
- [ ] 信号链路
- [ ] 性能优化

### 最终意见
[通过/需要修改/需要重新提交]
```

---

## 附录 A：快速检查清单

### A.1 5分钟快速审查

```
□ 文件在正确目录？
□ 无禁止修改的文件被修改？
□ Commit 格式正确？
□ 命名符合规范？
□ 脚本头部有文档？
□ 无跨层访问？
□ 使用 EventBus 通信？
□ 数值来自 JSON？
□ 数值与策划案一致？
□ 使用对象池？
□ 无硬编码？
□ 无调试代码残留？
□ 接口定义与实现一致？
□ 异常处理完整？
□ 信号链路正确？
```

### A.2 详细审查清单

参见正文各章节完整检查项。

---

## 附录 B：常见违规代码示例

### B.1 跨层访问

```gdscript
# 错误 - System 访问 Entity
class_name SpawnSystem
func spawn_enemy():
    var driver = get_node("/root/Driver")  # 禁止
    driver.some_method()

# 正确 - 通过信号
EventBus.enemy_spawned.emit(enemy_type)
```

### B.2 直接引用

```gdscript
# 错误 - 直接获取引用
var enemy = get_node("/root/SomeEnemy")
enemy.take_damage(10)

# 正确 - 通过 EventBus
EventBus.bullet_hit.emit(target, bullet, damage)
```

### B.3 硬编码

```gdscript
# 错误 - 硬编码数值
var damage = 10

# 正确 - 从配置读取
var config = ConfigManager.get_weapon_stats(weapon_id)
var damage = config["damage"]
```

---

## 附录 C：后期合并风险与应对

> 以下内容是防止"审完PR后期合并不了"的关键风险点。

### C.1 场景文件(.tscn)冲突风险

**风险描述**：多人同时修改同一个 `.tscn` 文件，会导致 Git 合并冲突，且冲突难以解决。

**高危文件**：
- `Main.tscn` - 主场景，几乎所有人都会改
- `Level01.tscn`、`Level02.tscn`、`Level03.tscn` - 关卡场景
- `DriverHUD.tscn`、`ShooterHUD.tscn` - HUD场景

**应对策略**：
1. **约定节点分支归属**：
   | 场景文件 | 负责修改的成员 |
   |:---------|:--------------|
   | `Main.tscn` | 新街（场景总框架） |
   | `Level*.tscn` | 新街（关卡结构） |
   | `DriverHUD.tscn` | cjs（驾驶员HUD） |
   | `ShooterHUD.tscn` | cjs（射击手HUD） |
   | `Motorcycle.tscn` | 池言いく（载具） |
   | `Drone*.tscn` | 长安旧梦（敌人） |

2. **审查时检查**：PR 修改的 `.tscn` 是否超出成员职责范围
3. **合入顺序**：按依赖关系排序，先合底层后合上层

### C.2 接口变更连锁风险

**风险描述**：A 模块改了接口，但依赖 A 的 B/C 模块不知道，导致合入后其他模块报错。

**典型场景**：
- `EventBus` 新增信号 → 监听方可能漏掉
- 接口参数变更 → 调用方忘记更新
- JSON 配置键名变更 → 读取方报错

**应对策略**：
1. **PR 描述必须包含**：
   ```
   ## 接口变更说明
   - 新增接口：[接口名]
   - 变更接口：[旧接口] → [新接口]
   - 影响模块：[依赖此接口的模块]
   ```
2. **Review 时检查**：接口变更是否通知了相关模块负责人
3. **强制要求**：接口变更必须附带受影响模块的同步修改

### C.3 循环依赖风险

**风险描述**：A 依赖 B，B 依赖 C，C 又依赖 A，形成死锁。

**Godot 中的典型情况**：
```
scripts/systems/level/SpawnSystem.gd  →  依赖  →  scripts/entities/enemy/EnemyBase.gd
scripts/entities/enemy/EnemyBase.gd  →  依赖  →  scripts/systems/world/WorldStateSystem.gd
scripts/systems/world/WorldStateSystem.gd  →  依赖  →  scripts/systems/level/SpawnSystem.gd
```

**应对策略**：
1. **审查时检查**：查看文件的 `extends` 和 `import`
2. **依赖方向必须单向**：System → Entity 是单向的
3. **使用 EventBus 解耦**：避免直接依赖

### C.4 配置文件格式风险

**风险描述**：JSON 配置格式错误（逗号、括号不匹配）导致游戏崩溃。

**应对策略**：
1. **审查时检查**：
   - JSON 文件是否可被正确解析
   - 键名是否使用 snake_case
   - 数值类型是否正确（int vs float）
2. **提交前验证**：要求成员在 PR 中注明"已用 Godot 加载测试"

### C.5 资源路径风险

**风险描述**：
- 资源路径硬编码写成绝对路径（如 `E:/...`）
- 资源已删除但代码还在引用
- 资源路径大小写不匹配（Linux 敏感）

**应对策略**：
1. **审查时检查**：
   - 路径是否以 `res://` 开头
   - 路径是否使用 snake_case
2. **规范路径格式**：
   ```gdscript
   # 正确
   var path = "res://assets/art/characters/player.png"
   
   # 错误
   var path = "E:/项目/assets/.../"  # 绝对路径禁止
   var path = "res://Assets/Art/..."  # 大写禁止
   ```

### C.6 .tscn 文件格式风险

**风险描述**：
- .tscn 文件格式错误，Godot 无法打开
- 节点路径引用错误（节点被删除但代码还在引用）
- 节点类型拼写错误

**应对策略**：
1. **提交前测试**：必须用 Godot 打开场景文件验证
2. **审查时检查**：
   - 文件头 `[gd_scene load_steps=...]` 是否存在
   - 节点 `[node name="xxx" type="xxx"]` 格式是否正确
   - 引用路径 `ext_resource` 是否正确

### C.7 合入顺序风险

**风险描述**：两个 PR 同时合入，一个依赖另一个，但合入顺序错误导致报错。

**典型依赖关系**：
```
DamageSystem.gd  ←  被几乎所有战斗相关模块依赖
    ↓
EnemyBase.gd  ←  依赖 DamageSystem
    ↓
SpawnSystem.gd  ←  依赖 EnemyBase
    ↓
LevelManager.gd  ←  依赖 SpawnSystem
```

**应对策略**：
1. **PR 合入前确认**：依赖关系图，决定合入顺序
2. **强制顺序**：底层模块必须先于上层模块合入
3. **PR 标注依赖**：
   ```
   ## 合入顺序要求
   - 本 PR 依赖：[PR #xxx] 已合入
   - 本 PR 被以下 PR 依赖：[PR #yyy]
   ```

---

## 附录 D：合入前最终检查清单

> 在确认合并前，必须完成以下检查。

### D.1 代码检查

- [ ] 所有检查项通过 PR_REVIEW_STANDARDS.md
- [ ] 接口变更已通知相关模块负责人
- [ ] 依赖的 PR 已先合入

### D.2 场景文件检查

- [ ] 修改的 .tscn 文件可被 Godot 正常打开
- [ ] 节点路径引用正确
- [ ] 无格式错误

### D.3 配置检查

- [ ] JSON 文件格式正确，可解析
- [ ] 资源路径使用 res:// 格式
- [ ] 数值与策划案一致

### D.4 测试检查

- [ ] 已在 Godot 中运行测试
- [ ] 无崩溃、无 Error 输出
- [ ] 功能符合预期

---

*文档版本：1.1（新增风险应对章节）*
*最后更新：2026-04-30*
*维护者：管理员*
