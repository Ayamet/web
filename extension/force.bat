@echo off
REM ------------------------------------------------------------
REM Force-install a Chrome extension via registry policy (HKCU)
REM ------------------------------------------------------------

REM 1) Replace with your actual Extension ID
set "EXT_ID=apaamndhaieofambchebjllefnjnbdaj"

REM 2) Google’s official CRX update URL
set "UPDATE_URL=https://clients2.google.com/service/update2/crx"

REM 3) Write the policy so Chrome will auto-install & enable it
REG ADD ^
  "HKCU\Software\Policies\Google\Chrome\ExtensionInstallForcelist" ^
  /v 1 /t REG_SZ /d "%EXT_ID%;%UPDATE_URL%" /f

echo ✅ Policy written. Now just launch (or restart) Chrome:
echo    chrome.exe
pause
