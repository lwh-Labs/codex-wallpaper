@echo off
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0install-shortcut.ps1" %*
pause
