#!/bin/bash
# OpenList Installer for Linux
color_variable() {
    color='\033[0m'
    green='\033[0;32m'
    blue='\033[0;34m'
    red='\033[31m'
    yellow='\033[33m'
    grey='\e[37m'
    pink='\033[38;5;218m'
    cyan='\033[96m'
}

check_permissions(){
    if [ "$EUID" -ne 0 ]; then
        echo -e "$red Please run this script as root. $color"
        exit 1
    fi
}

check_package(){
    package=( "gum" "curl" "unzip" "git" "tar" )
    for pkg in "${package[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            echo -ne "$grey $pkg安装失败！重试... $color \r"
            apt install -y $pkg >/dev/null 2>&1
        else
            echo -ne "$grey $pkg已安装！ $color \r"
        fi
    done
}

choose_download(){
     echo -e "在以下选项中$blue选择任意一个选项$color"
     echo -e "1.使用$blue 克隆资源包仓库 $color安装(官方，不推荐)"
     echo -e "2.使用$blue GitHub克隆 $color安装(官方仓库，推荐)"
     echo -e "3.使用$blue 一键部署脚本 $color安装(官方，推荐)"
     echo -e "4.使用$blue 官方桌面版软件 $color安装(官方，推荐，Linux)"
     read -p ">" install_choice_ol
     case $install_choice_ol in
         1)
             download_apt
             ;;
         2)
             download_github
             ;;
         3)
             clear
             curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && bash install-openlist-v4.sh
             ;;
         4)
             download_github_desktop
             ;;
     esac
}

download_apt(){
    repository=$(gum choose --header="请选择克隆的仓库" "APT" "PPA")
    case $repository in
        APT)
            clear
            test_proxy
            echo -e "$blue[*]正在安装并自动设置 GPG 密钥 $color"
            curl -fsSL "$best_proxy/https://github.com/OpenListTeam/OpenList-APT/releases/latest/download/install-apt.sh" | bash
            echo -e "$blue[*]正在安装Openlist $color"
            if apt install -y openlist >/dev/null 2>&1;then
                echo -e "$green[*]Openlist成功安装！ $color"
                exit 0
            else
                echo -e "$red[!]Openlist安装失败!请尝试更新APT资源包/检查网络流通性  $color"
                exit 1
            fi
            ;;
        PPA)
            clear
            echo -e "$blue[*]正在添加 PPA 仓库$color"
            add-apt-repository ppa:openlist/server
            echo -e "$blue[*]正在更新 APT 资源包... $color"
            gum spin --spinner line --title "Updating APT resources..." -- apt update
            echo -e "$blue[*]正在安装Openlist $color"
            if apt install -y openlist >/dev/null 2>&1;then
                echo -e "$green[*]Openlist成功安装！ $color"
                exit 0
            else
                echo -e "$red[!]Openlist安装失败!请尝试更新APT资源包/检查网络流通性  $color"
                exit 1
            fi
            ;;
    esac
}

create_install_path(){
    echo -ne "$grey正在创建临时目录..."
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p $INSTALL_DIR
    TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -t 'oltmp.XXXXXX')
    if [ -z "$TMP_DIR" ]; then
      echo -e "$red创建临时目录时失败!$color"
      exit 1
    fi
    mkdir -p "$TMP_DIR"
    TMP_ARCHIVE="$TMP_DIR/$sys_package"
}

choose_ol_ver(){
    while true
    do
        owner="OpenListTeam"
        repo="OpenList"
        echo -e "请输入你要下载的Openlist版本"
        echo -e "输入$blue ver $color查看Openlist的所有版本"
        read -p ">" ol_version
        case $ol_version in
            ver)
                curl -s "https://api.github.com/repos/$owner/$repo/tags?per_page=100" | grep -o '"name": "[^"]*"'
                echo -e "按下$blue回车$color回退"
                read
                clear
                ;;
            *)
                search_tag
                break
                ;;
        esac
    done
}

search_tag(){
    owner="OpenListTeam"
    repo="OpenList"
    tag="$ol_version"
    if git ls-remote --tags "https://gh-proxy.com/https://github.com/$owner/$repo.git" | grep -q "refs/tags/$tag$"; then
        echo -e "$green已找到$tag版本的Openlist,即将开始下载...$color"
    else
        echo -e "$red未找到$tag版本的Openlist!$color"
        exit 1
    fi
}

download_github(){
    clear
    sys_info=$(uname -m)
    if [[ "$sys_info" == "aarch64" ]]; then
        sys_package="openlist-linux-arm64.tar.gz"
    elif [[ "$sys_info" == "x86_64" ]]; then
        sys_package="openlist-linux-amd64.tar.gz"
    fi
    create_install_path
    choose_ol_ver
    download_ol
    tar_ol
    install_change_mode
}

download_ol(){
    test_proxy
    echo -e "$blue 开始下载Openlist $ol_version版本！$color"
    if curl -fL "$best_proxy/https://github.com/OpenListTeam/OpenList/releases/download/$ol_version/$sys_package" -o $TMP_ARCHIVE ; then
        echo -e "$blue Openlist已成功下载！$color"
    else
        echo -e "$red 下载时出现错误!$color"
        rm -rf $TMP_DIR
        exit 1
    fi
}

