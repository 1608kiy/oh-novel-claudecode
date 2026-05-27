#!/usr/bin/env python3
"""
export_chapters.py — 导出章节为单个文件
用法: python export_chapters.py <项目目录> [选项]

选项:
  --all           导出所有已接受的章节
  --volume N      导出第N卷
  --range X-Y     导出第X章到第Y章
  --format FORMAT 输出格式 (md/txt)
  --output PATH   输出路径
"""

import sys
import os
import re
import argparse
from pathlib import Path


def find_chapters(text_dir):
    """查找所有章节文件"""
    chapters = {}
    if not text_dir.exists():
        return chapters
    
    for file_path in text_dir.glob('第*章*.md'):
        # 提取章节号
        match = re.match(r'第(\d+)章', file_path.name)
        if match:
            chapter_num = int(match.group(1))
            chapters[chapter_num] = file_path
    
    return chapters


def read_chapter(file_path):
    """读取章节内容"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 去除 Markdown 标记
        lines = content.split('\n')
        result = []
        for line in lines:
            # 去除标题的 # 符号
            if line.startswith('# '):
                result.append(line[2:])
            elif line.startswith('## '):
                result.append(line[3:])
            else:
                result.append(line)
        
        return '\n'.join(result)
    except Exception as e:
        print(f"  ⚠ 读取失败 {file_path}: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(description='导出章节为单个文件')
    parser.add_argument('project_dir', help='项目目录')
    parser.add_argument('--all', action='store_true', help='导出所有章节')
    parser.add_argument('--volume', type=int, help='导出第N卷')
    parser.add_argument('--range', type=str, help='导出范围 (如 1-10)')
    parser.add_argument('--format', default='md', choices=['md', 'txt'], help='输出格式')
    parser.add_argument('--output', type=str, help='输出路径')
    
    args = parser.parse_args()
    
    project_dir = Path(args.project_dir)
    if not project_dir.exists():
        print(f"错误: 目录不存在 {project_dir}")
        sys.exit(1)
    
    # 查找书名目录（包含 正文/ 的目录）
    text_dir = None
    for d in project_dir.rglob('正文'):
        if d.is_dir():
            text_dir = d
            break
    
    if not text_dir:
        print("错误: 找不到 正文/ 目录")
        sys.exit(1)
    
    book_dir = text_dir.parent
    book_name = book_dir.name
    
    # 查找所有章节
    all_chapters = find_chapters(text_dir)
    
    if not all_chapters:
        print("错误: 没有找到章节文件")
        sys.exit(1)
    
    print(f"项目: {book_name}")
    print(f"总章数: {len(all_chapters)}")
    
    # 确定导出范围
    if args.all:
        chapters = all_chapters
        range_desc = "全部"
    elif args.volume:
        # 假设每卷40章
        start = (args.volume - 1) * 40 + 1
        end = args.volume * 40
        chapters = {k: v for k, v in all_chapters.items() if start <= k <= end}
        range_desc = f"第{args.volume}卷"
    elif args.range:
        parts = args.range.split('-')
        if len(parts) == 2:
            start, end = int(parts[0]), int(parts[1])
            chapters = {k: v for k, v in all_chapters.items() if start <= k <= end}
            range_desc = f"第{start}-{end}章"
        else:
            print("错误: --range 格式应为 X-Y")
            sys.exit(1)
    else:
        # 默认导出所有
        chapters = all_chapters
        range_desc = "全部"
    
    if not chapters:
        print(f"错误: 指定范围内没有章节")
        sys.exit(1)
    
    print(f"导出范围: {range_desc} ({len(chapters)} 章)")
    
    # 确定输出路径
    if args.output:
        output_path = Path(args.output)
    else:
        output_dir = project_dir / 'output'
        output_dir.mkdir(parents=True, exist_ok=True)
        
        ext = '.txt' if args.format == 'txt' else '.md'
        if args.volume:
            filename = f"{book_name}_第{args.volume}卷{ext}"
        elif args.range:
            filename = f"{book_name}_{args.range}{ext}"
        else:
            filename = f"{book_name}_全文{ext}"
        
        output_path = output_dir / filename
    
    # 合并章节
    print(f"\n导出中...")
    
    total_chars = 0
    with open(output_path, 'w', encoding='utf-8') as f:
        # 写入标题
        f.write(f"# {book_name}\n\n")
        
        for chapter_num in sorted(chapters.keys()):
            file_path = chapters[chapter_num]
            content = read_chapter(file_path)
            
            if content:
                f.write(content)
                f.write('\n\n')
                
                # 统计字数
                chars = len(content.replace('\n', '').replace(' ', ''))
                total_chars += chars
                print(f"  ✓ 第{chapter_num}章 ({chars} 字)")
    
    # 输出统计
    size = output_path.stat().st_size
    if size > 1024 * 1024:
        size_str = f"{size / 1024 / 1024:.1f} MB"
    elif size > 1024:
        size_str = f"{size / 1024:.1f} KB"
    else:
        size_str = f"{size} B"
    
    print(f"\n导出完成: {output_path}")
    print(f"总字数: {total_chars}")
    print(f"文件大小: {size_str}")


if __name__ == '__main__':
    main()
