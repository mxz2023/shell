#!/bin/bash

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

# 检查脚本是否存在
if [ ! -f "git-init-remote.sh" ]; then
    print_red "错误: git-init-remote.sh 脚本不存在"
    exit 1
fi

print_yellow "请选择安装方式:"
print_yellow "1) 安装到系统目录 (/usr/local/bin) - 需要管理员权限"
print_yellow "2) 安装到个人目录 (~/bin) - 仅当前用户可用"
print_yellow "3) 取消安装"
read -r INSTALL_CHOICE

case $INSTALL_CHOICE in
    1)
        print_yellow "正在安装到系统目录..."
        
        # 检查是否有 sudo 权限
        if ! command -v sudo &> /dev/null; then
            print_red "错误: 需要 sudo 命令来安装到系统目录"
            exit 1
        fi
        
        # 复制脚本到 /usr/local/bin
        sudo cp git-init-remote.sh /usr/local/bin/git-init-remote
        
        # 设置执行权限
        sudo chmod +x /usr/local/bin/git-init-remote
        
        if [ $? -eq 0 ]; then
            print_green "安装成功！现在你可以在任何目录下运行 'git-init-remote' 命令"
            print_green "也可以作为 Git 子命令运行: 'git init-remote'"
        else
            print_red "安装失败，请检查权限"
        fi
        ;;
        
    2)
        print_yellow "正在安装到个人目录..."
        
        # 创建个人 bin 目录（如果不存在）
        mkdir -p ~/bin
        
        # 复制脚本到 ~/bin
        cp git-init-remote.sh ~/bin/git-init-remote
        
        # 设置执行权限
        chmod +x ~/bin/git-init-remote
        
        # 检查 PATH 中是否已包含 ~/bin
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            # 根据当前 shell 添加到相应的配置文件
            if [ -f ~/.zshrc ]; then
                echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
                print_yellow "已将 ~/bin 添加到 PATH (在 ~/.zshrc 中)"
                print_yellow "请运行 'source ~/.zshrc' 或重新打开终端使其生效"
            elif [ -f ~/.bashrc ]; then
                echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
                print_yellow "已将 ~/bin 添加到 PATH (在 ~/.bashrc 中)"
                print_yellow "请运行 'source ~/.bashrc' 或重新打开终端使其生效"
            else
                print_yellow "请手动将 ~/bin 添加到你的 PATH 环境变量中"
            fi
        fi
        
        print_green "安装成功！在 PATH 更新后，你可以在任何目录下运行 'git-init-remote' 命令"
        ;;
        
    3)
        print_yellow "已取消安装"
        ;;
        
    *)
        print_red "无效选择，已取消安装"
        ;;
esac