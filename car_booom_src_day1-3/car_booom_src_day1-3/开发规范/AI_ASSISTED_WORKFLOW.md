# MADMEN — AI 辅助开发标准流程

> 本文档定义了团队使用 AI 辅助开发时的标准工作流程。
> 所有成员在开发任何模块时都必须遵循此流程。

---

## 流程总览

```
┌─────────────────────────────────────────────────────────────┐
│                    标准开发流程                               │
│                                                             │
│  ① 拉取远程分支到本地  →  ② 让 AI 阅读规范和职责边界  →        │
│                                                             │
│  ③ 在自己的分支开发  →  ④ 自检（Review 清单）  →              │
│                                                             │
│  ⑤ 推送分支  →  ⑥ 发起 PR  →  ⑦ 管理员 Review  →  ⑧ 合入    │
└─────────────────────────────────────────────────────────────┘
```

---

## 第一步：从 GitHub 拉取 feature 分支

### 1.1 确认当前分支状态

```bash
# 查看当前状态
git status

# 查看远程分支
git branch -r

# 确保本地 main 是最新的
git checkout main
git pull origin main
```

### 1.2 创建或切换到自己的 feature 分支

```bash
# 已有分支则切换
git checkout feature/模块名-你的名字

# 没有则从 main 创建新分支
git checkout -b feature/模块名-你的名字
```

### 1.3 合并远程 feature 分支内容到本地（多人协作时）

```bash
# 合并远程最新代码（如果有共享的 feature 分支）
git fetch origin
git merge origin/feature/共享分支名

# 如果有冲突，解决冲突后继续
git add .
git commit -m "merge: 解决与远程分支的冲突"
```

> **注意**：如果你是在 `feature/模块名-你的名字` 分支上开发，先 fetch 查看是否有远程更新，再决定是否 merge。

---

## 第二步：让 AI 阅读开发规范和职责边界

> **这是最关键的步骤。** 在让 AI 写任何代码之前，必须先提供规范文档。
> 不同模块的成员需要给 AI 看不同的职责边界文档。

### 2.1 所有成员必读

| 文档 | 说明 |
|:-----|:-----|
| `开发规范/DEVELOPMENT_STANDARDS.md` | 命名规范 / 架构层次 / EventBus 规范 / Git 分支策略 / Commit 规范 / AI Review 清单 |
| `开发规范/INTEGRATION_CHECKLIST.md` | 代码对接检查清单 |

### 2.2 按职责阅读对应文档

| 你的职责 | 额外必读的职责边界文档 |
|:---------|:----------------------|
| 新街（场景/关卡/商店） | `开发规范/RESPONSIBILITY_新街.md` |
| 长安旧梦（敌人/BOSS/AI） | `开发规范/RESPONSIBILITY_长安旧梦.md` |
| 池言いく（玩家/武器/物理） | `开发规范/RESPONSIBILITY_池言いく.md` |
| cjs（UI/经济/对接） | `开发规范/RESPONSIBILITY_cjs.md` |

### 2.3 给 AI 提供规范的正确方式

**推荐方式**：在开始对话时，主动把规范内容粘贴给 AI，或让 AI 先读取规范文件。

示例提示词：

```
请先阅读以下开发规范文档，了解项目标准：
- 项目根目录/开发规范/DEVELOPMENT_STANDARDS.md
- 项目根目录/开发规范/INTEGRATION_CHECKLIST.md
- 项目根目录/开发规范/RESPONSIBILITY_池言いく.md（我是池言いく）

接下来我要实现：WeaponShotgun.gd 霰弹枪，扇形散射5发，每发独立判定。
请严格按照规范中的命名（snake_case）、脚本头部模板、EventBus 信号规范来写代码。
```

**禁止**：不让 AI 看规范就开始写代码。

---

## 第三步：在自己的分支开发

### 3.1 遵循架构层次规则

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

> **下层禁止访问上层**，违反此规则会导致代码耦合，难以维护。

### 3.2 跨模块通信必须通过 EventBus

```gdscript
# 正确：通过信号通信
EventBus.enemy_killed.emit(enemy, killer)

# 禁止：直接获取其他模块引用
var enemy = get_node("/root/SomeEnemy")  # ❌
```