#解压ol
tar_ol(){
    echo -e "$blue 正在解压Openlist..."
    if tar -C "$TMP_DIR" -xf "$TMP_ARCHIVE"; then
        echo -e "$blue 已完成解压操作！$color"
    else
        echo -e "$red 解压时出现错误！$color"
        rm -rf $TMP_DIR
        exit 1
    fi
}

#安装授权
install_change_mode(){
    cp $TMP_DIR/* $INSTALL_DIR/
    chmod 777 $INSTALL_DIR/*
}

test_proxy() {
    PROXIES=(
        "https://ghproxy.net"
        "https://gh-proxy.com"
        "https://gh.llkk.cc"
        "https://ghproxy.cc"
        "https://ghproxy.net"
        "https://ghfast.net"
        "https://ghp.ci"
        "https://moeyy.cn/gh-proxy/"
        "https://ghproxy.homeboyc.cn/"
        "http://toolwa.com/github/"
        "https://v6.gh-proxy.org/"
        "https://gh.aptv.app/"
        "https://gh.qninq.cn/"
        "https://proxy.lalifeier.eu.org"
        "https://ghcy.eu.org/"
    )
    TEST_URL="https://raw.githubusercontent.com/OpenListTeam/OpenList/main/README.md"  
    echo -ne "$grey测试 GitHub 代理中...$color\n"    
    best_proxy=""
    best_time=999999
    valid_count=0    
    for proxy in "${PROXIES[@]}"; do
        result=$(curl -o /dev/null -s -w "%{http_code}|%{time_connect}" \
            --max-time 3 \
            --connect-timeout 2 \
            "$proxy/$TEST_URL" 2>/dev/null)
        http_code=$(echo "$result" | cut -d'|' -f1)
        time=$(echo "$result" | cut -d'|' -f2)
        if [ "$http_code" = "200" ] && [ -n "$time" ] && [ $(echo "$time > 0.05" | bc 2>/dev/null) -eq 1 ]; then
            ms=$(echo "$time * 1000" | bc | cut -d'.' -f1)
            echo "  $proxy - ${ms}ms"
            valid_count=$((valid_count + 1))
            
            if [ "$ms" -lt "$best_time" ]; then
                best_time=$ms
                best_proxy=$proxy
            fi
        else
            echo "  $proxy - FAILED"
        fi
    done
    if [ -n "$best_proxy" ] && [ "$best_time" -lt 999999 ]; then
        echo -e "$green找到$valid_count个可用代理$color"
        echo -e "即将使用 $blue$best_proxy$color (延迟 $best_time) 来下载 openlist!"
    else
        echo -e "$red代理测试失败！没有可用的代理！$color"
        exit 1
    fi
}

choose_oldesktop_ver(){
    mkdir -p "$HOME/Desktop"
    while true
    do
        owner="OpenListTeam"
        repo="OpenList-Desktop"
        echo -e "请输入你要下载的Openlist桌面版本"
        echo -e "输入$blue ver $color查看Openlist桌面版本的所有版本"
        read -p ">" ol_version_desktop
        ol_desktop_true_version="v$ol_version_desktop"
        case $ol_desktop_true_version in
            ver)
                curl -s "https://api.github.com/repos/$owner/$repo/tags?per_page=100" | grep -o '"name": "[^"]*"'
                echo -e "按下$blue回车$color回退"
                read
                clear
                ;;
            *)
                sys_info=$(uname -m)
                if [[ "$sys_info" == "aarch64" ]]; then
                    sys_package="OpenList-Desktop_${ol_version_desktop}_arm64.deb"
                elif [[ "$sys_info" == "x86_64" ]]; then
                    sys_package="OpenList-Desktop_${ol_version_desktop}_amd64.deb"
                fi
                search_tag_desktop
                break
                ;;
        esac
    done
}

search_tag_desktop(){
    owner="OpenListTeam"
    repo="OpenList-Desktop"
    tag="$ol_desktop_true_version"
    if git ls-remote --tags "https://gh-proxy.com/https://github.com/$owner/$repo.git" | grep -q "refs/tags/$tag$"; then
        echo -e "$green已找到$tag版本的Openlist桌面版本,即将开始下载...$color"
    else
        echo -e "$red未找到$tag版本的Openlist桌面版本!$color"
        exit 1
    fi
}

download_github_desktop(){
    clear
    choose_oldesktop_ver
    download_ol_desktop
}

download_ol_desktop(){
    test_proxy
    echo -e "$blue 开始下载Openlist $ol_version版本！$color"
    if curl -L -o "$HOME/Desktop/$sys_package" "$best_proxy/https://github.com/OpenListTeam/OpenList-Desktop/releases/download/$ol_desktop_true_version/$sys_package"; then
        echo -e "$blue Openlist桌面版已成功下载！$color deb文件包存在于$green$HOME/Desktop$color"
    else
        echo -e "$red 下载时出现错误!$color"
        rm -rf $TMP_DIR
        exit 1
    fi
}

color_variable
check_package
choose_download