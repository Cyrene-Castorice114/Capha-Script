#!/bin/bash
#检查你的capha文件

#check capha files
check_path(){
    while true
    do
        if [ -d "$HOME/.capha" ]; then
            INS_PATH="$HOME/.capha"
            if [ -f "$HOME/.capha/config.conf" ]; then
                echo -e "配置文件存在于:$blue$INS_PATH$color"
            else
                echo -e "$red未检测到配置文件，开始创建...$color"
                if echo "#Capha config file" >> $HOME/.capha/config.conf ; then                  
                    if [ -f "$HOME/.capha/config.conf" ]; then
                        echo -e "配置文件存在于:$blue$INS_PATH$color"
                        break
                    else
                        echo -e "$red创建时发生错误，请手动运行$cyan touch $INS_PATH/config.conf $color"
                        exit 1
                    fi
                else
                    echo -e "$red缺少必要资源包$color-$cyan touch $color"
                    echo -e "$blue开始尝试安装touch...$color"
                    apt update >/dev/null 2>&1 && apt upgrade -y >/dev/null 2>&1 && apt install touch >/dev/null 2>&1
                    if command -v touch >/dev/null 2>&1; then
                        echo -e "$blue重新创建配置文件...$color"
                        touch $INS_PATH/config.conf
                    else
                        echo -e "$red安装touch失败，请运行$green apt update && apt upgrade -y && apt install touch -y$color去安装"
                        echo -e "$red或者在终端输入$green touch $INS_PATH/config.conf $color创建"
                        exit 1
                    fi
                fi
            fi
            break
        else
            echo -e "$red未检查到工作目录，正在创建...$color"
            if command -v mkdir >/dev/null 2>&1; then
                mkdir $HOME/.capha
                if [ -d "$HOME/.capha" ]; then
                    INS_PATH="$HOME/.capha"
                else
                    echo -e "$red创建时发生错误，请手动运行$syan mkdir $HOME/.capha $color"
                    exit 1
                fi
            else
                echo -e "$red缺少必要资源包$color-$cyan mkdir $color"
                echo -e "$blue开始尝试安装mkdir...$color"
                apt update >/dev/null 2>&1 && apt upgrade -y >/dev/null 2>&1 && apt install mkdir >/dev/null 2>&1
                if command -v touch >/dev/null 2>&1; then
                    echo -e "$blue重新创建工作目录...$color"
                    touch $HOME/.capha
                else
                    echo -e "$red安装mkdir失败，请运行$green apt update && apt upgrade -y && apt install mkdir -y$color去安装"
                    exit 1
                fi
            fi
        fi
    done
}

