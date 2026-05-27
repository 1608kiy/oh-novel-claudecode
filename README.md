# oh-novel-claudecode

长篇小说创作工具箱 — 基于 Claude Code 的 AI 辅助写作系统

## 功能特性

- **大纲创作**：选题→设定→卷纲→细纲，阶段推进
- **正文写作**：章节循环（简报→预检→写→检→审→润→接受）
- **质量审查**：16 维度评分，问题分级，修改建议
- **润色去AI味**：六道门系统，身体细节替代情绪词
- **伏笔管理**：播种→推进→验证→动态重调度
- **状态追踪**：角色状态、知识库、时间线、节奏图
- **导出发布**：合并章节，适配起点/番茄/晋江

## 安装

```bash
npx skills add 1608kiy/oh-novel-claudecode -g -y
```

## 快速上手

```
/novel-setup    → 部署环境（5分钟）
/novel-outline  → 写大纲
/novel-write    → 开始写正文
```

## Skill 列表

| Skill | 说明 |
|-------|------|
| `novel` | 主路由，自动分发 |
| `novel-setup` | 环境部署 |
| `novel-outline` | 大纲创作 |
| `novel-write` | 正文写作 |
| `novel-review` | 质量审查 |
| `novel-polish` | 润色去AI味 |
| `novel-explorer` | 项目查询 |
| `novel-researcher` | 资料搜集 |
| `novel-scan` | 排行榜扫描 |
| `novel-analyze` | 拆文分析 |
| `novel-import` | 导入已有小说 |
| `novel-cover` | 封面生成 |

## 写作模式

| 模式 | 触发条件 | 流程 |
|------|---------|------|
| 开书 | 项目无正文 | 完整流程 |
| 日更 | 续写、日更 | 简化流程 |
| 修订 | 修改第X章 | 定向重写 |
| 重写 | 重写第X章 | 整章重写 |
| 导出 | 导出、合并 | 合并发布 |

## 工具脚本

```bash
# JSON状态文件转换（兼容旧项目）
python scripts/convert_json_to_md.py <项目目录>

# 备份项目
python scripts/backup_project.py <项目目录>

# 导出章节
python scripts/export_chapters.py <项目目录> --all
python scripts/export_chapters.py <项目目录> --volume 1
python scripts/export_chapters.py <项目目录> --range 1-10
```

## Agent

| Agent | 模型 | 职责 |
|-------|------|------|
| story-architect | opus | 架构设计、世界观、大纲 |
| narrative-writer | sonnet | 正文写作 |
| character-designer | sonnet | 角色设计、对话 |
| consistency-checker | haiku | 一致性检查 |
| story-explorer | haiku | 项目查询 |
| story-researcher | sonnet | 资料搜集 |
| chapter-extractor | haiku | 章节摘要 |

## 参考文档

包含 25+ 参考文档，涵盖：

- 写作技法（writing-craft、style-craft）
- 题材公式（genre-catalog、genre-writing-formulas）
- 角色设计（character-basics、character-design-methods）
- 钩子设计（hooks-chapter、hooks-suspense）
- 情绪设计（emotional-arc-design、emotional-methods）
- 反转设计（reversal-toolkit）
- 禁词表（banned-words）
- 去AI味（anti-ai-writing）

## 项目结构

```
{书名}/
├── 正文/          # 正文章节
├── 设定/          # 角色、世界观、势力
├── 大纲/          # 卷纲、细纲
├── 追踪/          # 进度、伏笔、角色状态、知识库
├── 对标/          # 对标作品分析
├── 拆文库/        # 拆文分析结果
├── 参考资料/      # 研究资料
├── backups/       # 备份
└── output/        # 导出文件
```

## 相关项目

- [oh-story-claudecode](https://github.com/worldwonderer/oh-story-claudecode) — 网文写作工具集（短篇+长篇）

## License

MIT
