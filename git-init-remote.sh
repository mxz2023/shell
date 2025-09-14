#!/bin/bash

# 脚本名称: git-init-remote
# 描述: 将本地项目初始化并关联到远程 Git 仓库
# 用法: ./git-init-remote.sh [远程仓库URL]

# 显示彩色输出的函数
print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

print_yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

print_red() {
    echo -e "\033[0;31m$1\033[0m"
}

# 检查是否已经安装 Git
if ! command -v git &> /dev/null; then
    print_red "错误: Git 未安装，请先安装 Git"
    exit 1
fi

# 检查当前目录是否已经是 Git 仓库
if [ -d ".git" ]; then
    print_yellow "当前目录已经是 Git 仓库"
else
    print_yellow "初始化 Git 仓库..."
    git init
    if [ $? -ne 0 ]; then
        print_red "Git 初始化失败"
        exit 1
    fi
    print_green "Git 仓库初始化成功"
fi

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    print_yellow "检测到未提交的更改，正在添加所有文件..."
    git add .
    
    print_yellow "正在创建初始提交..."
    git commit -m "初始提交"
    if [ $? -ne 0 ]; then
        print_red "提交失败，请检查 Git 配置"
        print_yellow "提示: 可能需要设置用户名和邮箱:"
        print_yellow "git config --global user.name \"你的名字\""
        print_yellow "git config --global user.email \"你的邮箱\""
        exit 1
    fi
    print_green "初始提交创建成功"
else
    print_yellow "没有检测到需要提交的更改"
fi

# 处理远程仓库 URL
REMOTE_URL=$1

if [ -z "$REMOTE_URL" ]; then
    print_yellow "未提供远程仓库 URL，请输入远程仓库 URL:"
    read -r REMOTE_URL
    
    if [ -z "$REMOTE_URL" ]; then
        print_red "未提供远程仓库 URL，退出"
        exit 1
    fi
fi

# 检查是否已经有远程仓库
if git remote | grep -q "origin"; then
    print_yellow "远程仓库 'origin' 已存在，正在更新 URL..."
    git remote set-url origin "$REMOTE_URL"
else
    print_yellow "添加远程仓库..."
    git remote add origin "$REMOTE_URL"
fi

print_green "远程仓库设置成功: $REMOTE_URL"

# 获取当前分支名称
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)

# 如果没有分支（新仓库），则创建一个默认分支
if [ -z "$CURRENT_BRANCH" ]; then
    # 检查 Git 版本，以确定默认分支名称
    GIT_VERSION=$(git --version | awk '{print $3}')
    DEFAULT_BRANCH="main"
    
    # Git 2.28.0 之前的版本默认是 master
    if [ "$(printf '%s\n' "2.28.0" "$GIT_VERSION" | sort -V | head -n1)" = "2.28.0" ]; then
        DEFAULT_BRANCH="master"
    fi
    
    print_yellow "未检测到分支，正在创建默认分支 '$DEFAULT_BRANCH'..."
    git checkout -b $DEFAULT_BRANCH
    CURRENT_BRANCH=$DEFAULT_BRANCH
fi

print_yellow "当前分支: $CURRENT_BRANCH"

# 检查远程仓库是否存在
git ls-remote --exit-code origin &>/dev/null
REMOTE_EXISTS=$?

# 推送到远程仓库
print_yellow "是否要推送到远程仓库? (y/n)"
read -r PUSH_CONFIRM

if [ "$PUSH_CONFIRM" = "y" ] || [ "$PUSH_CONFIRM" = "Y" ]; then
    # 如果远程仓库存在，先检查是否有冲突
    if [ $REMOTE_EXISTS -eq 0 ]; then
        print_yellow "正在检查远程仓库状态..."
        
        # 尝试推送，但不要真正推送，只是检查是否会成功
        PUSH_TEST=$(git push -n origin $CURRENT_BRANCH 2>&1)
        
        # 如果远程仓库有内容且与本地不同步
        if echo "$PUSH_TEST" | grep -q "rejected" || echo "$PUSH_TEST" | grep -q "non-fast-forward"; then
            print_yellow "远程仓库已有内容，与本地不同步。请选择操作:"
            print_yellow "1) 拉取并合并远程更改 (git pull)"
            print_yellow "2) 拉取并变基本地更改 (git pull --rebase)"
            print_yellow "3) 强制推送本地更改 (git push -f) - 警告：这将覆盖远程更改!"
            print_yellow "4) 取消操作"
            read -r CONFLICT_CHOICE
            
            case $CONFLICT_CHOICE in
                1)
                    print_yellow "拉取并合并远程更改..."
                    git pull origin $CURRENT_BRANCH
                    if [ $? -eq 0 ]; then
                        print_yellow "合并成功，正在推送..."
                        git push -u origin $CURRENT_BRANCH
                        if [ $? -eq 0 ]; then
                            print_green "成功推送到远程仓库"
                        else
                            print_red "推送失败，可能需要手动解决冲突"
                        fi
                    else
                        print_red "拉取失败，可能存在合并冲突，需要手动解决"
                    fi
                    ;;
                2)
                    print_yellow "拉取并变基本地更改..."
                    git pull --rebase origin $CURRENT_BRANCH
                    if [ $? -eq 0 ]; then
                        print_yellow "变基成功，正在推送..."
                        git push -u origin $CURRENT_BRANCH
                        if [ $? -eq 0 ]; then
                            print_green "成功推送到远程仓库"
                        else
                            print_red "推送失败，可能需要手动解决冲突"
                        fi
                    else
                        print_red "变基失败，可能存在冲突，需要手动解决"
                    fi
                    ;;
                3)
                    print_yellow "警告：强制推送将覆盖远程更改！确定要继续吗? (y/n)"
                    read -r FORCE_CONFIRM
                    if [ "$FORCE_CONFIRM" = "y" ] || [ "$FORCE_CONFIRM" = "Y" ]; then
                        print_yellow "正在强制推送到远程仓库..."
                        git push -f -u origin $CURRENT_BRANCH
                        if [ $? -eq 0 ]; then
                            print_green "成功强制推送到远程仓库"
                        else
                            print_red "强制推送失败"
                        fi
                    else
                        print_yellow "已取消强制推送"
                    fi
                    ;;
                4)
                    print_yellow "已取消推送操作"
                    ;;
                *)
                    print_yellow "无效选择，已取消推送操作"
                    ;;
            esac
        else
            # 远程仓库存在但没有冲突，可以直接推送
            print_yellow "正在推送到远程仓库..."
            git push -u origin $CURRENT_BRANCH
            if [ $? -eq 0 ]; then
                print_green "成功推送到远程仓库"
            else
                print_red "推送失败，出现意外错误"
            fi
        fi
    else
        # 远程仓库不存在或为空，可以直接推送
        print_yellow "正在推送到远程仓库..."
        git push -u origin $CURRENT_BRANCH
        if [ $? -eq 0 ]; then
            print_green "成功推送到远程仓库"
        else
            print_red "推送失败，请检查远程仓库 URL 是否正确"
        fi
    fi
else
    print_yellow "跳过推送到远程仓库"
    print_yellow "稍后可以使用以下命令推送:"
    print_yellow "git push -u origin $CURRENT_BRANCH"
fi

print_green "Git 仓库初始化和远程关联完成!"