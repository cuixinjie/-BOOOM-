# MADMEN — 开发规范总纲

> 本文档是所有开发成员的通用准则，每位程序成员还需阅读各自对应的**职责边界文档**。

---

## 1. 引擎与语言

| 项目 | 版本/规范 |
|:-----|:---------|
| 引擎 | Godot 4.x |
| 主语言 | GDScript（优先）/ C#（视性能需求） |
| 场景格式 | `.tscn`（文本格式，纳入版本控制） |

---

## 2. 目录结构

```
MADMEN/
├── project.godot
├── assets/
│   ├── art/           # 美术资源（按子目录分类，见美术规范）
│   ├── audio/
│   │   ├── sfx/
│   │   └── bgm/
│   ├── fonts/
│   └── configs/       # JSON配置（武器/敌人/关卡）
├── scenes/            # 场景文件（.tscn）
│   ├── main/
│   ├── levels/
│   ├── entities/
│   ├── ui/
│   └── environment/
├── scripts/           # 脚本文件
│   ├── autoload/       # 单例（最高层）
│   ├── core/          # 核心系统
│   ├── entities/      # 实体脚本
│   ├── systems/       # 游戏系统
│   ├── ui/           # UI脚本
│   └── utils/         # 工具类
└── tests/            # 单元测试
```

---

## 3. 架构层次与依赖规则

```
┌──────────────────────────────────────────┐
│           Autoload（单例层）               │  可访问：Autoload, Core
│   GameManager / AudioManager / InputManager│  禁止访问：Systems, Entities, UI
├──────────────────────────────────────────┤
│           Core（核心层）                   │  可访问：Autoload, Core
│   StateMachine / ObjectPool / DamageSystem│  禁止访问：Systems, Entities, UI
├──────────────────────────────────────────┤
│           Systems（系统层）                │  可访问：Autoload, Core, Systems
│   Combat / Level / Economy / World / ...  │  禁止访问：Entities, UI
├──────────────────────────────────────────┤
│           Entities（实体层）               │  可访问：Autoload, Core
│   Player / Vehicle / Enemy / Bullet       │  禁止访问：Systems, UI
├──────────────────────────────────────────┤
│           UI（界面层）                     │  可访问：Autoload, Core
│   HUD / Shop / Menus                      │  禁止访问：Systems, Entities
└──────────────────────────────────────────┘
```

**依赖方向必须严格遵守**：下层不得引用上层，同层可相互访问但应尽量通过 EventBus 解耦。

---

## 4. 命名规范

| 类型 | 规范 | 示例 |
|:-----|:-----|:-----|
| 类名 | PascalCase | `VehicleController` |
| 变量/函数 | snake_case | `current_health` |
| 常量 | SCREAMING_SNAKE | `MAX_SPEED` |
| 信号 | snake_case | `enemy_killed` |
| 枚举类型 | PascalCase | `WorldState` |
| 枚举值 | SCREAMING_SNAKE | `WORLD_NORMAL` |
| 文件名 | 与类名一致，`.gd` 扩展名 | `VehicleController.gd` |
| 场景节点名 | snake_case，末尾带类型缩写 | `player_motorcycle`、`enemy_drone_basic` |
| 资源配置键 | snake_case | `enemy_stats.json` 内键名 |
| Autoload 节点名 | PascalCase，英文 | `GameManager`（而非 `游戏管理器`） |

---

## 5. 脚本头部模板

每个脚本顶部必须包含以下格式的注释块：

```gdscript
## [模块名称] — [一句话描述]
##
## 功能说明：
## - [功能点1]
## - [功能点2]
##
## 对接注意事项：
## - [本模块被哪些模块依赖 / 本模块依赖哪些模块]
## - [与其他成员模块对接时需确认的接口]
##
## 创建人：[姓名]
## 创建日期：[YYYY-MM-DD]

class_name [ClassName]
extends [ParentClass]
## ... 实现代码 ...
```

---

## 6. EventBus 信号规范

所有跨模块通信必须通过 `EventBus` 信号，禁止直接 `get_node()` 获取其他模块的引用。

```gdscript
# 定义位置：scripts/autoload/EventBus.gd
class_name EventBus
extends Node

# === 战斗信号 ===
signal enemy_killed(enemy: Node, killer: Node)
signal bullet_hit(target: Node, bullet: Node, damage: float)
signal player_damaged(player: Node, damage: float)
signal vehicle_damaged(damage: float)
signal vehicle_repaired(amount: float)

# === 游戏状态信号 ===
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(victory: bool)
signal segment_completed(segment_id: int)
signal rest_point_entered()
signal boss_spawned(boss: Node)
signal boss_phase_changed(phase: int)

# === 里世界信号 ===
signal world_state_changed(from_state: int, to_state: int)
signal role_swap_triggered(driver_id: int, shooter_id: int)
signal shield_state_inverted()

# === 经济信号 ===
signal coin_collected(amount: int)
signal energy_collected(amount: int)
signal proficiency_gained(amount: float)
signal level_up(new_level: int)
signal shop_purchased(item_id: String, cost: int)

# === 追兵信号 ===
signal chase_distance_changed(distance: float)
signal vehicle_breakdown()
signal repair_started()
signal repair_progress_changed(progress: float)
signal repair_completed()
signal repair_failed()
signal chase_caught()

# === 玩家输入信号 ===
signal driver_input_changed(input_data: Dictionary)
signal shooter_input_changed(input_data: Dictionary)
signal weapon_fired(weapon_id: String)
signal weapon_reloaded(weapon_id: String)
signal ammo_type_changed(ammo_type: String)

# === 特殊路段信号 ===
signal special_segment_started(segment_type: String)
signal special_segment_completed(segment_type: String)
signal special_segment_failed(segment_type: String)
```

