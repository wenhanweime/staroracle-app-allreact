#!/usr/bin/env python3
"""
Project Change Tracker - 增量记录版
===================================
智能记录项目改动，基于Git暂存区实现增量记录。

工作原理：
每次运行时检测【工作区 vs 暂存区】的差异（即新的改动），
记录完成后自动git add为下次记录做准备，形成改动链条。

功能：
1. 智能检测自上次记录以来的新改动
2. 增量记录，避免重复记录已记录的内容
3. 保存文件的完整内容，并标注改动位置
4. 将结果按版本号追加到 change_log.md
5. 自动复制改动内容到粘贴板
6. 自动git add为下次记录做准备

使用方法：
    python record_changes.py
    
    或使用快捷命令：/diff
    
工作流程：
第1次: 检测所有改动 → 记录 → git add（准备）
第2次: 检测新改动 → 记录 → git add（准备）  
第N次: 检测新改动 → 记录 → git add（准备）
"""

import os
import subprocess
import datetime
import re
import platform
from pathlib import Path

# 配置
ROOT_DIR = Path(__file__).parent.resolve()
LOG_FILE = ROOT_DIR / "change_log.md"


def run_cmd(cmd: str) -> str:
    """运行 shell 命令并返回输出"""
    return subprocess.check_output(cmd, shell=True, text=True).strip()


def get_changed_files() -> list[str]:
    """检测自上次git add以来的新改动（增量记录）"""
    try:
        print("🔍 检测自上次记录以来的新改动...")
        
        # 检测工作区相对于暂存区的改动（新的改动）
        diff_cmd = "git diff --name-only"
        diff_output = run_cmd(diff_cmd)
        
        # 同时检测未跟踪的新文件
        untracked_cmd = "git ls-files --others --exclude-standard"
        untracked_output = run_cmd(untracked_cmd)
        
        changed_files = []
        
        # 添加修改过的文件
        if diff_output:
            changed_files.extend(diff_output.splitlines())
        
        # 添加新文件，但过滤掉不需要的文件
        if untracked_output:
            for file_path in untracked_output.splitlines():
                # 跳过日志文件、临时文件等
                if not any(skip in file_path for skip in [
                    'change_log.md', '.log', 'node_modules/', 'dist/', '.DS_Store', 
                    '.git/', '__pycache__/', '*.pyc', '.tmp'
                ]):
                    changed_files.append(file_path)
        
        # 处理文件名编码问题：尝试解码带引号的文件名
        decoded_files = []
        for file_path in changed_files:
            if file_path.startswith('"') and file_path.endswith('"'):
                try:
                    # 去掉引号并尝试解码
                    unquoted = file_path[1:-1]
                    # 尝试将八进制编码转换为实际文件名
                    import codecs
                    decoded = codecs.decode(unquoted, 'unicode_escape').encode('latin1').decode('utf-8')
                    # 验证解码后的文件是否真实存在
                    if (ROOT_DIR / decoded).exists():
                        decoded_files.append(decoded)
                        continue
                except:
                    pass
            # 如果解码失败或不需要解码，保持原文件名
            decoded_files.append(file_path)
        
        changed_files = list(set(decoded_files))
        
        if not changed_files:
            print("✅ 没有检测到新的改动")
            return []
        
        print(f"📝 检测到 {len(changed_files)} 个新改动的文件:")
        for file_path in changed_files:
            print(f"   - {file_path}")
        
        return changed_files
            
    except Exception as e:
        print(f"❌ 检测改动文件时出错: {e}")
        return []


def get_file_content(file_path: Path) -> str:
    """读取文件的完整内容"""
    try:
        return file_path.read_text(encoding="utf-8")
    except Exception as e:
        return f"<<无法读取文件: {e}>>"


def get_file_diff(file_path: Path) -> str:
    """获取文件的改动 diff（工作区 vs 暂存区）"""
    try:
        # 首先尝试检测工作区相对于暂存区的差异
        diff_cmd = f"git diff -- {file_path}"
        diff_output = run_cmd(diff_cmd)
        
        # 如果没有差异，可能是新文件，检测相对于HEAD的差异
        if not diff_output.strip():
            diff_cmd = f"git diff HEAD -- {file_path}"
            diff_output = run_cmd(diff_cmd)
            
        return diff_output
    except subprocess.CalledProcessError:
        return "<<无 diff>>"


