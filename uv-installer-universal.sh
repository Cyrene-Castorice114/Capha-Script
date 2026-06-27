#!/bin/bash

color(){
cyan='\033[96m'
blue='\033[0;34m'
red='\033[1;31m'
yellow='\033[1;33m'
color='\033[0m'
}

check_system_package(){
    if command -v pkg >/dev/null 2>&1; then
        system_install="apt install"
        system="Termux"
    elif command -v apt >/dev/null 2>&1; then
        system_install="apt install"
        system="Debian/Ubuntu"
    elif command -v pacman >/dev/null 2>&1; then
        system_install="pacman -S"
        system="Arch Linux"
    elif command -v yum >/dev/null 2>&1; then
        system_install="yum install"
        system="CentOS/RHEL"
    elif command -v dnf >/dev/null 2>&1; then
        system_install="dnf install"
        system="Fedora"
    else
        echo -e "$red 未检测到支持的包管理器，请手动安装所需依赖项。$color"
        exit 1
    fi
}

check_package(){
    echo -e "$blue 检测到系统为 $system$color"
    echo -ne "$grey正在检查必要的资源包$color \r"
    package=( "curl" "mkdir" "cp" "chmod" "mktemp" "rm" "tar" )
    for pkg in ${package[@]};do
        if command -v $pkg >/dev/null 2>&1; then
            echo -ne "$grey检查到$pkg!已跳过安装... \r"
        else
            echo -ne "$grey缺失$pkg!即将安装... \r"
            $system_install $pkg -y >/dev/null 2>&1
        fi
    done
}

check_sys(){
    if [[ "$(uname -m)" == "x86_64" ]];then
        sys_pkg=uv-x86_64-unknown-linux-gnu.tar.gz
    elif [[ "$(uname -m)" == "aarch64" ]];then
        sys_pkg=uv-aarch64-unknown-linux-gnu.tar.gz
    else
        echo -e "$red未知的系统版本!$color"
        exit 0
    fi    
}

create_install_path(){
    echo -ne "$grey正在创建临时目录..."
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p $INSTALL_DIR
    TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -t 'uvtmp.XXXXXX')
    if [ -z "$TMP_DIR" ]; then
      echo -e "$red创建临时目录时失败!$color"
      exit 1
    fi
    mkdir -p "$TMP_DIR"
    TMP_ARCHIVE="$TMP_DIR/$sys_pkg"
}

choose_uv_ver(){
    while true
    do
        owner="astral-sh"
        repo="uv"
        echo -e "请输入你要下载的uv版本"
        echo -e "输入$blue ver $color查看uv的所有版本"
        read -p ">" uv_version
        case $uv_version in
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
    owner="astral-sh"
    repo="uv"
    tag="$uv_version"
    if git ls-remote --tags "https://gh-proxy.com/https://github.com/$owner/$repo.git" | grep -q "refs/tags/$tag$"; then
        echo -e "$green已找到$tag版本的uv,即将开始下载...$color"
    else
        echo -e "$red未找到$tag版本的uv!$color"
        exit 1
    fi
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
    TEST_URL="https://raw.githubusercontent.com/astral-sh/uv/main/README.md"  
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
        echo -e "即将使用 $blue$best_proxy$color (延迟 $best_time) 来下载 uv!"
    else
        echo -e "$red代理测试失败！没有可用的代理！$color"
        exit 1
    fi
}

#下载uv
download_uv(){
    echo -e "$blue 开始下载uv v$uv_version版本！$color"
    if curl -fL "$best_proxy/https://github.com/astral-sh/uv/releases/download/$uv_version/$sys_pkg" -o $TMP_ARCHIVE ; then
        echo -e "$blue uv已成功下载！$color"
    else
        echo -e "$red 下载时出现错误!$color"
        rm -rf $TMP_DIR
        exit 1
    fi
}

#解压uv
tar_uv(){
    echo -e "$blue 正在解压uv..."
    if tar -C "$TMP_DIR" -xf "$TMP_ARCHIVE" --strip-components 1; then
        echo -e "$blue 已完成解压操作！$color"
    else
        echo -e "$red 解压时出现错误！$color"
        rm -rf $TMP_DIR
        exit 1
    fi
}

#安装授权
install_change_mode(){
    cp $TMP_DIR/uv $TMP_DIR/uvx $INSTALL_DIR/
    chmod 777 $INSTALL_DIR/uv $INSTALL_DIR/uvx
}

end(){
   if ! grep -q "$INSTALL_DIR" $HOME/.bashrc; then
       echo "export PATH=$INSTALL_DIR:\$PATH" >> $HOME/.bashrc
       source $HOME/.bashrc
       echo -e "$blue 已自动配置到：uv$color"
   fi
   rm -rf $TMP_DIR
}

color
check_system_package
check_package
check_sys
create_install_path
choose_uv_ver
test_proxy
download_uv
tar_uv
install_change_mode
end