# MADMEN — Day 1-3 合并版

> 本项目由 **新街、池言いく、长安旧梦、cjs** 四人团队协作开发，整合自各成员 Day 1-3 的工作成果。

---

## 项目信息

| 项目 | 内容 |
|:-----|:-----|
| **游戏名称** | MADMEN |
| **游戏类型** | 第三人称追尾视角双人合作弹幕射击游戏 |
| **引擎** | Godot 4.x (GDScript) |
| **目标平台** | PC (Steam) |
| **支持模式** | 本地双人分屏 |

---

## 团队成员

| 成员 | 职责 |
|:-----|:-----|
| **新街** | 场景框架 / 路段机制 / 特殊路段 / 商店系统 / GameManager / LevelManager |
| **池言いく** | 玩家系统 / 武器系统 / 机车物理 / 输入系统 / 追兵系统 / 抛锚修车 |
| **长安旧梦** | 敌人系统 / BOSS系统 / AI行为 / 弹幕生成 / 里世界切换 / DamageSystem |
| **cjs** | UI系统 / 经济系统 / 音频管理 / 配置管理 / HUD / EventBus |

---

## 目录结构

```
MADMENX_src/
├── project.godot              # Godot项目配置
├── README.md                  # 本文件
│
├── assets/
│   └── configs/               # JSON配置文件
│       ├── enemy_stats.json   # 敌人属性配置
│       ├── game_config.json  # 游戏通用配置
│       ├── level_config.json # 关卡配置
│       ├── shop_items.json   # 商店商品配置
│       └── weapon_stats.json # 武器属性配置
│
├── scenes/
│   ├── main/
│   │   ├── Main.tscn         # 游戏主入口
│   │   └── Autoloads.tscn    # 单例场景
│   ├── levels/
│   │   ├── Level01.tscn
│   │   ├── Level02.tscn
│   │   └── Level03.tscn
│   ├── entities/
│   │   ├── bullets/
│   │   │   ├── BulletEnemy.tscn
│   │   │   └── BulletPlayer.tscn
│   │   ├── enemies/
│   │   │   ├── DroneBasic.tscn
│   │   │   ├── DroneHealer.tscn
│   │   │   ├── DroneLaser.tscn
│   │   │   ├── EnemyBike.tscn
│   │   │   └── bosses/
│   │   │       └── Boss01.tscn
│   │   ├── obstacles/
│   │   │   ├── ObstacleBarrier.tscn  # 路障
│   │   │   ├── ObstacleLarge.tscn    # 大型障碍物
│   │   │   └── ObstaclePothole.tscn  # 坑洞
│   │   ├── pickups/
│   │   │   └── Coin.tscn
│   │   └── vehicles/
│   │       └── Motorcycle.tscn
│   └── ui/
│       ├── hud/
│       │   └── HUDController.tscn  # HUD总控制器（含 DriverHUD / ShooterHUD 内嵌）
│       └── shop/
│           └── ShopUI.tscn
│
├── scripts/
│   ├── autoload/             # 单例层（最高层）
│   │   ├── AudioManager.gd   # 音频管理器
│   │   ├── ConfigManager.gd   # 配置管理器
│   │   ├── EventBus.gd       # 全局事件总线
│   │   ├── GameManager.gd    # 游戏总管理器
│   │   ├── InputManager.gd   # 输入管理器
│   │   ├── SaveManager.gd    # 存档管理器
│   │   └── WorldStateManager.gd # 里世界状态管理
│   │
│   ├── core/                  # 核心系统
│   │   ├── DamageSystem.gd   # 伤害计算系统
│   │   ├── EventBusHelper.gd # 事件总线辅助
│   │   ├── ObjectPool.gd     # 对象池管理器
│   │   └── StateMachine.gd    # 状态机基类
│   │
│   ├── entities/              # 实体脚本
│   │   ├── base/
│   │   │   ├── Damager.gd        # 可造成伤害实体
│   │   │   ├── Entity.gd         # 实体基类
│   │   │   ├── LivingEntity.gd   # 可存活实体
│   │   │   └── Pickupable.gd     # 可拾取实体
│   │   ├── bullet/
│   │   │   ├── BulletBase.gd      # 子弹基类
│   │   │   ├── BulletEnemy.gd     # 敌人弹幕
│   │   │   ├── BulletFactory.gd   # 子弹工厂
│   │   │   └── BulletPlayer.gd    # 玩家子弹
│   │   ├── enemy/
│   │   │   ├── BossBase.gd        # BOSS基类
│   │   │   ├── DroneBasic.gd      # 弹幕无人机
│   │   │   ├── DroneHealer.gd     # 治疗无人机
│   │   │   ├── DroneLaser.gd      # 激光无人机
│   │   │   ├── EnemyBase.gd       # 敌人基类
│   │   │   └── EnemyBike.gd       # 对冲摩托车
│   │   ├── pickups/
│   │   │   ├── Coin.gd            # 金币
│   │   │   ├── EnergyOrb.gd      # 能量球
│   │   │   └── ItemDrop.gd        # 物品掉落
│   │   ├── player/
│   │   │   ├── Driver.gd         # 驾驶员
│   │   │   ├── PlayerBase.gd     # 玩家基类
│   │   │   ├── Shooter.gd        # 射击手
│   │   │   └── WeaponBase.gd     # 武器基类
│   │   └── vehicle/
│   │       ├── Motorcycle.gd       # 摩托车
│   │       ├── VehicleController.gd # 载具控制器
│   │       └── VehicleSkills.gd    # 载具技能系统
│   │
│   ├── systems/               # 游戏系统
│   │   ├── chase/
│   │   │   ├── BreakdownRecovery.gd # 抛锚修复系统
│   │   │   └── ChaseSystem.gd      # 追兵系统
│   │   ├── combat/
│   │   │   └── CombatSystem.gd      # 战斗系统
│   │   ├── economy/
│   │   │   ├── EconomySystem.gd    # 经济系统
│   │   │   └── ShopSystem.gd       # 商店系统
│   │   ├── level/
│   │   │   ├── LevelManager.gd      # 关卡管理器
│   │   │   ├── RestPointManager.gd  # 躲藏点管理
│   │   │   ├── RoadObstacle.gd      # 路面障碍
│   │   │   ├── SegmentGenerator.gd   # 路段生成器
│   │   │   └── SpawnSystem.gd       # 敌人生成系统
│   │   ├── special/
│   │   │   └── SpecialSegmentManager.gd # 特殊路段管理
│   │   └── world/
│   │       └── WorldStateSystem.gd   # 里世界切换系统
│   │
│   ├── ui/                   # UI脚本
│   │   ├── DriverHUD.gd        # 驾驶员HUD
│   │   ├── ShooterHUD.gd      # 射击手HUD
│   │   ├── HUDController.gd   # HUD总控制器
│   │   ├── MenuController.gd   # 菜单控制器
│   │   ├── ShopUI.gd          # 商店界面
│   │   ├── UISignalDebugger.gd   # UI信号调试工具（cjs）
│   │   ├── UIIntegrationTest.gd  # UI集成测试（cjs）
│   │   └── UIComponents/
│   │       ├── AmmoDisplay.gd     # 弹药显示
│   │       ├── HealthBar.gd        # 血条组件
│   │       ├── InventorySlot.gd    # 背包格子
│   │       ├── SkillCooldown.gd    # 技能冷却
│   │       └── WorldStateIndicator.gd # 里世界状态指示
│   │
│   └── utils/                # 工具类（预留）
│
└── tests/                    # 单元测试
    ├── test_damage_system.gd
    ├── test_economy_system.gd
    └── test_weapon_system.gd
```

