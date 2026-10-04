@echo off
title Lok Samadhan - Run On Connected Mobile Phone
cd /d "%~dp0"

echo =======================================================================
echo          Lok Samadhan - Mobile Phone Launcher (Android)
echo =======================================================================
echo.
echo [*] Step 1: Forwarding port 5000 via ADB Reverse Proxy...
adb reverse tcp:5000 tcp:5000 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Port 5000 forwarded to phone via USB (localhost:5000 and Wi-Fi both work!)
) else (
    echo [INFO] ADB reverse skipped or device on Wi-Fi only.
)

echo.
echo [*] Step 2: Checking backend status at http://10.90.141.134:5000/api/health ...
echo [*] Backend URL: http://10.90.141.134:5000/api

echo.
echo [*] Step 3: Installing and launching Flutter app on mobile device...
echo.
flutter run -d android --dart-define=API_BASE_URL=http://10.90.141.134:5000/api

pause
