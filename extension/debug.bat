@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo   DEBUG: CRX INSTALLER via External Extensions
echo ==================================================

REM 0) Close Chrome
echo [!] PLEASE CLOSE ALL CHROME WINDOWS BEFORE CONTINUING
pause

REM 1) CONFIG – fill in your details here
set "CRX_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "WORKDIR=%~dp0crx-install"
set "EXT_ID=apaamndhaieofambchebjllefnjnbdaj"

REM 2) Kill Chrome if running
echo.
echo [1] Killing Chrome…
taskkill /F /IM chrome.exe >nul 2>&1

REM 3) Prepare working folder
echo.
echo [2] Preparing work folder: "%WORKDIR%"
if exist "%WORKDIR%" rd /s /q "%WORKDIR%"
mkdir "%WORKDIR%" || (
  echo   ERROR: Could not create "%WORKDIR%"
  pause & exit /b 1
)

REM 4) Download the CRX
echo.
echo [3] Downloading extension.crx…
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Invoke-WebRequest '%CRX_URL%' -OutFile '%WORKDIR%\extension.crx' -UseBasicParsing"
if not exist "%WORKDIR%\extension.crx" (
  echo   ERROR: Download failed—file missing.
  pause & exit /b 1
)
echo   Download successful:
dir "%WORKDIR%\extension.crx"

REM 5) Escape the path for JSON
echo.
echo [4] Escaping CRX path for JSON…
set "CRX_PATH=%WORKDIR%\extension.crx"
set "CRX_JSON_PATH=%CRX_PATH:\=\\\\%"
echo   JSON path: !CRX_JSON_PATH!

REM 6) Write External Extensions manifest
echo.
echo [5] Writing External Extensions manifest…
set "EXT_MDIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default\External Extensions"
if not exist "%EXT_MDIR%" mkdir "%EXT_MDIR%" 2>nul

> "%EXT_MDIR%\%EXT_ID%.json" (
  echo {"^"external_crx"^":"^"!CRX_JSON_PATH!^"","^"external_version"^":"^"1.0"^"}
) || (
  echo   ERROR: Could not write manifest JSON.
  pause & exit /b 1
)

echo   Manifest created at:
echo     %EXT_MDIR%\%EXT_ID%.json
type "%EXT_MDIR%\%EXT_ID%.json"

REM 7) Launch Chrome
echo.
echo [6] Launching Chrome…
start chrome "chrome://extensions"

echo.
echo [DONE] The extension should now appear and be enabled.
pause