def get_next_version_number() -> int:
    """获取下一个版本号"""
    if not LOG_FILE.exists():
        return 0
    
    content = LOG_FILE.read_text(encoding="utf-8")
    # 匹配版本号模式: ## 🔥 VERSION 001 📝
    pattern = r"## 🔥 VERSION (\d+) 📝"
    matches = re.findall(pattern, content)
    
    if matches:
        return max(int(match) for match in matches) + 1
    return 0


def copy_to_clipboard(content: str) -> bool:
    """复制内容到粘贴板，跨平台支持"""
    try:
        system = platform.system()
        
        if system == "Darwin":  # macOS
            subprocess.run(["pbcopy"], input=content, text=True, check=True)
        elif system == "Windows":
            subprocess.run(["clip"], input=content, text=True, check=True)
        elif system == "Linux":
            # 尝试多种Linux剪贴板工具
            try:
                subprocess.run(["xclip", "-selection", "clipboard"], input=content, text=True, check=True)
            except FileNotFoundError:
                try:
                    subprocess.run(["xsel", "--clipboard", "--input"], input=content, text=True, check=True)
                except FileNotFoundError:
                    return False
        else:
            return False
        
        return True
    except subprocess.CalledProcessError:
        return False


def format_file_section(file_path: Path) -> str:
    """格式化单个文件的输出部分"""
    rel_path = file_path.relative_to(ROOT_DIR)
    header = f"### 📄 {rel_path}\n"
    content = f"```{file_path.suffix.lstrip('.')}\n{get_file_content(file_path)}\n```\n"
    diff = get_file_diff(file_path)

    if diff.strip():
        diff_section = f"**改动标注：**\n```diff\n{diff}\n```\n"
    else:
        diff_section = "_无改动_\n"

    return f"{header}\n{content}\n{diff_section}"


def main():
    changed_files = get_changed_files()
    if not changed_files:
        print("✅ 没有检测到改动。")
        return

    version_num = get_next_version_number()
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 构建文件列表
    valid_files = []
    for file in changed_files:
        file_path = ROOT_DIR / file
        if file_path.exists():
            valid_files.append(file)
    
    # 构建概要信息
    files_summary = "、".join([f"`{file}`" for file in valid_files])
    summary_section = f"\n**本次修改的文件共 {len(valid_files)} 个，分别是：{files_summary}**\n"
    
    # 构建版本头部
    section_header = f"\n\n---\n## 🔥 VERSION {version_num:03d} 📝\n**时间：** {timestamp}\n{summary_section}"

    # 构建详细文件内容
    sections = []
    for file in valid_files:
        file_path = ROOT_DIR / file
        sections.append(format_file_section(file_path))

    # 构建完整的新增内容
    full_content = section_header + "\n".join(sections)
    
    # 复制到粘贴板
    copy_success = copy_to_clipboard(full_content)
    
    # 写入文件（新内容追加到顶部）
    if LOG_FILE.exists():
        # 读取现有内容
        existing_content = LOG_FILE.read_text(encoding="utf-8")
        # 将新内容写入到顶部
        with open(LOG_FILE, "w", encoding="utf-8") as f:
            f.write(full_content + existing_content)
    else:
        # 文件不存在，直接创建
        with open(LOG_FILE, "w", encoding="utf-8") as f:
            f.write(full_content)

    # 记录完成后，将改动添加到暂存区为下次记录做准备
    print("🔄 添加改动到暂存区，为下次记录做准备...")
    try:
        success_count = 0
        for file in changed_files:
            try:
                # 尝试多种方式添加文件
                file_path = ROOT_DIR / file
                if file_path.exists():
                    # 使用相对路径添加文件
                    run_cmd(f'git add "{file_path.relative_to(ROOT_DIR)}"')
                    success_count += 1
                    print(f"   ✓ {file}")
                else:
                    # 如果文件不存在，可能是编码问题，尝试使用通配符
                    print(f"   ⚠ {file}: 文件不存在或编码问题，跳过")
            except Exception as file_error:
                print(f"   ✗ {file}: {file_error}")
        print(f"✅ 成功添加 {success_count}/{len(changed_files)} 个文件到暂存区")
    except Exception as e:
        print(f"⚠️ 添加到暂存区时出错: {e}")

    # 输出结果
    if copy_success:
        print(f"✅ 本次改动已记录到 {LOG_FILE}")
        print(f"📋 改动内容已复制到粘贴板 ({len(full_content)} 字符)")
    else:
        print(f"✅ 本次改动已记录到 {LOG_FILE}")
        print(f"⚠️ 无法复制到粘贴板，请手动复制文件内容")


if __name__ == "__main__":
    main()
