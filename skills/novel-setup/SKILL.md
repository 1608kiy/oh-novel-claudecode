---
name: novel-setup
version: 1.0.0
description: |
  长篇小说工具集基础设施部署。将 hooks/rules/agents/CLAUDE.md 部署到用户项目目录。
  兼容 Claude Code、OpenCode、Codex、Cursor 等平台。
  触发方式：/novel-setup、「准备写书」「帮我搭环境」「配置写作项目」
---

# novel-setup：小说工具集基础设施部署

你是写作基础设施部署器。将小说工具集的全套基础设施部署到用户项目目录。

**铁律：不覆盖用户已有配置，合并而非替换。**

---

## Phase 1：检测项目状态

1. 检查当前目录是否已部署过（存在 `.novel-deployed`）
   - 已存在 → 询问是否重新部署
2. 检查是否有书名目录（包含 `追踪/` 子目录的目录）
   - 有 → 长篇项目，显示当前项目信息
   - 无 → 新项目
3. 检查 `.claude/settings.local.json` 是否存在
   - 存在 → 读取，后续合并
   - 不存在 → 后续创建
4. 检查 `.active-book` 是否存在
   - 存在 → 显示当前活跃书目

## Phase 2：部署基础设施

### 2.1 部署 CLAUDE.md

- 读取 `novel-setup/references/templates/CLAUDE.md.tmpl`
- 替换占位符：`{项目名}`、`{书名}`
- 写入项目根目录 `CLAUDE.md`（已存在则按 marker/section 合并）

### 2.2 部署 Hooks

- 递归复制 `novel-setup/references/templates/hooks/` → `.claude/hooks/`
- 保留 `lib/common.sh` 和 `lib/sentinel.sh`
- 对 `.claude/hooks/*.sh` 设置执行权限

### 2.3 部署 Rules

- 复制 `novel-setup/references/templates/rules/*.md` → `.claude/rules/`

### 2.4 部署 Agents

- 复制 `novel-setup/references/templates/agents/*.md` → `.claude/agents/`

### 2.5 部署 Agent References

- 复制 `novel-setup/references/agent-references/*.md` → `.claude/skills/novel-setup/references/agent-references/`

### 2.6 合并 Hooks 注册到 settings.local.json

- 读取 `novel-setup/references/templates/settings-hooks.json`
- 与用户现有 `.claude/settings.local.json` 合并（按 command 去重）

### 2.7 创建部署标记

创建 `.novel-deployed` 文件：
```
deployed_at: <timestamp>
agents_version: 1
setup_skill_version: 1.0.0
target_cli: claude-code
references_dir: .claude/skills/novel-setup/references/agent-references
```

### 2.8 创建项目目录结构

```
{书名}/
├── 正文/
├── 设定/
│   ├── 角色/
│   ├── 世界观/
│   └── 势力/
├── 大纲/
├── 追踪/
│   ├── 进度.md
│   ├── 伏笔.md
│   ├── 角色状态.md
│   ├── 知识库.md
│   ├── 剧情线.md
│   ├── 节奏图.md
│   └── 上下文.md
├── 对标/
├── 拆文库/
├── 参考资料/
└── backups/
```

---

## 工具脚本

novel-setup 提供以下工具脚本，位于 `novel-setup/references/templates/scripts/`：

### convert_json_to_md.ps1 — JSON 转 Markdown（推荐）

将 E:\novel 等旧项目的 JSON 状态文件转换为 Markdown 格式。

```powershell
.\convert_json_to_md.ps1 <项目目录>
```

转换内容：
- `progress.json` → `追踪/进度.md`
- `foreshadowing.json` → `追踪/伏笔.md`
- `character_state.json` → `追踪/角色状态.md`
- `knowledge.json` → `追踪/知识库.md`

### convert_json_to_md.py — JSON 转 Markdown（Python 版本）

如果 Python 环境可用，也可以使用 Python 版本：

