@echo off
title Open Web Build Folder for Instant Drop
cd /d "%~dp0"

echo =======================================================================
echo     Instant 24/7 Hosting via Netlify Drop (Zero Commands Needed)
echo =======================================================================
echo.
echo 1. Opening https://app.netlify.com/drop in your browser...
start https://app.netlify.com/drop

echo 2. Opening the "build\web" folder in Windows Explorer...
explorer "%~dp0build\web"

echo.
echo -----------------------------------------------------------------------
echo  WHAT TO DO:
echo   - Drag the opened "web" folder (or select all its contents) 
echo     into the Netlify Drop box in your browser.
echo   - In 10 seconds, you get a permanent, 24/7 link that NEVER expires!
echo   - It works with laptop OFF, phone unplugged, and Antigravity closed.
echo -----------------------------------------------------------------------
echo.
pause
