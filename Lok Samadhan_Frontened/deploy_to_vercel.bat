@echo off
title Sahayak Vaani - Deploy to Permanent Free Cloud
cd /d "%~dp0build\web"

echo =======================================================================
echo          Deploy Sahayak Vaani Permanently (Free 24/7 Hosting)
echo =======================================================================
echo.
echo This will deploy your Flutter web app to Vercel so that:
echo  1. It stays online 24/7 even when your PC is turned off or Antigravity is closed.
echo  2. You get a permanent URL (e.g. sahayak-vaani.vercel.app) that never changes.
echo  3. You will NEVER get "Error 1033: Host lost" again!
echo.
echo TIPS:
echo  - If it's your first time, it will ask to log in via GitHub/Email (opens browser).
echo  - For all setup questions, simply press [ENTER] to choose default answers!
echo.
echo Press any key to start deployment...
pause >nul

echo.
echo Deploying to Vercel...
npx --yes vercel --prod

echo.
pause
