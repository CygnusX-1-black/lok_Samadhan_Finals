@echo off
cd /d "%~dp0"
echo Launching Sahayak Vaani tunnel in an independent Windows window...
start "Sahayak Vaani Public Web Runner" cmd.exe /c "%~dp0start_public_web.bat"
exit
