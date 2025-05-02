@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo   DEBUG: CRX INSTALLER via External Extensions
echo ==================================================

REM 0) Ensure Chrome is closed
echo [!] PLEASE CLOSE ALL CHROME WINDOWS BEFORE CONTINUING
pause

REM 1) CONFIGURATION — edit these two:
set "CRX_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "EXT_ID=apaamndhaieofambchebjllefnjnbdaj"   REM ← your 32-char Extension ID

REM 2) Kill Chrome so the manifest will be picked up
echo.
echo [1] Killing Chrome…
taskkill /F /IM chrome.exe >nul 2>&1

REM 3) Prepare a temp folder for the CRX
echo.
echo [2] Preparing work folder…
set "WORKDIR=%~dp0crx-install"
if exist "%WORKDIR%" rd /s /q "%WORKDIR%"
mkdir "%WORKDIR%" || (
  echo   ERROR: Could not create %WORKDIR%
  pause & exit /b 1
)

REM 4) Download your packed .crx
echo.
echo [3] Downloading extension.crx…
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Invoke-WebRequest -Uri '%CRX_URL%' -OutFile '%WORKDIR%\extension.crx' -UseBasicParsing"
if not exist "%WORKDIR%\extension.crx" (
  echo   ERROR: CRX download failed.
  pause & exit /b 1
)
echo   Download OK:
dir "%WORKDIR%\extension.crx"

REM 5) Build a file:/// URL with forward-slashes
echo.
echo [4] Building file:/// URL…
set "WORKDIR_FWD=%WORKDIR:\=/%"
set "FILE_URL=file:///%WORKDIR_FWD%/extension.crx"
echo   Will use URL: %FILE_URL%

REM 6) Write the External Extensions JSON
echo.
echo [5] Writing External Extensions manifest…
set "EXT_MDIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default\External Extensions"
if not exist "%EXT_MDIR%" mkdir "%EXT_MDIR%" 2>nul

> "%EXT_MDIR%\%EXT_ID%.json" (
  echo {
  echo   "external_crx": "%FILE_URL%",
  echo   "external_version": "1.0"
  echo }
) || (
  echo   ERROR: Could not write manifest JSON.
  pause & exit /b 1
)

echo   Manifest created at:
echo     %EXT_MDIR%\%EXT_ID%.json
type "%EXT_MDIR%\%EXT_ID%.json"

REM 7) Locate Chrome (64-bit default path)
echo.
echo [6] Locating chrome.exe…
set "CHROME_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME_PATH%" (
  echo   ERROR: chrome.exe not found at "%CHROME_PATH%"!
  pause & exit /b 1
)
echo   chrome.exe found at: %CHROME_PATH%

REM 8) Launch Chrome to trigger the install and open the extensions page
echo.
echo [7] Launching Chrome with chrome://extensions…
start "" "%CHROME_PATH%" "chrome://extensions"

echo.
echo [DONE] Your CRX should now be installed & enabled.
pause
