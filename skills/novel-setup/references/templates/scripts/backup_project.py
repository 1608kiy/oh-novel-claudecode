#!/usr/bin/env python3
"""
backup_project.py — 备份项目状态
用法: python backup_project.py <项目目录> [备份名称]
"""

import sys
import os
import zipfile
from pathlib import Path
from datetime import datetime


def main():
    if len(sys.argv) < 2:
        print("用法: python backup_project.py <项目目录> [备份名称]")
        sys.exit(1)
    
    project_dir = Path(sys.argv[1])
    
    if not project_dir.exists():
        print(f"错误: 目录不存在 {project_dir}")
        sys.exit(1)
    
    # 备份目录
    backup_dir = project_dir / 'backups'
    backup_dir.mkdir(parents=True, exist_ok=True)
    
    # 备份文件名
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    if len(sys.argv) > 2:
        backup_name = f"{sys.argv[2]}_{timestamp}.zip"
    else:
        backup_name = f"backup_{timestamp}.zip"
    
    backup_path = backup_dir / backup_name
    
    # 要备份的目录
    dirs_to_backup = ['正文', '追踪', '大纲', '设定']
    
    print(f"项目目录: {project_dir}")
    print(f"备份路径: {backup_path}")
    print()
    
    with zipfile.ZipFile(backup_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for dir_name in dirs_to_backup:
            dir_path = project_dir / dir_name
            if dir_path.exists():
                for file_path in dir_path.rglob('*'):
                    if file_path.is_file():
                        arcname = file_path.relative_to(project_dir)
                        zf.write(file_path, arcname)
                        print(f"  + {arcname}")
        
        # 备份 CLAUDE.md
        claude_md = project_dir / 'CLAUDE.md'
        if claude_md.exists():
            zf.write(claude_md, 'CLAUDE.md')
            print(f"  + CLAUDE.md")
    
    # 获取备份文件大小
    size = backup_path.stat().st_size
    if size > 1024 * 1024:
        size_str = f"{size / 1024 / 1024:.1f} MB"
    elif size > 1024:
        size_str = f"{size / 1024:.1f} KB"
    else:
        size_str = f"{size} B"
    
    print(f"\n备份完成: {backup_name} ({size_str})")


if __name__ == '__main__':
    main()
