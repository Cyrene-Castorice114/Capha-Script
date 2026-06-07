#AstrBot installer for Windows

#Check if Python is installed
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python 没有被安装，即将安装Python."
    $pythonInstallerUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    Remove-Item $installerPath
}
else {
    Write-Host "Python 已安装，跳过安装Python."
}

#Check if pip is installed
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "pip 没有被安装，即将安装pip."
    python -m ensurepip --upgrade
}
else {
    Write-Host "pip 已安装，跳过安装pip."
}

#check uv for running the bot
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "uv 没有被安装，即将安装uv."
    pip install uv==0.10.1
}
else {
    Write-Host "uv 已安装，跳过安装uv."
}

#venv is not needed since uv will handle the dependencies in its own environment
uv venv create astrbot-env
uv venv use astrbot-env

#using uv to install the bot
Write-Host "正在使用 uv 安装 AstrBot."
uv tool install astrbot
uv run astrbot init
Write-Host "AstrBot 安装完成。现在可以使用 'uv run astrbot' 来运行。"

