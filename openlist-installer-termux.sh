#!/bin/bash

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

check_package(){
    echo -ne "${grey}正在检查必要的软件包${color} \r"
    package=( "gum" "tar" "curl" "unzip" "chmod" )
    for pkg in "${package[@]}";do
        if command -v $pkg >/dev/null 2&>1;then
            echo -ne "${grey}$pkg已安装！ ${color} \r"
        else
            echo -ne "${grey}$pkg未安装！开始安装... ${color} \r"
            if apt install -y $pkg >/dev/null 2>&1;then
                echo -ne "${grey}$pkg安装成功！ ${color}     \r"
            else
                echo -ne "${blue}$pkg安装失败！${red}请检查网络状态/apt(pkg)软件包状态 ${color} \r"
            fi
        fi
    done
}

download_openlist(){
    echo -e "请选择你下载OpenList的方式:"
    echo -e "1.使用${blue}apt软件包$color下载"
    echo -e "2.使用${blue}GitHub克隆$color下载"
    echo -e "3.使用${blue}一键安装脚本$color下载"
    read -p ">" download_openlist_choice
    case $download_openlist_choice in
        1)
            clear
            package_install
            ;;
        2)
            clear
            install_github
            echo -e "使用${pink}./openlist help$color即可查看帮助界面!"
            ;;
        3)
            clear
            curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && bash install-openlist-v4.sh && rm -rf install-openlist-v4.sh
            ;;
    esac
}

package_install(){
    if command -v openlist >/dev/null 2>&1; then
        echo -e "你已安装了Openlist,$green是否覆盖安装？$color"
        echo -e "$red这将会清除你原先的所有内容!"
        cover_download=$(gum choose --header="覆盖下载?" "yes" "no")
        case $cover_download in
            yes)
                echo -e "正在删除现有的OpenList..."
                if apt remove openlist -y >/dev/null 2>&1;then
                    echo -e "旧版本OpenList${green}已完全移除"
                else
                    echo -e "$red卸载OpenList失败！$color"
                    exit 1
                fi
                echo -e "$green开始安装OpenList$color"
                if apt install openlist -y >/dev/null 2>&1;then
                    echo -e "OpenList${green}已安装!输入${pink}openlist server$green运行$color"
                else
                    echo -e "$red安装OpenList失败！请检查apt(pkg)软件包的版本状态或者网络状态!$color"
                    exit 1
                fi
            ;;
        esac
    else
        echo -e "$green开始安装OpenList$color"
        if apt install openlist -y >/dev/null 2>&1;then
            echo -e "OpenList${green}已安装!输入${pink}openlist server$green运行$color"
        else
            echo -e "$red安装OpenList失败！请检查apt(pkg)软件包的版本状态或者网络状态!$color"
            exit 1
        fi
    fi
}

install_github(){
    clear
    sys_info=$(uname -m)
    if [[ "$sys_info" == "aarch64" ]]; then
        sys_package="openlist-android-arm64.tar.gz"
    elif [[ "$sys_info" == "x86_64" ]]; then
        sys_package="openlist-android-amd64.tar.gz"
    fi
    create_install_path
    choose_ol_ver
    download_ol
    tar_ol
    install_change_mode
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

color_variable
check_package
download_openlist