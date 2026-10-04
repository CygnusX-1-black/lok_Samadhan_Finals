@echo off
title Sahayak Vaani - Public Web Runner
cd /d "%~dp0"

echo =======================================================================
echo            Sahayak Vaani - Public Web Tunnel Runner
echo =======================================================================
echo.

:: 1. Check build directory
if not exist "build\web\index.html" (
    echo [ERROR] Flutter web build not found at build\web\index.html!
    echo Please run 'flutter build web' first.
    echo.
    pause
    exit /b 1
)

:: 2. Clean up any previous server on port 8088
echo [*] Checking and cleaning up port 8088...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8088" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>&1
)

:: 3. Start local Python web server in background
echo [*] [1/2] Starting local web server on http://127.0.0.1:8088 ...
start "SahayakVaani-Server" /B python -u tools\serve.py

timeout /t 2 /nobreak >nul

:: 4. Information message
echo [*] [2/2] Launching Cloudflare Public Tunnel...
echo.
echo =======================================================================
echo  HOW IT WORKS & WHY YOU SEE ERROR 1033:
echo   - This tunnel runs LOCALLY from your PC.
echo   - Keep this Command Prompt window OPEN (you can minimize it).
echo   - If you close this window or close Antigravity, the tunnel dies
echo     and visitors will see "Error 1033: Host lost".
echo   - Each time this script runs, Cloudflare gives a NEW random URL!
echo     The old URL (like sensitive-issued-...) is permanently expired.
echo.
echo  LOOK FOR YOUR NEW URL BELOW (https://....trycloudflare.com):
echo =======================================================================
echo.

:: 5. Launch Cloudflare tunnel
tools\cloudflared.exe tunnel --url http://127.0.0.1:8088

:: 6. Cleanup when tunnel exits
echo.
echo [*] Tunnel stopped. Cleaning up background server...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8088" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>&1
)
echo [*] Done.
pause
