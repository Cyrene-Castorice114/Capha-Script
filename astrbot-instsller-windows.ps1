#AstrBot installer for Windows
#Check if Python is installed
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python is not installed. Please install Python and try again."
    exit
else {
    Write-Host "Python is installed. Proceeding with installation."
}
#Check if pip is installed
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "pip is not installed. Please install pip and try again."
    exit
else {
    Write-Host "pip is installed. Proceeding with installation."
}


