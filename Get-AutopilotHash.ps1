# --- 1. SELF-ELEVATION BLOCK ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# --- 2. PREPARATION & POLICIES ---
Write-Host "Setting Execution Policy..." -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

Write-Host "Checking for NuGet and Get-WindowsAutopilotInfo..." -ForegroundColor Cyan
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
Install-Script -Name Get-WindowsAutopilotInfo -Force -Confirm:$false

# --- 3. DATA RETRIEVAL (Including Username) ---
$SerialNumber = (Get-CimInstance Win32_Bios).SerialNumber
$CurrentUsername = $env:USERNAME
$DesktopPath = [Environment]::GetFolderPath("Desktop")

# Updated Filename Format
$OutputFileName = "hashfile-$CurrentUsername-$SerialNumber.csv"
$FullPath = Join-Path $DesktopPath $OutputFileName

# --- 4. EXECUTION ---
Write-Host "Generating hash for User: $CurrentUsername | Serial: $SerialNumber..." -ForegroundColor Yellow
& "Get-WindowsAutopilotInfo.ps1" -OutputFile $FullPath

# --- 5. CLEANUP & PAUSE ---
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser -Force

Write-Host "`nSUCCESS: File created on Desktop: $OutputFileName" -ForegroundColor Green
Write-Host "----------------------------------------------------------"
Read-Host "Task Complete. Press ENTER to close this window"