### 3.3 Commit 规范

```
[模块] 简短描述（不超过 50 字）

详细说明（可选，超过 10 字）

Co-Authored-By: 成员名 <邮箱>
```

示例：

```bash
git add .
git commit -m "$(cat <<'EOF'
[Weapon] 实现霰弹枪扇形散射逻辑

- 添加扇形角度计算（45度覆盖）
- 5发子弹独立碰撞判定
- 对接 BulletFactory 创建子弹

Co-Authored-By: 池言いく <example@email.com>
EOF
)"
```

### 3.4 提交前自检（对应 `DEVELOPMENT_STANDARDS.md` 第 12 节）

```
AI Review 清单 — 提交前必须检查：

- [ ] 代码符合命名和格式要求
- [ ] 没有访问禁止访问的层级（如 Entity 访问了 System）
- [ ] 跨模块通信使用 EventBus，而非直接引用
- [ ] 配置数据来自 JSON，而非硬编码
- [ ] 高频对象使用 ObjectPool
- [ ] 脚本头部包含完整的文档注释
- [ ] 无明显的逻辑错误或边界条件遗漏
```

---

## 第四步：推送分支

### 4.1 提交到本地

```bash
git add .
git commit -m "[模块] 简短描述"
```

### 4.2 推送到远程

```bash
# 首次推送（创建远程分支）
git push -u origin feature/模块名-你的名字

# 后续推送
git push
```

---

## 第五步：发起 Pull Request

### 5.1 通过 GitHub 网页创建 PR

1. 打开 GitHub 仓库页面
2. 点击 **Compare & pull request**
3. 选择目标分支：`main`
4. 填写 PR 信息（见下方模板）

### 5.2 PR 描述模板

```markdown
## 实现了什么

- [ ] 功能点 1
- [ ] 功能点 2

## 涉及的文件

- `scripts/.../xxx.gd`
- `assets/configs/xxx.json`

## 对接检查（提交前自查）

- [ ] 代码符合 DEVELOPMENT_STANDARDS.md 规范
- [ ] 遵守架构层次规则，无跨层访问
- [ ] 跨模块通信使用 EventBus
- [ ] 配置数据来自 JSON
- [ ] 脚本头部有完整文档注释
- [ ] 接口已在文档中声明

## 需要其他成员确认的对接点

- [ ] 与 [模块/成员] 的接口已确认
- [ ] 信号链路已测试
```

### 5.3 Assign 审核人

| 模块 | 审核人 |
|:-----|:-------|
| 场景/关卡/商店 | 新街 |
| 敌人/BOSS/AI | 长安旧梦 |
| 玩家/武器/物理 | 池言いく |
| UI/经济/对接 | cjs |

> **特殊情况**：如果涉及多个模块的改动，由改动最多的模块负责人主审。

---

## 第六步：管理员 Review 后合并

### 6.1 审核人检查项

对应 `开发规范/INTEGRATION_CHECKLIST.md` 第二部分：

1. **信号链路验证** — 完整事件生命周期是否打通
2. **边界条件检查** — 空弹药/能量不足/耐力耗尽等异常处理
3. **数值一致性检查** — JSON 配置值与代码引用是否一致
4. **依赖层级检查** — 是否有跨层直接引用

### 6.2 Review 通过后合并

审核人点击 **Merge pull request** → **Confirm merge**

### 6.3 Review 未通过的处理

- 审核人在 PR 下留言具体问题
- 开发者在自己的分支修复
- 推送更新后 PR 自动更新，无需重新发起 PR
- 修复后重新 Request Review

---

## 常见问题

### Q: 可以直接修改其他成员的代码吗？

**不可以**。职责边界文档中明确标注了"绝对不能修改"的文件。如有需要，必须与对应负责人协商。

### Q: 发现其他模块有 bug 应该怎么办？

在 GitHub 上开 Issue，描述问题、指明可能的原因。由该模块负责人修复。

### Q: 两个模块需要同时改怎么办？

协调好接口后各自在分支上改，通过 PR 合并顺序控制依赖关系。或者临时开一个 `feature/跨模块-名字` 分支。