```bash
python convert_json_to_md.py <项目目录>
```

### backup_project.py — 备份项目

```bash
python backup_project.py <项目目录> [备份名称]
```

备份内容：正文/、追踪/、大纲/、设定/、CLAUDE.md

### export_chapters.py — 导出章节

```bash
python export_chapters.py <项目目录> --all              # 导出所有
python export_chapters.py <项目目录> --volume 1         # 导出第1卷
python export_chapters.py <项目目录> --range 1-10       # 导出第1-10章
python export_chapters.py <项目目录> --all --format txt # 导出为txt
```

## Phase 3：验证安装

1. 验证 hooks 注册
2. 验证 rules 路径
3. 验证 7 个 agent 文件
4. 验证 agent reference bundle
5. 验证 `.novel-deployed`
6. 输出安装报告

---

## Phase 4：继续已有项目

当检测到项目已有内容（正文/目录有文件，或追踪/目录有文件）时，进入此流程。

### 4.1 检测现有状态

检查以下文件是否存在：
- `追踪/进度.md` — 已有则读取当前进度
- `追踪/伏笔.md` — 已有则读取伏笔状态
- `追踪/角色状态.md` — 已有则读取角色状态
- `追踪/知识库.md` — 已有则读取知识库
- `追踪/上下文.md` — 已有则读取上次进度快照

### 4.2 检测 JSON 格式状态（兼容 E:\novel 等旧项目）

如果检测到 JSON 格式的状态文件（如 `progress.json`、`foreshadowing.json`），提示用户：
```
检测到 JSON 格式的状态文件。是否转换为 Markdown 格式？
转换后可以使用 novel-* 系列 skill 的完整功能。
```

如果用户同意，执行转换：
- `progress.json` → `追踪/进度.md`
- `foreshadowing.json` → `追踪/伏笔.md`
- `character_state.json` → `追踪/角色状态.md`
- `knowledge.json` → `追踪/知识库.md`

### 4.3 显示项目状态

输出：
```
项目状态：
- 书名：{书名}
- 总章数：{X}
- 已完成：{Y}
- 当前位置：第{N}章
- 待处理伏笔：{Z} 个
```

### 4.4 确定下一步

根据项目状态，提示用户：
- 如果有未完成的章节 → 建议运行 `novel-write` 继续写作
- 如果大纲不完整 → 建议运行 `novel-outline` 补充大纲
- 如果有审查问题 → 建议运行 `novel-review` 处理问题

---

## Phase 5：迁移标准化流程

当用户要求迁移旧项目时，按以下标准化流程执行：

### 5.1 迁移前检查

```
检查项：
- [ ] 旧项目目录是否存在
- [ ] 是否有 JSON 状态文件（progress.json 等）
- [ ] 是否有章节文件（state/chapters/ 或 正文/）
- [ ] 是否有配置文件（config.yaml）
- [ ] 是否有审查/质量报告（state/reviews/、state/quality/）
- [ ] 是否有章节摘要（state/summaries/）
- [ ] 是否有章节简报（state/briefs/）
```

### 5.2 迁移步骤

| 步骤 | 操作 | 输出 |
|------|------|------|
| 1 | 创建新目录结构 | 正文/、设定/、大纲/、追踪/、对标/、拆文库/、参考资料/、backups/、output/ |
| 2 | 复制章节文件 | 正文/第{N}章_{章名}.md |
| 3 | 转换 JSON → Markdown | 追踪/进度.md、伏笔.md、角色状态.md、知识库.md |
| 4 | 转换扩展 JSON → Markdown | 追踪/节奏图.md、剧情线.md、读者承诺.md、势力动态.md、风格样本.md、术语表.md、项目圣经.md |
| 5 | 复制章节摘要 | 追踪/摘要/（从 state/summaries/ 复制） |
| 6 | 复制章节简报 | 追踪/简报/（从 state/briefs/ 复制） |
| 7 | 复制章节审查 | 追踪/审查/（从 state/reviews/ 复制） |
| 8 | 复制质量报告 | 追踪/质量/（从 state/quality/ 复制） |
| 9 | 创建缺失的追踪文件 | 追踪/上下文.md |
| 10 | 部署 novel-setup 基础设施 | .claude/ 目录 |
| 11 | 执行健康度检查 | 追踪/伏笔健康度.md、节奏健康度.md |
| 12 | 生成迁移报告 | 追踪/迁移报告.md |

