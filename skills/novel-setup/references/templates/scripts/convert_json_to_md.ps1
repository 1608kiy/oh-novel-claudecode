#!/usr/bin/env pwsh
# convert_json_to_md.ps1 — 将问卦项目的 JSON 状态文件转换为 Markdown 格式
# 用法: .\convert_json_to_md.ps1 <项目目录>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectDir
)

$ErrorActionPreference = "Stop"

# 检查目录
if (-not (Test-Path $ProjectDir)) {
    Write-Host "错误: 目录不存在 $ProjectDir"
    exit 1
}

# 查找 state 目录
$stateDir = $null
if (Test-Path "$ProjectDir\state\progress.json") {
    $stateDir = "$ProjectDir\state"
} elseif (Test-Path "$ProjectDir\progress.json") {
    $stateDir = $ProjectDir
}

if (-not $stateDir) {
    Write-Host "错误: 找不到 progress.json"
    exit 1
}

# 追踪目录
$trackDir = "$ProjectDir\追踪"
New-Item -ItemType Directory -Path $trackDir -Force | Out-Null

Write-Host "项目目录: $ProjectDir"
Write-Host "状态目录: $stateDir"
Write-Host "追踪目录: $trackDir"
Write-Host ""

$converted = 0

# ============================================================
# 1. 转换 progress.json → 追踪/进度.md
# ============================================================
if (Test-Path "$stateDir\progress.json") {
    Write-Host "转换 progress.json..."
    $progress = Get-Content "$stateDir\progress.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 进度"
    $lines += ""
    $lines += "## 统计"
    $lines += ""
    
    # 问卦的 progress.json 有 chapters 子对象
    $chapters = if ($progress.chapters) { $progress.chapters } else { $progress }
    
    $total = 0
    $drafted = 0
    $reviewed = 0
    $polished = 0
    $accepted = 0
    $needsRewrite = 0
    
    foreach ($prop in $chapters.PSObject.Properties) {
        $total++
        $ch = $prop.Value
        if ($ch.draft) { $drafted++ }
        if ($ch.reviewed) { $reviewed++ }
        if ($ch.polished) { $polished++ }
        if ($ch.accepted) { $accepted++ }
        if ($ch.needs_rewrite) { $needsRewrite++ }
    }
    
    $lines += "- 总章数: $total"
    $lines += "- 已写: $drafted"
    $lines += "- 已审查: $reviewed"
    $lines += "- 已润色: $polished"
    $lines += "- 已接受: $accepted"
    $lines += "- 需重写: $needsRewrite"
    $lines += ""
    $lines += "## 章节状态"
    $lines += ""
    $lines += "| 章节 | 状态 | 审查分 | 问题数 | 更新时间 |"
    $lines += "|------|------|--------|--------|----------|"
    
    foreach ($prop in $chapters.PSObject.Properties | Sort-Object { [int]$_.Name }) {
        $chNum = $prop.Name
        $ch = $prop.Value
        
        # 确定状态
        $status = "待写"
        if ($ch.accepted) { $status = "已接受" }
        elseif ($ch.polished) { $status = "已润色" }
        elseif ($ch.reviewed) { $status = "已审查" }
        elseif ($ch.draft) { $status = "已写" }
        
        $score = if ($ch.review_score) { $ch.review_score } else { "-" }
        $issues = if ($ch.major_issues) { $ch.major_issues } else { "0" }
        $updated = if ($ch.updated_at) { $ch.updated_at.Substring(0, 10) } else { "-" }
        
        $lines += "| 第${chNum}章 | $status | $score | $issues | $updated |"
    }
    
    $lines | Set-Content "$trackDir\进度.md" -Encoding UTF8
    Write-Host "  ✓ 进度.md ($total 章)"
    $converted++
}

