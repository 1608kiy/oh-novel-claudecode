#!/usr/bin/env python3
"""
convert_json_to_md.py — 将 E:\novel 的 JSON 状态文件转换为 Markdown 格式
用法: python convert_json_to_md.py <项目目录>
"""

import json
import sys
import os
from pathlib import Path
from datetime import datetime


def load_json(path):
    """加载 JSON 文件"""
    if not path.exists():
        return None
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"  ⚠ 无法读取 {path}: {e}")
        return None


def convert_progress(data, output_path):
    """progress.json → 追踪/进度.md"""
    if not data:
        return False
    
    lines = ["# 进度\n"]
    lines.append("## 统计\n")
    
    # 统计各状态数量
    status_count = {}
    total = 0
    for ch_num, ch_data in data.items():
        total += 1
        status = ch_data.get('status', 'unknown')
        status_count[status] = status_count.get(status, 0) + 1
    
    lines.append(f"- 总章数: {total}\n")
    for status, count in sorted(status_count.items()):
        lines.append(f"- {status}: {count}\n")
    
    lines.append("\n## 章节状态\n\n")
    lines.append("| 章节 | 状态 | 审查分 | 字数 | 备注 |\n")
    lines.append("|------|------|--------|------|------|\n")
    
    for ch_num in sorted(data.keys(), key=lambda x: int(x) if x.isdigit() else 0):
        ch = data[ch_num]
        status = ch.get('status', '-')
        score = ch.get('review_score', '-')
        word_count = ch.get('word_count', '-')
        notes = ch.get('notes', '')
        lines.append(f"| 第{ch_num}章 | {status} | {score} | {word_count} | {notes} |\n")
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    return True


def convert_foreshadowing(data, output_path):
    """foreshadowing.json → 追踪/伏笔.md"""
    if not data:
        return False
    
    lines = ["# 伏笔追踪\n"]
    
    # 按状态分组
    active = []
    recovered = []
    overdue = []
    
    items = data if isinstance(data, list) else data.get('items', [])
    
    for item in items:
        status = item.get('status', 'active')
        if status == 'recovered' or status == '已回收':
            recovered.append(item)
        elif status == 'overdue' or status == '逾期':
            overdue.append(item)
        else:
            active.append(item)
    
    # 活跃伏笔
    lines.append("## 活跃伏笔\n\n")
    lines.append("| ID | 伏笔 | 播种章节 | 预计回收 | 状态 |\n")
    lines.append("|----|------|---------|---------|------|\n")
    for item in active:
        fid = item.get('id', '-')
        desc = item.get('description', item.get('desc', '-'))
        plant = item.get('plant_chapter', item.get('planted', '-'))
        recover = item.get('recover_chapter', item.get('expected', '-'))
        status = item.get('status', '已播种')
        lines.append(f"| {fid} | {desc} | {plant} | {recover} | {status} |\n")
    
    # 逾期伏笔
    if overdue:
        lines.append("\n## 逾期伏笔\n\n")
        lines.append("| ID | 伏笔 | 播种章节 | 预计回收 | 状态 |\n")
        lines.append("|----|------|---------|---------|------|\n")
        for item in overdue:
            fid = item.get('id', '-')
            desc = item.get('description', item.get('desc', '-'))
            plant = item.get('plant_chapter', item.get('planted', '-'))
            recover = item.get('recover_chapter', item.get('expected', '-'))
            lines.append(f"| {fid} | {desc} | {plant} | {recover} | 逾期 |\n")
    
    # 已回收伏笔
    if recovered:
        lines.append("\n## 已回收伏笔\n\n")
        lines.append("| ID | 伏笔 | 播种章节 | 回收章节 |\n")
        lines.append("|----|------|---------|----------|\n")
        for item in recovered:
            fid = item.get('id', '-')
            desc = item.get('description', item.get('desc', '-'))
            plant = item.get('plant_chapter', item.get('planted', '-'))
            recover = item.get('recover_chapter', item.get('recovered', '-'))
            lines.append(f"| {fid} | {desc} | {plant} | {recover} |\n")
    
    # 统计
    lines.append(f"\n## 统计\n\n")
    lines.append(f"- 活跃: {len(active)} 个\n")
    lines.append(f"- 逾期: {len(overdue)} 个\n")
    lines.append(f"- 已回收: {len(recovered)} 个\n")
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    return True


