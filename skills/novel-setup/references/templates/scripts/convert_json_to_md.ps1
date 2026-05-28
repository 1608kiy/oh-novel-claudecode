#!/usr/bin/env pwsh
# convert_json_to_md.ps1 — 将 JSON 状态文件转换为 Markdown 格式
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

# 转换 progress.json
if (Test-Path "$stateDir\progress.json") {
    Write-Host "转换 progress.json..."
    $progress = Get-Content "$stateDir\progress.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @("# 进度", "", "## 统计", "")
    
    # 统计
    $statusCount = @{}
    $total = 0
    foreach ($prop in $progress.PSObject.Properties) {
        $total++
        $status = if ($prop.Value.status) { $prop.Value.status } else { "unknown" }
        if ($statusCount.ContainsKey($status)) {
            $statusCount[$status]++
        } else {
            $statusCount[$status] = 1
        }
    }
    
    $lines += "- 总章数: $total"
    foreach ($status in $statusCount.Keys) {
        $lines += "- $status: $($statusCount[$status])"
    }
    $lines += "", "## 章节状态", "", "| 章节 | 状态 | 审查分 | 字数 | 备注 |", "|------|------|--------|------|------|"
    
    foreach ($prop in $progress.PSObject.Properties | Sort-Object { [int]$_.Name }) {
        $chNum = $prop.Name
        $ch = $prop.Value
        $status = if ($ch.status) { $ch.status } else { "-" }
        $score = if ($ch.review_score) { $ch.review_score } else { "-" }
        $wordCount = if ($ch.word_count) { $ch.word_count } else { "-" }
        $lines += "| 第${chNum}章 | $status | $score | $wordCount | |"
    }
    
    $lines | Set-Content "$trackDir\进度.md" -Encoding UTF8
    Write-Host "  ✓ 进度.md"
}

# 转换 foreshadowing.json
if (Test-Path "$stateDir\foreshadowing.json") {
    Write-Host "转换 foreshadowing.json..."
    $foreshadowing = Get-Content "$stateDir\foreshadowing.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @("# 伏笔追踪", "")
    
    $active = @()
    $recovered = @()
    $overdue = @()
    
    $items = if ($foreshadowing.items) { $foreshadowing.items } else { $foreshadowing }
    
    foreach ($item in $items) {
        $status = if ($item.status) { $item.status } else { "active" }
        switch ($status) {
            "recovered" { $recovered += $item }
            "overdue" { $overdue += $item }
            default { $active += $item }
        }
    }
    
    # 活跃伏笔
    $lines += "## 活跃伏笔", "", "| ID | 伏笔 | 播种章节 | 预计回收 | 状态 |", "|----|------|---------|---------|------|"
    foreach ($item in $active) {
        $id = if ($item.id) { $item.id } else { "-" }
        $desc = if ($item.description) { $item.description } else { "-" }
        $plant = if ($item.plant_chapter) { $item.plant_chapter } else { "-" }
        $recover = if ($item.recover_chapter) { $item.recover_chapter } else { "-" }
        $status = if ($item.status) { $item.status } else { "已播种" }
        $lines += "| $id | $desc | $plant | $recover | $status |"
    }
    
    # 逾期伏笔
    if ($overdue.Count -gt 0) {
        $lines += "", "## 逾期伏笔", "", "| ID | 伏笔 | 播种章节 | 预计回收 | 状态 |", "|----|------|---------|---------|------|"
        foreach ($item in $overdue) {
            $id = if ($item.id) { $item.id } else { "-" }
            $desc = if ($item.description) { $item.description } else { "-" }
            $plant = if ($item.plant_chapter) { $item.plant_chapter } else { "-" }
            $recover = if ($item.recover_chapter) { $item.recover_chapter } else { "-" }
            $lines += "| $id | $desc | $plant | $recover | 逾期 |"
        }
    }
    
    # 已回收伏笔
    if ($recovered.Count -gt 0) {
        $lines += "", "## 已回收伏笔", "", "| ID | 伏笔 | 播种章节 | 回收章节 |", "|----|------|---------|----------|"
        foreach ($item in $recovered) {
            $id = if ($item.id) { $item.id } else { "-" }
            $desc = if ($item.description) { $item.description } else { "-" }
            $plant = if ($item.plant_chapter) { $item.plant_chapter } else { "-" }
            $recover = if ($item.recover_chapter) { $item.recover_chapter } else { "-" }
            $lines += "| $id | $desc | $plant | $recover |"
        }
    }
    
    # 统计
    $lines += "", "## 统计", "", "- 活跃: $($active.Count) 个", "- 逾期: $($overdue.Count) 个", "- 已回收: $($recovered.Count) 个"
    
    $lines | Set-Content "$trackDir\伏笔.md" -Encoding UTF8
    Write-Host "  ✓ 伏笔.md"
}

# 转换 character_state.json
if (Test-Path "$stateDir\character_state.json") {
    Write-Host "转换 character_state.json..."
    $charState = Get-Content "$stateDir\character_state.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @("# 角色状态", "")
    
    $characters = if ($charState.characters) { $charState.characters } else { $charState }
    
    foreach ($prop in $characters.PSObject.Properties) {
        $name = $prop.Name
        $info = $prop.Value
        $lines += "## $name", ""
        
        foreach ($field in $info.PSObject.Properties) {
            $lines += "- $($field.Name): $($field.Value)"
        }
        $lines += ""
    }
    
    $lines | Set-Content "$trackDir\角色状态.md" -Encoding UTF8
    Write-Host "  ✓ 角色状态.md"
}

# 转换 knowledge.json
if (Test-Path "$stateDir\knowledge.json") {
    Write-Host "转换 knowledge.json..."
    $knowledge = Get-Content "$stateDir\knowledge.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $lines = @("# 知识库", "", "> 累积的故事事实", "")
    
    $items = if ($knowledge.items) { $knowledge.items } else { $knowledge }
    
    # 按类型分组
    $characters = @()
    $settings = @()
    $plots = @()
    
    foreach ($item in $items) {
        $type = if ($item.type) { $item.type } else { "other" }
        switch ($type) {
            "character" { $characters += $item }
            "setting" { $settings += $item }
            "plot" { $plots += $item }
        }
    }
    
    if ($characters.Count -gt 0) {
        $lines += "## 角色事实", "", "| 事实 | 首次出现 |", "|------|----------|"
        foreach ($item in $characters) {
            $desc = if ($item.description) { $item.description } else { "-" }
            $chapter = if ($item.chapter) { $item.chapter } else { "-" }
            $lines += "| $desc | 第${chapter}章 |"
        }
        $lines += ""
    }
    
    if ($settings.Count -gt 0) {
        $lines += "## 设定事实", "", "| 事实 | 首次出现 |", "|------|----------|"
        foreach ($item in $settings) {
            $desc = if ($item.description) { $item.description } else { "-" }
            $chapter = if ($item.chapter) { $item.chapter } else { "-" }
            $lines += "| $desc | 第${chapter}章 |"
        }
        $lines += ""
    }
    
    if ($plots.Count -gt 0) {
        $lines += "## 剧情事实", "", "| 事实 | 首次出现 |", "|------|----------|"
        foreach ($item in $plots) {
            $desc = if ($item.description) { $item.description } else { "-" }
            $chapter = if ($item.chapter) { $item.chapter } else { "-" }
            $lines += "| $desc | 第${chapter}章 |"
        }
        $lines += ""
    }
    
    $lines | Set-Content "$trackDir\知识库.md" -Encoding UTF8
    Write-Host "  ✓ 知识库.md"
}

Write-Host ""
Write-Host "转换完成!"