# ============================================================
# 2. 转换 foreshadowing.json → 追踪/伏笔.md
# ============================================================
if (Test-Path "$stateDir\foreshadowing.json") {
    Write-Host "转换 foreshadowing.json..."
    $foreshadowing = Get-Content "$stateDir\foreshadowing.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 伏笔追踪"
    $lines += ""
    
    $items = if ($foreshadowing.items) { $foreshadowing.items } else { $foreshadowing }
    
    $planted = @()
    $advanced = @()
    $resolved = @()
    
    foreach ($item in $items) {
        $status = if ($item.status) { $item.status } else { "planted" }
        switch ($status) {
            "resolved" { $resolved += $item }
            "advanced" { $advanced += $item }
            default { $planted += $item }
        }
    }
    
    # 活跃伏笔（已播种）
    $lines += "## 已播种"
    $lines += ""
    $lines += "| 伏笔 | 最后活跃 |"
    $lines += "|------|----------|"
    foreach ($item in $planted) {
        $name = if ($item.name) { $item.name } else { "-" }
        $lastActive = if ($item.last_active_chapter) { "第$($item.last_active_chapter)章" } else { "-" }
        $lines += "| $name | $lastActive |"
    }
    $lines += ""
    
    # 已推进
    $lines += "## 已推进"
    $lines += ""
    $lines += "| 伏笔 | 最后活跃 |"
    $lines += "|------|----------|"
    foreach ($item in $advanced) {
        $name = if ($item.name) { $item.name } else { "-" }
        $lastActive = if ($item.last_active_chapter) { "第$($item.last_active_chapter)章" } else { "-" }
        $lines += "| $name | $lastActive |"
    }
    $lines += ""
    
    # 已回收
    if ($resolved.Count -gt 0) {
        $lines += "## 已回收"
        $lines += ""
        $lines += "| 伏笔 | 最后活跃 |"
        $lines += "|------|----------|"
        foreach ($item in $resolved) {
            $name = if ($item.name) { $item.name } else { "-" }
            $lastActive = if ($item.last_active_chapter) { "第$($item.last_active_chapter)章" } else { "-" }
            $lines += "| $name | $lastActive |"
        }
        $lines += ""
    }
    
    # 统计
    $lines += "## 统计"
    $lines += ""
    $lines += "- 已播种: $($planted.Count) 个"
    $lines += "- 已推进: $($advanced.Count) 个"
    $lines += "- 已回收: $($resolved.Count) 个"
    $lines += "- 总计: $($items.Count) 个"
    
    $lines | Set-Content "$trackDir\伏笔.md" -Encoding UTF8
    Write-Host "  ✓ 伏笔.md ($($items.Count) 个)"
    $converted++
}

# ============================================================
# 3. 转换 character_state.json → 追踪/角色状态.md
# ============================================================
if (Test-Path "$stateDir\character_state.json") {
    Write-Host "转换 character_state.json..."
    $charState = Get-Content "$stateDir\character_state.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 角色状态"
    $lines += ""
    
    $characters = if ($charState.characters) { $charState.characters } else { $charState }
    
    foreach ($ch in $characters) {
        $name = if ($ch.name) { $ch.name } else { "未知" }
        $lines += "## $name"
        $lines += ""
        
        if ($ch.last_active_chapter) {
            $lines += "- 最后出场: 第$($ch.last_active_chapter)章"
        }
        if ($ch.current_location) {
            $lines += "- 当前位置: $($ch.current_location)"
        }
        if ($ch.goal) {
            $lines += "- 当前目标: $($ch.goal)"
        }
        if ($ch.last_seen) {
            $lines += "- 最后出现: 第$($ch.last_seen)章"
        }
        if ($ch.relationships) {
            $lines += "- 关系: $($ch.relationships -join ', ')"
        }
        if ($ch.unfinished_clues) {
            $lines += "- 未解线索: $($ch.unfinished_clues -join ', ')"
        }
        $lines += ""
    }
    
    $lines | Set-Content "$trackDir\角色状态.md" -Encoding UTF8
    Write-Host "  ✓ 角色状态.md ($($characters.Count) 个角色)"
    $converted++
}

