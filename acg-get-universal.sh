#!/bin/bash
#手机图片来源于API：https://www.loliapi.com/acg/pe
#电脑图片来源于API：https://www.loliapi.com/acg/pc
#脚本由Cyrene（即CAPHA-Hoshino Ai/HA-Hoshino-Ai）制作

PIC_API_AND=https://www.loliapi.com/acg/pe
PIC_API_PC=https://www.loliapi.com/acg/pc
check_dir(){
    while true
    do
        if [ -d "$HOME/.capha/acg" ];then
            echo -ne "$grey检测到PATH目录:$HOME/.capha/acg   Path directory detected: $HOME/.capha/acg \r"
            chmod 777 $HOME/.capha/*
            sleep 0.5
            break
        else
            echo -ne "$grey未检测到PATH目录，开始创建...   Path directory not detected, start creating... \r"
            mkdir -p $HOME/.capha/acg
            chmod 777 $HOME/.capha/*
            sleep 0.5
        fi 
    done
}

check_system_package(){
    if command -v pkg >/dev/null 2>&1; then
        system_install="apt install"
        system="Termux"
    elif command -v apt >/dev/null 2>&1; then
        system_install="apt install"
        system="Ubuntu/Debian"
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

check_mainly_package(){
    echo -e "$blue 检测到系统为 $system$color"
    echo -ne " $grey检查必要的资源包...   Check the necessary resource packages... \r"
    sleep 1
    PACKAGE=( "curl" "wget" "chafa" "whiptail" )
    for package in "${PACKAGE[@]}";do
        if command -v $package >/dev/null 2>&1; then
            echo -ne " $grey检查到 $package 资源包，跳过安装 $package ...   Checked $package resource Pack, Skip Installation $package... \r"
            sleep 0.5
        else
            echo -ne " $grey未检查到 $package 资源包，开始安装 $package ...   Not checked $package resource pack, starting installation $package... \r"
            sleep 0.5
            if $system_install $package -y >/dev/null 2>&1;then
                echo -ne " $grey$package 资源包安装成功!    $package resource package installed successfully!"
                sleep 0.8
            else
                echo -ne " $grey$package 资源包安装失败!    $package resource package installed failed!"
                exit 1
            fi
        fi
    done
}

choose_devices(){
    clear
    echo -e "请选择$blue获取图片的设备/终端$color:"
    echo -e "1.$green Android/Termux $color"
    echo -e "2.$green WSL/Linux/Terminal $color"
    echo -e "3.$green 清除已获取的图片 $color"
    echo -e "4.$green 查看已保存的图片 $color"
    echo -e "0.$red 取消获取图片 $color"
    read -p ">" get_device
    case $get_device in
        1)
            deaflut=0
            echo -e "获取的$blue图片张数$color"
            read -p ">" get_pic_num
            while true
            do
                if [[ "$deaflut" != "$get_pic_num" ]];then
                    echo -e "$green 正在从$blue$PIC_API_AND$green中获取图片..."
                    get_pic_pe
                    deaflut=$((deaflut + 1))
                elif [[ "$deaflut" -gt "$get_pic_num" ]];then
                    echo -e "$red 无法读取的数字! $color"
                else
                    echo -e "$green 成功从$blue$PIC_API_AND$green中获取了$yellow$get_pic_num$green张图片到$PIC_PATH!"
                    break
                fi
            done
            ;;
        2)
            deaflut=0
            echo -e "获取的$blue图片张数$color"
            read -p ">" get_pic_num
            while true
            do
                if [[ "$deaflut" != "$get_pic_num" ]];then
                    echo -e "$green 正在从$blue$PIC_API_PC$green中获取图片..."
                    get_pic_pc
                    deaflut=$((deaflut + 1))
                elif [[ "$deaflut" -gt "$get_pic_num" ]];then
                    echo -e "$red 无法读取的数字! $color"
                else
                    echo -e "$green 成功从$blue$PIC_API_PC$green中获取了$yellow$get_pic_num$green张图片到$PIC_PATH!"
                    break
                fi
            done
            ;;
        3)
            clear
            echo -ne "$grey 正在删除文件...$color \r"
            rm -r  $HOME/.capha/acg/*
            echo -e "$green 已成功删除$blue$HOME/.capha/acg$color下的所有文件!" 
            ;;
        4)
            clear
            list_saved_images
            ;;
        0)
            exit 0
            ;;
    esac
}

get_pic_pc(){
    GET_TIME=$(date +%Y%m%d_%H%M%S)
    PIC_PATH="$HOME/.capha/acg/$GET_TIME"_pc
    if wget -O $PIC_PATH.png "$PIC_API_PC" >/dev/null 2>&1;then
        chafa $PIC_PATH.png
    else
        echo -e "$red 无法从$blue$PIC_API_PC$red获取图片!"
        exit 1
    fi
}

get_pic_pe(){
    GET_TIME=$(date +%Y%m%d_%H%M%S)
    PIC_PATH="$HOME/.capha/acg/$GET_TIME"_pe
    if wget -O $PIC_PATH.png "$PIC_API_AND" >/dev/null 2>&1;then
        chafa $PIC_PATH.png
    else
        echo -e "$red 无法从$blue$PIC_API_AND$red获取图片!"
        exit 1
    fi
}

list_saved_images(){
    shopt -s nullglob
    local files=("$HOME/.capha/acg/"*.png)
    shopt -u nullglob
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "$red 尚未保存任何图片，请先获取图片再查看。$color"
        return
    fi

    echo -e "$green 已保存的图片列表: $color"
    local idx=1
    for file in "${files[@]}"; do
        echo "$idx. $(basename "$file")"
        idx=$((idx + 1))
    done

    while true; do
        read -p "请输入要查看的图片序号 (0 退出): " selection
        if [[ "$selection" == "0" ]]; then
            break
        elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$idx" ]; then
            local target="${files[$((selection - 1))]}"
            echo -e "$cyan 正在使用 chafa 渲染: $target $color"
            chafa "$target"
            break
        else
            echo -e "$red 输入不合法，请输入有效序号。$color"
        fi
    done
}

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

color_variable
check_dir
check_system_package
check_mainly_package
choose_devices
