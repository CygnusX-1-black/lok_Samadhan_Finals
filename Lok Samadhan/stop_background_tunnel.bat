@echo off
title Stop Sahayak Vaani Background Service
cd /d "%~dp0"

echo Stopping background tunnel and web server...
taskkill /F /IM cloudflared.exe >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8088" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>&1
)
echo Background service stopped successfully.
pause
