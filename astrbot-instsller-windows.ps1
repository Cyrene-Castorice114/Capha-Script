#AstrBot installer for Windows

#Check if Python is installed
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python is not installed. starting install Python."
    $pythonInstallerUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    Remove-Item $installerPath
}
else {
    Write-Host "Python is installed. Proceeding with installation."
}

#Check if pip is installed
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "pip is not installed. Starting install pip."
    python -m ensurepip --upgrade
}
else {
    Write-Host "pip is installed. Proceeding with installation."
}

#check uv for running the bot
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "uv is not installed. Starting install uv."
    pip install uv==0.10.1
}
else {
    Write-Host "uv is installed. Proceeding with installation."
}

#using uv to install the bot
Write-Host "Installing AstrBot using uv."
uv tool install astrbot
uv run astrbot init
Write-Host "AstrBot installation complete. You can now run the bot using 'uv run astrbot'."

