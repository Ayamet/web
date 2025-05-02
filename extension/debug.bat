@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo   DEBUG: CRX INSTALLER via External Extensions
echo ==================================================

REM 0) Make sure Chrome is closed
echo [!] Please CLOSE all Chrome windows before continuing.
pause

REM 1) CONFIG — set these before running:
set "CRX_URL=https://drive.google.com/uc?export=download&id=1RHPij0Z7oD1b78v8fNZiYeUgXjYVHKIv"
set "WORKDIR=%~dp0crx-install"
set "EXT_ID=apaamndhaieofambchebjllefnjnbdaj"   REM ← your 32-char ID

echo.
echo [Step 1] Preparing work folder: "%WORKDIR%"
if exist "%WORKDIR%" rd /s /q "%WORKDIR%" || (
  echo   ERROR: Could not delete "%WORKDIR%"
  pause & exit /b 1
)
mkdir "%WORKDIR%" 2>nul || (
  echo   ERROR: Could not create "%WORKDIR%"
  pause & exit /b 1
)

echo.
echo [Step 2] Downloading CRX from Drive...
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Invoke-WebRequest -Uri '%CRX_URL%' -OutFile '%WORKDIR%\extension.crx' -UseBasicParsing"
if errorlevel 1 (
  echo   ERROR: Download failed.
  pause & exit /b 1
)

echo.
echo [Step 3] Verifying download…
if not exist "%WORKDIR%\extension.crx" (
  echo   ERROR: CRX not found at "%WORKDIR%\extension.crx"
  pause & exit /b 1
) else (
  dir "%WORKDIR%\extension.crx"
)

echo.
echo [Step 4] Writing External Extensions manifest…
set "EXT_MANIFEST_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default\External Extensions"
if not exist "%EXT_MANIFEST_DIR%" mkdir "%EXT_MANIFEST_DIR%" 2>nul

(
  echo {
  echo   "^"external_crx^": "^"%WORKDIR%\extension.crx^","
  echo   "^"external_version^": "^"1.0^""
  echo }
) > "%EXT_MANIFEST_DIR%\%EXT_ID%.json"  || (
  echo   ERROR: Could not write manifest JSON.
  pause & exit /b 1
)

echo   Manifest written to:
echo     %EXT_MANIFEST_DIR%\%EXT_ID%.json
type "%EXT_MANIFEST_DIR%\%EXT_ID%.json"

echo.
echo [Step 5] Launching Chrome…
start chrome "chrome://extensions"

echo.
echo [DONE] Your CRX should now appear under chrome://extensions
pause
