@echo off
title Sahayak Vaani - Instant Cloud Re-Deploy
cd /d "%~dp0"

echo =======================================================================
echo         Sahayak Vaani - One-Click Cloud Re-Deployment
echo =======================================================================
echo.
echo Deploying updated Flutter Web build with Gujarati support...
echo.

:: Ensure SPA routing works cleanly
if exist "build\web\index.html" (
    copy /y "build\web\index.html" "build\web\200.html" >nul
)

:: Primary Global Cloud Deployment (Cloudflare Edge CDN)
echo [*] Uploading to 24/7 Global Cloud CDN...
call npx --yes @shipstatic/ship build/web

echo.
echo =======================================================================
echo Deployment complete!
echo Your latest build with Gujarati facility is live 24/7 globally.
echo It works without Antigravity, without USB cable, on any phone/PC!
echo =======================================================================
echo.
pause
