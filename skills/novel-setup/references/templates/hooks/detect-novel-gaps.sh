#!/bin/bash
# detect-novel-gaps.sh — 检测写作项目中的缺口
# 设计原则：无缺口时完全静默，不输出任何内容，避免污染 context
set -euo pipefail

# 加载公共函数库（project_root + discover_all_books）
source "$(dirname "$0")/lib/common.sh"

ROOT=$(project_root)
OUTPUT=""
HAS_WARNINGS=false

# 1. 新项目检测：没有书名目录
declare -a BOOK_DIRS=()
while IFS= read -r dir; do
  [ -n "$dir" ] && BOOK_DIRS+=("$dir")
done < <(discover_all_books)

if [ "${#BOOK_DIRS[@]}" -eq 0 ]; then
  # 完全新项目，没有任何目录结构 — 静默退出
  exit 0
fi

for BOOK_DIR in "${BOOK_DIRS[@]}"; do
  BOOK_NAME=$(basename "$BOOK_DIR")
  BOOK_OUTPUT=""

  # 2. 正文多但设定少
  CHAPTER_COUNT=0
  SETTING_COUNT=0
  if [ -d "$BOOK_DIR/正文" ]; then
    CHAPTER_COUNT=$(find "$BOOK_DIR/正文" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [ -d "$BOOK_DIR/设定" ]; then
    SETTING_COUNT=$(find "$BOOK_DIR/设定" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [ "$CHAPTER_COUNT" -gt 10 ] && [ "$SETTING_COUNT" -lt 3 ]; then
    BOOK_OUTPUT+="[WARN] $BOOK_NAME: $CHAPTER_COUNT chapters but only $SETTING_COUNT setting files. Consider adding more settings.\n"
  fi

  # 3. 过期伏笔
  if [ -f "$BOOK_DIR/追踪/伏笔.md" ]; then
    ABNORMAL_FORESHADOW=$(grep -c "逾期" "$BOOK_DIR/追踪/伏笔.md" 2>/dev/null || echo "0")
    if [ "$ABNORMAL_FORESHADOW" -gt 0 ]; then
      BOOK_OUTPUT+="[WARN] $BOOK_NAME: $ABNORMAL_FORESHADOW overdue foreshadowing entries in 伏笔.md. Run /novel-review to audit.\n"
    fi
  fi

  # 4. 大纲缺失
  if [ -d "$BOOK_DIR/正文" ]; then
    if [ -d "$BOOK_DIR/追踪" ] && [ ! -d "$BOOK_DIR/大纲" ]; then
      BOOK_OUTPUT+="[WARN] $BOOK_NAME: 正文/ exists but 大纲/ is missing. Run /novel-outline first.\n"
    fi
  fi

  # 5. 追踪文件缺失
  if [ -d "$BOOK_DIR/追踪" ]; then
    for tracker in 进度.md 伏笔.md 角色状态.md 知识库.md 上下文.md; do
      if [ ! -f "$BOOK_DIR/追踪/$tracker" ]; then
        BOOK_OUTPUT+="[WARN] $BOOK_NAME: 追踪/$tracker is missing. Run /novel-setup to restore.\n"
      fi
    done
  fi

  # 仅在有问题时输出该书目的信息
  if [ -n "$BOOK_OUTPUT" ]; then
    OUTPUT+="Checking: $BOOK_NAME\n$BOOK_OUTPUT"
    HAS_WARNINGS=true
  fi
done

# 仅在有警告时输出
if [ "$HAS_WARNINGS" = true ]; then
  printf '%b' "=== Novel Gap Detection ===\n$OUTPUT\n"
fi
