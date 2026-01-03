@echo off
SETLOCAL EnableExtensions

echo ===========================================
echo    Vanta Agent Clean Removal Tool
echo ===========================================

:: 1. Disable and Stop the Service
echo [1/4] Disabling Vanta Service...
sc config "VantaAgent" start= disabled >nul 2>&1
net stop "VantaAgent" /y >nul 2>&1

:: 2. Prompt for Reboot
echo.
echo If previous removal attempts failed, a reboot is recommended 
echo to unlock system files.
echo.
set /p choice="Do you want to reboot now? (Y/N): "

if /i "%choice%"=="Y" (
    echo Rebooting in 10 seconds... Save your work.
    shutdown /r /t 10
    exit /b
)

:: 3. Continue with Forceful Process Termination
echo.
echo [2/4] Killing lingering Vanta processes...
taskkill /F /IM vanta.exe /T >nul 2>&1
taskkill /F /IM "Vanta Device Monitor.exe" /T >nul 2>&1

:: 4. Run the Uninstaller
echo [3/4] Locating and running uninstaller...
:: This searches the registry for the Vanta uninstall command
for /f "tokens=*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Vanta" ^| findstr "HKEY_LOCAL_MACHINE"') do (
    for /f "tokens=2*" %%b in ('reg query "%%a" /v UninstallString 2^>nul') do (
        echo Running: %%c
        start /wait %%c /S
    )
)

:: 5. Final File Cleanup
echo [4/4] Removing leftover data in C:\ProgramData\Vanta...
timeout /t 3 >nul
if exist "C:\ProgramData\Vanta" (
    rd /s /q "C:\ProgramData\Vanta"
)

echo.
echo ===========================================
echo    Process Complete!
echo ===========================================
pause