### Q: AI 生成的代码可以直接提交吗？

**不可以**。所有 AI 生成代码必须经过人工 review（Review 清单检查）后才能合入。

---

## 附录 A：MCP + Godot 开发流程

> 本章节介绍如何配置 **MCP (Model Context Protocol)** + **Godot**，让 AI 能够直接与 Godot 编辑器交互，实时预览代码效果、运行游戏、调试输出。

---

### A.1 什么是 Godot MCP

MCP 是 Anthropic 推出的标准化协议，让 AI 助手（如 Cursor 中的 AI）能够与外部工具深度集成。Godot MCP 使 AI 可以直接：
- 读取和编辑项目中的 `.gd` 脚本文件
- 操作 Godot 场景（创建、修改 `.tscn` 文件）
- 启动/停止 Godot 编辑器和游戏
- 捕获实时调试输出
- 实时预览代码改动效果

---

### A.2 环境要求

| 要求 | 说明 |
|:-----|:-----|
| Node.js | 18+ 版本 |
| npm | 与 Node.js 一起安装 |
| Godot | 4.x 版本 |
| Cursor | 支持 MCP 的最新版本 |

---

### A.3 安装 Godot MCP 插件（两种方案）

#### 方案一：ee0pdt/Godot-MCP（推荐，功能完整）

**第一步：安装 MCP Server**

```bash
# 克隆仓库
git clone https://github.com/ee0pdt/Godot-MCP.git

# 进入 server 目录
cd Godot-MCP/server

# 安装依赖
npm install

# 编译 TypeScript
npm run build
```

> 编译成功后，`server/dist/index.js` 即为 MCP Server 的入口文件。

**第二步：在 Godot 项目中启用 MCP 插件**

```bash
# 将 MCP addon 复制到项目的 addons 目录
cp -r Godot-MCP/addons/godot-mcp <你的项目路径>/addons/
```

然后在 Godot 编辑器中：
1. 打开项目
2. **Project → Project Settings → Plugins**
3. 找到 `godot-mcp`，将 Status 设为 **Enabled**

**第三步：在 Cursor 中配置 MCP**

在项目根目录创建 `.cursor/mcp.json`（如果已存在则编辑）：

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["E:/开发学习文件夹/项目管理/机核BOOOM/Godot-MCP/server/dist/index.js"],
      "env": {
        "MCP_TRANSPORT": "stdio"
      }
    }
  }
}
```

> **注意**：将路径替换为你实际克隆的 `Godot-MCP/server/dist/index.js` 的绝对路径。

---

#### 方案二：bradypp/godot-mcp（轻量、零配置）

**第一步：安装 MCP Server**

```bash
git clone https://github.com/bradypp/godot-mcp.git
cd godot-mcp
npm install
npm run build
```

**第二步：配置 Cursor**

在 `.cursor/mcp.json` 中添加：

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["<你克隆的路径>/godot-mcp/build/index.js"],
      "env": {
        "GODOT_PATH": "C:/Program Files/Godot/Godot.exe"
      }
    }
  }
}
```

> Windows 用户需要将 Godot 路径设为：`C:/Program Files/Godot/Godot.exe`
> macOS 用户设为：`/Applications/Godot.app/Contents/MacOS/Godot`
> Linux 用户设为：`/usr/bin/godot`

---

### A.4 验证 MCP 连接

配置完成后，**重启 Cursor**。

在 Cursor 的 MCP 设置页面中，应该能看到 `godot` 服务器显示为 **Connected**。

也可以在 Cursor 的 AI 对话框中测试：

```
/query godot status
```

如果返回 Godot 连接状态，说明 MCP 已正常工作。

---

### A.5 MCP + Godot 开发流程（完整六步）

在标准开发流程的基础上，引入 MCP 后，整个开发循环变为：

```
┌──────────────────────────────────────────────────────────────┐
│               MCP + Godot 完整开发循环                          │
│                                                              │
│  ① 拉取分支到本地  →  ② 让 AI 阅读规范  →                      │
│                                                              │
│  ③ AI 写代码（通过 MCP 直接编辑 .gd / .tscn）  →               │
│                                                              │
│  ④ 启动 Godot 预览效果 / 运行测试  →                           │
│                                                              │
│  ⑤ 确认效果正确后提交  →  ⑥ 发 PR  →  ⑦ Review  →  ⑧ 合并    │
└──────────────────────────────────────────────────────────────┘
```

