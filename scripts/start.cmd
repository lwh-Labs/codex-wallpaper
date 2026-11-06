@echo off
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0start.ps1" %*
set "wallpaperExit=%errorlevel%"
echo.
echo Wallpaper launcher exited with code %wallpaperExit%.
pause
exit /b %wallpaperExit%
