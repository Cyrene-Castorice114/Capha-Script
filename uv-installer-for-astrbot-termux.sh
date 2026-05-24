#!/bin/bash
#颜色处理
color(){
blue='\033[0;34m'
red='\033[1;31m'
yellow='\033[1;33m'
color='\033[0m'
}
#检查命令
check_command(){
    for package_need in tar mkdir cp chmod mktemp rm curl;do
        if command -v $package_must >/dev/null 2>&1; then
            echo -e "$blue 已检测到必要文件-$package_need!"
        else
            echo -e "$red 你缺少了必要文件！正在退出..."
            exit 1
        fi
    done
}

create_install_path(){
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p $INSTALL_DIR
    TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -t 'uvtmp.XXXXXX')
    if [ -z "$TMP_DIR" ]; then
      echo -e "$red 创建临时目录时失败"
      exit 1
    fi
    mkdir -p "$TMP_DIR"
    TMP_ARCHIVE="$TMP_DIR/uv-aarch64-unknown-linux-gnu.tar.gz"
}

#下载uv
download_uv(){
    echo -e "$blue 开始下载uv 0.10.1版本！"
    if curl -fL "https://gh-proxy.com/https://github.com/astral-sh/uv/releases/download/0.10.1/uv-aarch64-unknown-linux-gnu.tar.gz" -o $TMP_ARCHIVE ; then
        echo -e "$blue uv已成功下载！"
    else
        echo -e "$red 下载时出现错误"
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
    chmod +x $INSTALL_DIR/uv $INSTALL_DIR/uvx
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
check_command
create_install_path
download_uv
tar_uv
install_change_mode
end