#### ③ AI 直接编辑 Godot 脚本（通过 MCP）

配置好 MCP 后，AI 可以直接使用工具操作 Godot 项目：

| AI 可使用的 MCP 工具 | 说明 |
|:--------------------|:-----|
| `godot_create_script` | 在指定路径创建新的 `.gd` 脚本 |
| `godot_edit_script` | 编辑现有 `.gd` 脚本 |
| `godot_create_scene` | 创建新的 `.tscn` 场景文件 |
| `godot_modify_scene` | 修改现有场景（添加节点、设置属性） |
| `godot_execute_command` | 执行 Godot 命令 |
| `godot_get_debug_output` | 获取实时调试输出 |

#### ④ 启动 Godot 预览效果

```bash
# 通过 AI 调用 MCP 工具启动 Godot
godot_launch_editor()
godot_run_scene("res://scenes/levels/Level01.tscn")
godot_get_debug_output()
```

或在 Godot 编辑器中手动运行：
1. 在 Cursor 中让 AI 写完代码
2. 打开 Godot 编辑器（已在 MCP 中启动）
3. 切换到对应场景，按 **F5** 运行
4. 观察效果是否符合预期

> **MCP 实时调试输出**：游戏运行时的 `print()`、警告、错误会实时显示在 Cursor 的 MCP 调试面板中。

---

### A.6 MCP 开发规范补充

使用 MCP + Godot 开发时，**额外遵守以下规则**：

#### A.6.1 场景文件（.tscn）操作规范

```markdown
## 使用 MCP 修改 .tscn 之前，必须：

1. 先用 MCP 工具读取当前场景文件内容
2. 了解现有节点树结构
3. 明确要添加/修改的节点及其路径
4. 操作后用 MCP 验证文件格式正确（.tscn 是文本格式）
```

#### A.6.2 运行测试规范

```markdown
## 每完成一个功能模块的开发，必须：

1. 在 Godot 编辑器中运行对应场景
2. 确认无运行时错误（Error 红字）
3. 确认功能符合预期
4. 检查 MCP 调试输出中无异常警告
5. 通过后才进行 git commit
```

#### A.6.3 Commit 时的额外检查

```markdown
## MCP + Godot 开发额外检查项：

- [ ] .tscn 场景文件格式正确，可被 Godot 编辑器正常打开
- [ ] 新增的节点路径与代码中 get_node() 引用的路径一致
- [ ] 运行测试通过，无崩溃或 Error
- [ ] .gd 脚本中的 @export 变量已在编辑器中正确配置
- [ ] 多人协作时，确保 .tscn 的节点命名不冲突
```

#### A.6.4 多人协作注意事项

> 当多人通过 MCP 各自在分支上修改 `.tscn` 文件时，容易产生 **git merge 冲突**，因为 `.tscn` 是文本格式但节点树结构复杂。

```markdown
## 避免 .tscn 冲突的策略：

1. 各自在不同的场景文件中开发（推荐）
2. 如果必须在同一个场景中改：
   - 约定好各自负责的节点分支路径
   - 例如：新街负责 `/levels/`，池言いく负责 `/entities/`
3. 合并前先在 Godot 编辑器中打开 .tscn 确认节点树正常
```

---

### A.7 Cursor MCP 配置检查清单

```
MCP + Godot 环境配置检查：

- [ ] Node.js 18+ 已安装（运行 node -v 验证）
- [ ] Godot-MCP server 已克隆并编译成功
- [ ] godot-mcp addon 已复制到项目的 addons/ 目录
- [ ] Godot 编辑器中已启用 MCP 插件
- [ ] .cursor/mcp.json 配置正确，路径无误
- [ ] Cursor 重启后 MCP 服务器状态为 Connected
- [ ] 能够在 Cursor 中执行 godot 命令
```

---

*文档版本：1.1*
*最后更新：2026-04-28*
*维护者：新街*