#check config text
check_config(){
    echo -e "$blue检查是否已配置配置文件..."
    if command -v dialog >/dev/null 2>&1; then
        sleep 0.5
        echo -ne "$blue优先检测到dialog的对话框软件包，正在应用...$color /r"
        check_habit=dialog
    elif command -v whiptail >/dev/null 2>&1; then
        echo -ne "$blue优先检测到whiptail的对话框软件包，正在应用...$color /r"
        sleep 0.5
        check_habit=whiptail
    else
        echo -ne "$blue未检测到对话框软件包，正在应用原始方式...$color /r"
        sleep 0.5
    fi
    
    if grep "auto_update" $HOME/.capha/config.conf ;then
        echo -ne "$grey检查到配置-$green自动更新$color(1/5) /r"
        sleep 0.5
    else
        if [[ "$check_habit" == "$check_habit" ]]; then
            $check_habit --title "配置(1/5)" --yesno "是否启用自动更新脚本？" 0 0 \
            if [ $? -eq 0 ];then
                echo "auto_update=true" > "$config"
            else
                echo "auto_update=false" > "$config"
            fi
        else
            while true
            do
                echo -e "此处你只需要输入$green是$color或$red否$color来进行配置"
                read -p "自动更新选项：" line_update
                if [[ "$line_update" == "是" ]]; then
                    echo "auto_update=true" > "$config"
                    break
                elif [[ "$line_update" == "否" ]]; then
                    echo "auto_update=false" > "$config"
                    break
                else
                    echo -e "$red<<$color请检查输入内容是否正确！"
                fi
            done
        fi
    fi

    if grep "auto_update_package" $HOME/.capha/config.conf ;then
        echo -ne "$grey检查到配置-$green自动更新软件包$color(2/5) /r"
        sleep 0.5
    else
        if [[ "$check_habit" == "$check_habit" ]]; then
            $check_habit --title "配置(2/5)" --yesno "是否启用自动更新软件包？" 0 0 \
            if [ $? -eq 0 ];then
                echo "auto_update_package=true" > "$config"
            else
                echo "auto_update_package=false" > "$config"
            fi
        else
            while true
            do
                echo -e "此处你只需要输入$green是$color或$red否$color来进行配置"
                read -p "自动更新软件包选项：" line_update_package
                if [[ "$line_update_package" == "是" ]]; then
                    echo "auto_update_package=true" > "$config"
                    break
                elif [[ "$line_update_package" == "否" ]]; then
                    echo "auto_update_package=false" > "$config"
                    break
                else
                    echo -e "$red<<$color请检查输入内容是否正确！"
                fi
            done
        fi
    fi

    if grep "choice_habit" $HOME/.capha/config.conf ;then
        echo -ne "$grey检查到配置-$green选择方式$color(3/5) /r"
        sleep 0.5
    else
        if [[ "$check_habit" == "$check_habit" ]]; then
            while true
            do
               script_habit_choice=$check_habit --title "配置(3/5)" \
                --menu "选择一个脚本选择方式：" 0 0 \
                1 "dialog" \
                2 "whiptail" \
                3>&1 1>&2 2>&3)
                case $script_habit_choice in
                    1)
                        echo "habit_choice=dialog" >> "$config"
                        break
                        ;;
                    2)
                        echo "habit_choice=whiptail" >> "$config"
                        break
                        ;;
                    255)
                        $install_habit --msgbox "请不要使用ESC退出此界面，请在里面选择其中一个，否则脚本运行时会报错！" 0 0 --nocancel \
                        ;;                    
                esac
            done
        else
            while true
            do
                echo -e "此处你只需要输入$blue dialog $color或$blue whiptail $color来进行配置"
                read -p "选择方式选项：" line_habit_choice
                if [[ "$line_habit_choice" == "dialog" ]]; then
                    echo "habit_choice=dialog" > "$config"
                    break
                elif [[ "$line_habit_choice" == "whiptail" ]]; then
                    echo "habit_choice=whiptail" > "$config"
                    break
                else
                    echo -e "$red<<$color请检查输入内容是否正确！"
                fi
            done
        fi
    fi

    if grep "ser_user" $HOME/.capha/config.conf ;then
        echo -ne "$grey检查到配置-$green设置用户$color(4/5) /r"
        sleep 0.5
    else
        if [[ "$check_habit" == "$check_habit" ]]; then
            while true
            do               
                set_user=$check_habit --title "配置(4/5)" --yesno "是否启用设置用户：" 0 0 \
                if [ $? -eq 0 ];then
                    echo "set_user=true" >> "$config"
                    set_user=true
                else                   
                    echo "set_user=false" >> "$config"
                fi
            done
        else
            while true
            do
                echo -e "此处你只需要输入$green是$color或$red否$color来进行配置"
                read -p "选择方式选项：" line_set_user
                if [[ "$line_set_user" == "是" ]]; then
                    echo "set_user=true" >> "$config"
                    set_user=true
                    break
                elif [[ "$line_set_user" == "否" ]]; then
                    echo "set_user=false" >> "$config"
                    break
                else
                    echo -e "$red<<$color请检查输入内容是否正确！"
                fi
            done
        fi
    fi

    if [[ "$set_user" == "true" ]]; then
        if grep "user_name" $HOME/.capha/config.conf ;then
            echo -ne "$grey检查到配置-$green设置用户名$color(5/5) /r"
            sleep 0.5
        else
            if [[ "$check_habit" == "$check_habit" ]]; then
                while true
                do               
                    set_user_name=$check_habit --title "配置(5/5)" --inputbox "请输入用户名：" 0 0 3>&1 1>&2 2>&3
                    if [ -n "$set_user_name" ]; then
                        echo "user_name=$set_user_name" >> "$config"
                        break
                    else                   
                        $check_habit --msgbox "用户名不能为空，请重新输入！" 0 0 --nocancel \
                    fi
                done
            else
                while true
                do
                    read -p "请输入用户名：" line_set_user_name
                    if [[ -n "$line_set_user_name" ]]; then
                        echo "user_name=$line_set_user_name" >> "$config"
                        break
                    else
                        echo -e "$red<<$color用户名不能为空，请重新输入！"
                    fi
                done
            fi
        fi
    fi
    echo -e "$green你的配置全部存在!$color"
}

color_variable(){
    color='\033[0m'
    orange='\033[0;33m'
    green='\033[0;32m'
    blue='\033[0;34m'
    red='\033[31m'
    yellow='\033[33m'
    grey='\e[37m'
    pink='\033[38;5;218m'
    cyan='\033[96m'
}

color_variable
check_path
check_config