**使用方式**：

```gdscript
# 监听信号
EventBus.enemy_killed.connect(_on_enemy_killed)
EventBus.vehicle_damaged.connect(_on_vehicle_damaged)

# 发射信号（优先使用具名参数避免传错）
EventBus.enemy_killed.emit(enemy, killer)
EventBus.vehicle_damaged.emit(5.0)

# 禁止这样做：
# var enemy = get_node("/root/SomeEnemy")  # 直接获取其他模块引用
```

---

## 7. 接口定义规范

每个模块对外提供的接口必须在脚本头部明确注明。以下是标准接口文档格式：

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
##
## get_energy() -> float
##   返回当前能量值
##
## consume_energy(amount: float) -> bool
##   消耗能量，成功返回 true，能量不足返回 false
## ===== 接口结束 =====
```

---

## 8. JSON 配置规范

所有可配置数据（武器属性、敌人属性、关卡配置）必须放在 `assets/configs/` 目录下的 JSON 文件中，**禁止在代码中硬编码数值**。

```json
{
  "pistol": {
    "name": "手枪",
    "damage": 10,
    "fire_rate": 2.5,
    "magazine_size": 6,
    "reload_time": 1.5,
    "spread": 0.05,
    "bullet_speed": 800
  }
}
```

配置加载统一通过 `ConfigManager` 单例：

```gdscript
var weapon_stats = ConfigManager.get_weapon_stats("pistol")
var damage = weapon_stats["damage"]
```

---

## 9. 对象池规范

所有高频创建销毁的对象（子弹、敌人、粒子）必须使用 `ObjectPool` 管理。

```gdscript
# 获取对象
var bullet = ObjectPool.get_object("player_bullet", "res://scenes/entities/bullets/BulletPlayer.tscn")

# 归还对象
ObjectPool.return_object("player_bullet", bullet)
```

**禁止**在高频逻辑中直接 `instance()` 新建对象。

---

## 10. 场景节点规范

- 每个 `.tscn` 文件中的根节点必须设置 `unique_name_in_owner = false` 或明确的节点路径
- 所有需要代码访问的子节点必须命名（snake_case）
- 使用 `@export` 暴露到编辑器时，变量名与节点名保持一致
- 分屏视角中 P1/P2 的节点需要有明确的前缀：`p1_` / `p2_`

---

## 11. Git 分支策略

| 分支 | 用途 |
|:-----|:-----|
| `main` | 稳定版本，仅通过 PR 合并 |
| `dev` | 开发主分支，每日合并 |
| `feature/[模块名]-[成员]` | 功能分支 |
| `fix/[问题描述]` | Bug 修复分支 |
| `art/[资源类型]` | 美术资源分支 |

**Commit 消息规范**：

```
[模块] 简短描述（不超过50字）

详细说明（可选，超过10字）

Co-Authored-By: 成员名 <邮箱>
```

示例：

```
[Level] 实现路段切换逻辑

- 添加 SegmentGenerator
- 对接 SpawnSystem
- 测试通过

Co-Authored-By: 新街 <example@email.com>
```

---

## 12. AI 辅助代码规范

本项目使用 AI 辅助生成代码，但所有 AI 生成代码必须经过 **人工 review** 后才能合入。

Review 清单：

- [ ] 代码符合本规范中的命名和格式要求
- [ ] 没有访问禁止访问的层级（如 Entity 访问了 System）
- [ ] 跨模块通信使用 EventBus，而非直接引用
- [ ] 配置数据来自 JSON，而非硬编码
- [ ] 高频对象使用 ObjectPool
- [ ] 脚本头部包含完整的文档注释
- [ ] 无明显的逻辑错误或边界条件遗漏

---

## 13. 对接检查清单

每次模块合入前，开发者必须确认：

**接口对接**：
- [ ] 本模块发出的所有信号在其他模块中正确监听
- [ ] 本模块监听的信号在其他模块中正确发射
- [ ] JSON 配置文件键名与代码中引用的键名一致
- [ ] Autoload 节点名与代码中引用的名称一致

**功能边界**：
- [ ] 本模块只修改/依赖自己负责的脚本文件
- [ ] 不修改其他成员的代码（除非获得授权）
- [ ] 不在 shared 目录（`core/`、`utils/`）中放入业务逻辑

**资源对接（程序 ↔ 美术）**：
- [ ] 美术资源路径与代码中引用的路径一致
- [ ] 动画名称与代码中引用的名称一致
- [ ] Sprite 帧数与动画器状态匹配
- [ ] 音效文件名与 AudioManager 引用的名称一致

---

## 14. 白盒先行策略

- **阶段 1（Day 1–3）**：所有视觉资源使用白盒占位（简单几何体、色块）
- **阶段 2（Day 4–9）**：美术正式资源分批交付，程序按约定路径替换
- **美术资源路径约定**：
  - 角色：`res://assets/art/characters/`
  - 敌人：`res://assets/art/enemies/`
  - 场景：`res://assets/art/environment/`
  - 特效：`res://assets/art/effects/`
  - UI：`res://assets/art/ui/`
  - 子弹视觉：`res://assets/art/bullets/`
- 美术资源命名：**snake_case**，与程序命名规范对齐

---

## 15. 调试与日志规范

```gdscript
# 使用 print 进行简单调试，发布版本前删除
print("[WeaponSystem] Fire called: ", weapon_id)

# 重要事件使用 push_warning 或 push_error
push_warning("[SpawnSystem] Unexpected enemy type: ", enemy_type)
push_error("[DamageSystem] Damage calculation overflow")

# 禁止在性能敏感代码（_process, _physics_process）中添加 print
```

---

*文档版本：1.0*
*最后更新：2026-04-28*
*主维护者：新街*