def convert_character_state(data, output_path):
    """character_state.json → 追踪/角色状态.md"""
    if not data:
        return False
    
    lines = ["# 角色状态\n"]
    
    characters = data if isinstance(data, dict) else data.get('characters', {})
    
    for name, info in characters.items():
        lines.append(f"\n## {name}\n\n")
        if isinstance(info, dict):
            for key, value in info.items():
                if isinstance(value, (list, dict)):
                    continue
                lines.append(f"- {key}: {value}\n")
        else:
            lines.append(f"- 状态: {info}\n")
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    return True


def convert_knowledge(data, output_path):
    """knowledge.json → 追踪/知识库.md"""
    if not data:
        return False
    
    lines = ["# 知识库\n"]
    lines.append("> 累积的故事事实\n\n")
    
    # 按类型分组
    categories = {
        'character': '角色事实',
        'setting': '设定事实',
        'plot': '剧情事实',
    }
    
    items = data if isinstance(data, list) else data.get('items', [])
    
    for cat_key, cat_name in categories.items():
        cat_items = [i for i in items if i.get('type') == cat_key]
        if cat_items:
            lines.append(f"## {cat_name}\n\n")
            lines.append("| 事实 | 首次出现 |\n")
            lines.append("|------|----------|\n")
            for item in cat_items:
                desc = item.get('description', item.get('desc', '-'))
                chapter = item.get('chapter', '-')
                lines.append(f"| {desc} | 第{chapter}章 |\n")
            lines.append("\n")
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    return True


def main():
    if len(sys.argv) < 2:
        print("用法: python convert_json_to_md.py <项目目录>")
        print("示例: python convert_json_to_md.py E:\\novel")
        sys.exit(1)
    
    project_dir = Path(sys.argv[1])
    
    if not project_dir.exists():
        print(f"错误: 目录不存在 {project_dir}")
        sys.exit(1)
    
    # 查找书名目录（包含 state/ 的目录）
    state_dir = None
    for d in project_dir.rglob('state'):
        if d.is_dir() and (d / 'progress.json').exists():
            state_dir = d
            break
    
    if not state_dir:
        # 尝试直接查找
        if (project_dir / 'state' / 'progress.json').exists():
            state_dir = project_dir / 'state'
        elif (project_dir / 'progress.json').exists():
            state_dir = project_dir
    
    if not state_dir:
        print("错误: 找不到 progress.json")
        print("请确保项目目录包含 state/progress.json 或 progress.json")
        sys.exit(1)
    
    # 追踪目录
    track_dir = state_dir.parent / '追踪'
    track_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"项目目录: {project_dir}")
    print(f"状态目录: {state_dir}")
    print(f"追踪目录: {track_dir}")
    print()
    
    # 转换
    conversions = [
        ('progress.json', '进度.md', convert_progress),
        ('foreshadowing.json', '伏笔.md', convert_foreshadowing),
        ('character_state.json', '角色状态.md', convert_character_state),
        ('knowledge.json', '知识库.md', convert_knowledge),
    ]
    
    success = 0
    for json_name, md_name, convert_func in conversions:
        json_path = state_dir / json_name
        md_path = track_dir / md_name
        
        if json_path.exists():
            data = load_json(json_path)
            if data and convert_func(data, md_path):
                print(f"  ✓ {json_name} → {md_name}")
                success += 1
            else:
                print(f"  ✗ {json_name} → 转换失败")
        else:
            print(f"  - {json_name} (不存在，跳过)")
    
    print(f"\n转换完成: {success}/{len(conversions)} 个文件")
    
    if success > 0:
        print(f"\n追踪文件已保存到: {track_dir}")
        print("请检查转换结果，确认无误后可删除原 JSON 文件。")


if __name__ == '__main__':
    main()