# ============================================================
# 4. 转换 knowledge.json → 追踪/知识库.md
# ============================================================
if (Test-Path "$stateDir\knowledge.json") {
    Write-Host "转换 knowledge.json..."
    $knowledge = Get-Content "$stateDir\knowledge.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 知识库"
    $lines += ""
    $lines += "> 累积的故事事实"
    $lines += ""
    
    # 问卦的 knowledge.json 用 facts 数组，每项是字符串
    $facts = if ($knowledge.facts) { $knowledge.facts } else { $knowledge }
    
    $lines += "## 事实列表"
    $lines += ""
    foreach ($fact in $facts) {
        $lines += "- $fact"
    }
    $lines += ""
    $lines += "## 统计"
    $lines += ""
    $lines += "- 总计: $($facts.Count) 条"
    
    $lines | Set-Content "$trackDir\知识库.md" -Encoding UTF8
    Write-Host "  ✓ 知识库.md ($($facts.Count) 条)"
    $converted++
}

# ============================================================
# 5. 转换 pacing_map.json → 追踪/节奏图.md
# ============================================================
if (Test-Path "$stateDir\pacing_map.json") {
    Write-Host "转换 pacing_map.json..."
    $pacingMap = Get-Content "$stateDir\pacing_map.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 节奏图"
    $lines += ""
    $lines += "## 章节节奏"
    $lines += ""
    $lines += "| 章节 | 情绪 | 强度 | 功能 |"
    $lines += "|------|------|------|------|"
    
    foreach ($entry in $pacingMap) {
        $chapter = if ($entry.chapter) { $entry.chapter } else { "-" }
        $beat = if ($entry.beat) { $entry.beat } else { "-" }
        $intensity = if ($entry.intensity) { $entry.intensity } else { "-" }
        $function = if ($entry.function) { $entry.function } else { "-" }
        $lines += "| 第${chapter}章 | $beat | $intensity | $function |"
    }
    
    $lines | Set-Content "$trackDir\节奏图.md" -Encoding UTF8
    Write-Host "  ✓ 节奏图.md ($($pacingMap.Count) 章)"
    $converted++
}

# ============================================================
# 6. 转换 open_threads.json → 追踪/剧情线.md
# ============================================================
if (Test-Path "$stateDir\open_threads.json") {
    Write-Host "转换 open_threads.json..."
    $openThreads = Get-Content "$stateDir\open_threads.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 剧情线"
    $lines += ""
    
    $threads = if ($openThreads.threads) { $openThreads.threads } else { $openThreads }
    
    # 按状态分组
    $active = @()
    $resolved = @()
    
    foreach ($thread in $threads) {
        $status = if ($thread.status) { $thread.status } else { "active" }
        if ($status -eq "resolved" -or $status -eq "fulfilled") {
            $resolved += $thread
        } else {
            $active += $thread
        }
    }
    
    # 活跃剧情线
    $lines += "## 活跃剧情线"
    $lines += ""
    $lines += "| ID | 类型 | 标题 | 开始 | 状态 | 所有者 |"
    $lines += "|----|------|------|------|------|--------|"
    foreach ($thread in $active) {
        $id = if ($thread.id) { $thread.id } else { "-" }
        $type = if ($thread.type) { $thread.type } else { "-" }
        $title = if ($thread.title) { $thread.title } else { "-" }
        $opened = if ($thread.opened_at) { "第$($thread.opened_at)章" } else { "-" }
        $status = if ($thread.status) { $thread.status } else { "-" }
        $owner = if ($thread.owner) { $thread.owner } else { "-" }
        $lines += "| $id | $type | $title | $opened | $status | $owner |"
    }
    $lines += ""
    
    # 已解决剧情线
    if ($resolved.Count -gt 0) {
        $lines += "## 已解决剧情线"
        $lines += ""
        $lines += "| ID | 类型 | 标题 | 开始 | 状态 |"
        $lines += "|----|------|------|------|------|"
        foreach ($thread in $resolved) {
            $id = if ($thread.id) { $thread.id } else { "-" }
            $type = if ($thread.type) { $thread.type } else { "-" }
            $title = if ($thread.title) { $thread.title } else { "-" }
            $opened = if ($thread.opened_at) { "第$($thread.opened_at)章" } else { "-" }
            $status = if ($thread.status) { $thread.status } else { "-" }
            $lines += "| $id | $type | $title | $opened | $status |"
        }
        $lines += ""
    }
    
    # 统计
    $lines += "## 统计"
    $lines += ""
    $lines += "- 活跃: $($active.Count) 条"
    $lines += "- 已解决: $($resolved.Count) 条"
    $lines += "- 总计: $($threads.Count) 条"
    
    $lines | Set-Content "$trackDir\剧情线.md" -Encoding UTF8
    Write-Host "  ✓ 剧情线.md ($($threads.Count) 条)"
    $converted++
}

