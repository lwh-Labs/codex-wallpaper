@echo off
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -STA -File "%~dp0picker.ps1" %*
if errorlevel 1 pause