---

## 合并说明

本版本整合了四名成员的 Day 1-3 工作成果，采用以下合并策略：

1. **相同文件以功能完整度最高者为准**（代码量、功能、注释完整）
2. **同名不同内容的文件保留最佳实现**
3. **chiyan 的独特文件**（obstacle_*.gd、shooting_system.gd、vehicle_hud.gd、breakdown_recovery.gd）已整合
4. **障碍物系统**（ObstacleBarrier、ObstacleLarge、ObstaclePothole）已包含在 `scenes/entities/obstacles/`
5. **DriverHUD / ShooterHUD** 已内嵌于 `HUDController.tscn`，无需独立场景文件
6. **CJS/长安旧梦 的调试工具**（UISignalDebugger.gd、UIIntegrationTest.gd）已包含
7. **所有 JSON 配置文件已合并**（weapon_stats、enemy_stats、game_config、level_config、shop_items）

---

## 目录结构说明

- `scenes/entities/obstacles/` — 路面障碍物场景（路障、大型障碍物、坑洞）
- `UISignalDebugger.gd` — UI 信号调试工具（仅开发时使用）
- `UIIntegrationTest.gd` — UI 集成测试脚本（仅开发时使用）

---

## 开发规范

详见 `car_booom_src_新街/开发规范/DEVELOPMENT_STANDARDS.md`

---

*合并版本：Day 1-3*
*最后更新：2026-05-02*