# ============================================================
# 7. 转换 reader_promises.json → 追踪/读者承诺.md
# ============================================================
if (Test-Path "$stateDir\reader_promises.json") {
    Write-Host "转换 reader_promises.json..."
    $readerPromises = Get-Content "$stateDir\reader_promises.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 读者承诺"
    $lines += ""
    
    $promises = if ($readerPromises.promises) { $readerPromises.promises } else { $readerPromises }
    
    # 按状态分组
    $fulfilled = @()
    $pending = @()
    
    foreach ($promise in $promises) {
        $status = if ($promise.status) { $promise.status } else { "pending" }
        if ($status -eq "fulfilled") {
            $fulfilled += $promise
        } else {
            $pending += $promise
        }
    }
    
    # 待兑现
    $lines += "## 待兑现"
    $lines += ""
    $lines += "| 承诺 | 最后活跃 |"
    $lines += "|------|----------|"
    foreach ($promise in $pending) {
        $text = if ($promise.promise) { $promise.promise } else { "-" }
        $lastActive = if ($promise.last_active_chapter) { "第$($promise.last_active_chapter)章" } else { "-" }
        $lines += "| $text | $lastActive |"
    }
    $lines += ""
    
    # 已兑现
    if ($fulfilled.Count -gt 0) {
        $lines += "## 已兑现"
        $lines += ""
        $lines += "| 承诺 | 最后活跃 |"
        $lines += "|------|----------|"
        foreach ($promise in $fulfilled) {
            $text = if ($promise.promise) { $promise.promise } else { "-" }
            $lastActive = if ($promise.last_active_chapter) { "第$($promise.last_active_chapter)章" } else { "-" }
            $lines += "| $text | $lastActive |"
        }
        $lines += ""
    }
    
    # 统计
    $lines += "## 统计"
    $lines += ""
    $lines += "- 待兑现: $($pending.Count) 个"
    $lines += "- 已兑现: $($fulfilled.Count) 个"
    $lines += "- 总计: $($promises.Count) 个"
    
    $lines | Set-Content "$trackDir\读者承诺.md" -Encoding UTF8
    Write-Host "  ✓ 读者承诺.md ($($promises.Count) 个)"
    $converted++
}

# ============================================================
# 8. 转换 faction_moves.json → 追踪/势力动态.md
# ============================================================
if (Test-Path "$stateDir\faction_moves.json") {
    Write-Host "转换 faction_moves.json..."
    $factionMoves = Get-Content "$stateDir\faction_moves.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 势力动态"
    $lines += ""
    $lines += "| 势力 | 状态 | 最后活跃 |"
    $lines += "|------|------|----------|"
    
    $moves = if ($factionMoves.moves) { $factionMoves.moves } else { $factionMoves }
    
    foreach ($move in $moves) {
        $faction = if ($move.faction) { $move.faction } else { "-" }
        $status = if ($move.status) { $move.status } else { "-" }
        $lastActive = if ($move.last_active_chapter) { "第$($move.last_active_chapter)章" } else { "-" }
        $lines += "| $faction | $status | $lastActive |"
    }
    
    $lines += ""
    $lines += "## 统计"
    $lines += ""
    $lines += "- 总计: $($moves.Count) 个势力"
    
    $lines | Set-Content "$trackDir\势力动态.md" -Encoding UTF8
    Write-Host "  ✓ 势力动态.md ($($moves.Count) 个势力)"
    $converted++
}

