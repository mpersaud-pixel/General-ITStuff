@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo ===========================================
echo    Vanta Agent Clean Removal Tool
echo ===========================================

:: 1. Disable and Stop the Service
echo [1/4] Disabling Vanta Service...
sc config "VantaAgent" start= disabled >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Failed to disable the Vanta service. Please run as Administrator.
    pause
    exit /b %errorlevel%
)

net stop "VantaAgent" /y >nul 2>&1
:: We don't exit on error here because the service might already be stopped.

:: 2. Prompt for Reboot
echo.
echo If previous removal attempts failed, a reboot is recommended.
set /p choice="Do you want to reboot now? (Y/N): "

if /i "%choice%"=="Y" (
    echo Rebooting in 10 seconds... Save your work.
    shutdown /r /t 10
    exit /b 0
)

:: 3. Forceful Process Termination
echo.
echo [2/4] Terminating Vanta processes...
:: We use || ver > nul to prevent "Process not found" from being treated as a fatal script error
taskkill /F /IM vanta.exe /T >nul 2>&1 || ver > nul
taskkill /F /IM "Vanta Device Monitor.exe" /T >nul 2>&1 || ver > nul

:: 4. Run the Uninstaller
echo [3/4] Locating and running uninstaller...
set "FoundUninstaller=N"

for /f "tokens=*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Vanta" ^| findstr "HKEY_LOCAL_MACHINE"') do (
    for /f "tokens=2*" %%b in ('reg query "%%a" /v UninstallString 2^>nul') do (
        set "FoundUninstaller=Y"
        echo Running: %%c
        start /wait %%c /S
        if !errorlevel! neq 0 (
            echo [ERROR] The uninstaller returned an error code: !errorlevel!
            pause
            exit /b !errorlevel!
        )
    )
)

if "%FoundUninstaller%"=="N" (
    echo [INFO] Vanta uninstaller not found in registry. It may already be uninstalled.
)

:: 5. Final File Cleanup
echo [4/4] Removing leftover data in C:\ProgramData\Vanta...
timeout /t 3 >nul
if exist "C:\ProgramData\Vanta" (
    rd /s /q "C:\ProgramData\Vanta"
    if exist "C:\ProgramData\Vanta" (
        echo [ERROR] Could not delete C:\ProgramData\Vanta. Files may still be locked.
        echo Please reboot and run this script again.
        pause
        exit /b 1
    )
)

echo.
echo ===========================================
echo    SUCCESS: Vanta Agent removed completely.
echo ===========================================
pause