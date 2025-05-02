@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo   DEBUG: CRX INSTALLER via External Extensions
echo ==================================================

REM 0) User must close Chrome
echo [!] PLEASE CLOSE ALL CHROME WINDOWS BEFORE CONTINUING
pause

REM 1) CONFIG – set these before running:
set "CRX_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "WORKDIR=%~dp0crx-install"
set "EXT_ID=apaamndhaieofambchebjllefnjnbdaj"   REM ← your 32-char Extension ID

REM 2) Kill any running Chrome so installation will apply
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
  "Invoke-WebRequest -Uri '%CRX_URL%' -OutFile '%WORKDIR%\extension.crx' -UseBasicParsing"
if not exist "%WORKDIR%\extension.crx" (
  echo   ERROR: Download failed—file missing.
  pause & exit /b 1
)
echo   Download successful:
dir "%WORKDIR%\extension.crx"

REM 5) Escape the path for JSON
echo.
echo [4] Escaping path for JSON…
set "CRX_PATH=%WORKDIR%\extension.crx"
set "CRX_JSON_PATH=%CRX_PATH:\=\\%"
echo   JSON path will be: !CRX_JSON_PATH!

REM 6) Write External Extensions manifest
echo.
echo [5] Writing External Extensions manifest…
set "EXT_MDIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default\External Extensions"
if not exist "%EXT_MDIR%" mkdir "%EXT_MDIR%" 2>nul

(
  echo {
  echo   "external_crx": "!CRX_JSON_PATH!",
  echo   "external_version": "1.0"
  echo }
) > "%EXT_MDIR%\%EXT_ID%.json" || (
  echo   ERROR: Could not write manifest JSON.
  pause & exit /b 1
)

echo   Manifest file created at:
echo     %EXT_MDIR%\%EXT_ID%.json
type "%EXT_MDIR%\%EXT_ID%.json"

REM 7) Launch Chrome to trigger installation
echo.
echo [6] Launching Chrome…
start chrome "chrome://extensions"

echo.
echo [DONE] Your CRX should now be installed and enabled.
pause