# ============================================================
# 9. 转换 style_samples.json → 追踪/风格样本.md
# ============================================================
if (Test-Path "$stateDir\style_samples.json") {
    Write-Host "转换 style_samples.json..."
    $styleSamples = Get-Content "$stateDir\style_samples.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 风格样本"
    $lines += ""
    
    if ($styleSamples.preferred) {
        $lines += "## 推荐风格"
        $lines += ""
        foreach ($item in $styleSamples.preferred) {
            $lines += "- $item"
        }
        $lines += ""
    }
    
    if ($styleSamples.avoid) {
        $lines += "## 避免风格"
        $lines += ""
        foreach ($item in $styleSamples.avoid) {
            $lines += "- $item"
        }
        $lines += ""
    }
    
    $lines | Set-Content "$trackDir\风格样本.md" -Encoding UTF8
    Write-Host "  ✓ 风格样本.md"
    $converted++
}

# ============================================================
# 10. 转换 canonical_terms.json → 追踪/术语表.md
# ============================================================
if (Test-Path "$stateDir\canonical_terms.json") {
    Write-Host "转换 canonical_terms.json..."
    $canonicalTerms = Get-Content "$stateDir\canonical_terms.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 术语表"
    $lines += ""
    $lines += "| 规范术语 | 别名 |"
    $lines += "|----------|------|"
    
    foreach ($prop in $canonicalTerms.PSObject.Properties) {
        $term = $prop.Name
        $aliases = $prop.Value
        $aliasStr = if ($aliases.Count -gt 0) { $aliases -join ', ' } else { "无" }
        $lines += "| $term | $aliasStr |"
    }
    
    $lines | Set-Content "$trackDir\术语表.md" -Encoding UTF8
    Write-Host "  ✓ 术语表.md ($($canonicalTerms.PSObject.Properties.Count) 个术语)"
    $converted++
}

# ============================================================
# 11. 转换 project_bible.json → 追踪/项目圣经.md
# ============================================================
if (Test-Path "$stateDir\project_bible.json") {
    Write-Host "转换 project_bible.json..."
    $projectBible = Get-Content "$stateDir\project_bible.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @()
    $lines += "# 项目圣经"
    $lines += ""
    
    if ($projectBible.core_theme) {
        $lines += "## 核心主题"
        $lines += ""
        $lines += $projectBible.core_theme
        $lines += ""
    }
    
    if ($projectBible.tone) {
        $lines += "## 基调"
        $lines += ""
        $lines += $projectBible.tone
        $lines += ""
    }
    
    if ($projectBible.story_promises) {
        $lines += "## 故事承诺"
        $lines += ""
        $lines += "| 承诺 | 开始 | 最后兑现 | 状态 |"
        $lines += "|------|------|----------|------|"
        foreach ($promise in $projectBible.story_promises) {
            $text = if ($promise.promise) { $promise.promise } else { "-" }
            $opened = if ($promise.opened_at) { "第$($promise.opened_at)章" } else { "-" }
            $lastPaid = if ($promise.last_paid_at) { "第$($promise.last_paid_at)章" } else { "-" }
            $status = if ($promise.status) { $promise.status } else { "-" }
            $lines += "| $text | $opened | $lastPaid | $status |"
        }
        $lines += ""
    }
    
    $lines | Set-Content "$trackDir\项目圣经.md" -Encoding UTF8
    Write-Host "  ✓ 项目圣经.md"
    $converted++
}

Write-Host ""
Write-Host "转换完成! 共转换 $converted 个文件"
Write-Host "追踪文件位置: $trackDir"
