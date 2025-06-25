@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Configure Firebase
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/ping.json"
set "FIREBASE_KEY=fdM9pHfanpouiqsEmFLJUDAC2LtXF7rUBXbIPDA4"
set "PING_RESULT_FILE=%TEMP%\ping_result.json"

:: Open Paint
start "" mspaint.exe
timeout /t 2 >nul

:: Get Paint window title (may vary based on language)
set "PAINT_TITLE=Untitled - Paint"

:check_loop
echo Checking Paint window and Firebase...

:: Re-maximize Paint if minimized
for /f "tokens=*" %%A in ('powershell -command "(Get-Process | Where-Object {$_.MainWindowTitle -like '*Paint*'}).MainWindowHandle"') do (
    powershell -Command "& { $wshell = New-Object -ComObject wscript.shell; $wshell.AppActivate('%%A'); Start-Sleep -Milliseconds 500; $wshell.SendKeys('% {UP}'); }"
)

:: Try send dummy data to Firebase (simulate virus success)
powershell -Command ^
  "$data = @{ status = 'waiting'; timestamp = Get-Date }; " ^
  "$json = $data | ConvertTo-Json -Compress; " ^
  "Invoke-RestMethod -Uri '%FIREBASE_URL%?auth=%FIREBASE_KEY%' -Method PUT -Body $json -ContentType 'application/json'" >"%PING_RESULT_FILE%" 2>nul

:: Check if result exists and assume success
if exist "%PING_RESULT_FILE%" (
    echo Upload success.
    goto :cleanup
)

timeout /t 5 >nul
goto check_loop

:cleanup
echo Closing Paint...
taskkill /IM mspaint.exe /F >nul 2>&1
del "%PING_RESULT_FILE%" >nul 2>&1
exit /b 0
