#!/bin/bash
#由CAPHA-Hoshino Ai写的AstrBot安装脚本
#程序：Astrbot

#颜色处理
color(){
blue='\033[0;34m'
red='\033[1;31m'
yellow='\033[1;33m'
color='\033[0m'
}
clear

check_package_category(){
    #检查pkg指令
    if command -v pkg >/dev/null 2>&1; then
        package_category=pkg
    else
        echo -e "$red 未知的软件包/不兼容的软件包!"
        exit 0
    fi
}
check_package(){
    #检查软件包的更新
    echo -e "$blue 当前软件包:$package_category"
    echo -e "$blue 正在检查$package_category软件包的更新"
    sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main@' $PREFIX/etc/apt/sources.list
    $package_category update >/dev/null 2>&1 && $package_category upgrade -y >/dev/null 2>&1
    #下载proot-distro软件包
    echo -e "$blue 检查完成！正在下载必要的软件包"
    if $package_category install proot -y >/dev/null 2>&1; then
        echo -e "$blue 你已成功下载了必要的资源包-proot！"
    else
        echo -e "$red 下载时出现错误！"
        exit 1
    fi
    if $package_category install python -y >/dev/null 2>&1; then
        echo -e "$blue 你已成功下载了必要的资源包-Python！"
    else
        echo -e "$red 下载时出现错误！"
        exit 1
    fi
    if pip install proot-distro==5.0.0 >/dev/null 2>&1; then
        echo -e "$blue 你已成功下载了必要的资源包-proot-distro！"
    else
        echo -e "$red 下载时出现错误！"
        exit 1
    fi
}

proot_download(){
    #安装Ubuntu最新版本并且改名为astrbot
    proot-distro install ubuntu 
    proot-distro rename ubuntu astrbot
    proot-distro login astrbot -- bash -c 'echo "export PATH="$HOME/.local/bin:$PATH"" >> $HOME/.bashrc'
    proot-distro login astrbot -- bash -c 'command' 
}

uv_install(){
    #在容器中下载并安装uv0.10.1版本
    echo -e "$blue 开始下载uv$color"
    proot-distro login astrbot -- bash -c 'echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> $HOME/.bashrc'
    proot-distro login astrbot -- bash -c '
    if [ -f "$HOME/.local/bin/uv" ];then
        echo -e "$blue uv已安装，跳过下载"
    else
        curl -LsSf "https://raw.gitcode.com/Cyrene-Castorice/Capha-Script/raw/main/uv-installer-for-astrbot-termux.sh" | sh
    fi'
    proot-distro login astrbot -- bash -c 'export PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc'
    proot-distro login astrbot -- bash -c 'source $HOME/.bashrc'
}

astrbot_download(){
    echo -e "$blue 正在切换阿里云pip源$color"
    proot-distro login astrbot -- bash -c 'pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/'
    proot-distro login astrbot -- bash -c 'pip config set install.trusted-host mirrors.aliyun.com'
    echo -e "$blue 正在使用$(proot-distro login astrbot -- bash -c '$HOME/.local/bin/uv --version')下载astrbot..."
    #启用venv环境
    echo -e "$blue 开始添加$green venv(virtualenv) $color环境并应用..."
    proot-distro login astrbot -- bash -c '$HOME/.local/bin/uv venv'
    proot-distro login astrbot -- bash -c 'source .venv/bin/activate'
    #切换uv的下载方式为复制
    echo -e "$blue 正在安装最稳定版本$green astrbot==4.22.2 $color"
    proot-distro login astrbot -- bash -c 'echo "export UV_LINK_MODE=copy" >> $HOME/.bashrc && $HOME/.local/bin/uv tool install astrbot==4.22.2'
    echo -e "$blue 正在初始化astrbot...$color"
    if proot-distro login astrbot -- bash -c '$HOME/.local/bin/uv tool run astrbot init' ; then
        echo -e "$blue 初始化astrbot成功！$color"
    else
        echo -e "$red 初始化失败！$color"
        exit 1
    fi
    echo -e "$blue 输入proot-distro login astrbot以进入容器！"
    echo -e "$blue 在容器内输入astrbot run即可运行！"
}

color
check_package_category
check_package
proot_download
uv_install
astrbot_download