### 5.2.1 问卦项目特殊处理

问卦项目有以下特殊目录需要处理：

| 源目录 | 目标目录 | 说明 |
|--------|---------|------|
| state/chapters/ | 正文/ | 章节文件（ch_001.txt → 第001章.md） |
| state/chapters_revised/ | 正文/ | 修订后的章节（优先使用） |
| state/chapters_manual/ | 正文/ | 手动编辑的章节（最优先） |
| state/summaries/ | 追踪/摘要/ | 章节摘要 |
| state/briefs/ | 追踪/简报/ | 章节简报 |
| state/reviews/ | 追踪/审查/ | 章节审查 |
| state/quality/ | 追踪/质量/ | 质量报告 |
| state/volume_reports/ | 追踪/卷报告/ | 卷报告 |
| state/feedback/ | 追踪/反馈/ | 反馈记录 |
| state/foreshadowing_reschedule/ | 追踪/伏笔重调度/ | 伏笔重调度记录 |

章节文件优先级：
1. state/chapters_manual/（最优先）
2. state/chapters_revised/（次优先）
3. state/chapters/（默认）

### 5.2.2 章节文件命名转换

问卦项目的章节文件命名格式：
- 源文件：ch_001.txt、ch_002.txt
- 目标文件：第001章.md、第002章.md

转换规则：
1. 提取章节号：ch_001.txt → 1
2. 生成目标文件名：第001章.md
3. 如果源文件有章名（如 ch_001_京城.md），使用章名：第001章_京城.md

### 5.3 迁移报告格式

```markdown
## 迁移报告

### 基本信息
- 迁移时间：{timestamp}
- 源目录：{source}
- 目标目录：{target}

### 迁移内容
- 章节文件：{X} 个
- 状态文件：{X} 个
- 配置文件：{X} 个

### 健康度检查
- 伏笔健康度：{score}/100
- 节奏健康度：{score}/100
- 角色完整度：{score}/100
- 文件完整度：{score}/100

### 发现的问题
- {问题1}
- {问题2}

### 建议的下一步
- {建议1}
- {建议2}
```

### 5.4 迁移后验证

```
验证项：
- [ ] 所有章节文件已复制
- [ ] 追踪文件已创建
- [ ] 健康度报告已生成
- [ ] novel-setup 基础设施已部署
- [ ] 可以正常加载 novel-write 继续写作
```

---

## 会话恢复

当会话中断后重新开始时，session-start.sh 会自动显示项目状态。恢复流程：

1. 读取 `追踪/上下文.md` — 获取上次进度快照
2. 读取 `追踪/进度.md` — 获取章节完成状态
3. 显示当前位置和下一步建议

用户可以直接说「继续」或「续写」，novel-write 会从上次中断的位置继续。

---

## CLAUDE.md 合并策略

按 marker/section 合并：
1. 识别 novel-setup 管理块标记（如有，只替换标记内内容）
2. 无标记 → 按 `##` 标题切分 section
3. 模板标准 section（Skill 路由表、文件结构、协作规则等）覆盖用户同名 section
4. 用户独有 section 保留不动

## settings-hooks.json 合并算法

按 hook command 去重：
1. 用户已有 hook command → 保留
2. 模板新 hook command → append
3. 用户独有配置 → 完整保留

---

## 模板占位符

| 占位符 | 替换规则 |
|--------|----------|
| `{项目名}` | 用户项目名称或目录名 |
| `{书名}` | 书名目录名 |
