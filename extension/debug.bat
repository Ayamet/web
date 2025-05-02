@echo off
setlocal EnableDelayedExpansion

echo ========================================================
echo   ENHANCED CHROME EXTENSION AUTO-INSTALLER
echo   No Developer Account Required | Works on Any Windows PC
echo ========================================================

REM Initial setup
set "WORKDIR=%TEMP%\chrome-ext-installer-%RANDOM%"
set "EXT_DIR=%WORKDIR%\extension"
set "LOG_FILE=%WORKDIR%\install.log"

REM Create a clean working directory
if exist "%WORKDIR%" rd /s /q "%WORKDIR%" 2>nul
mkdir "%WORKDIR%" 2>nul || (
    echo [ERROR] Failed to create working directory.
    exit /b 1
)

echo [*] Starting installation process... > "%LOG_FILE%"
echo [*] Working directory: %WORKDIR% >> "%LOG_FILE%"

REM ===== CONFIGURATION SECTION =====
REM We now download from your Drive link instead of using a local ZIP
set "USE_LOCAL_ZIP=false"
set "LOCAL_ZIP_PATH=%~dp0extension.zip"
set "DOWNLOAD_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"

REM Configure your extension options here
set "EXTENSION_NAME=My Chrome Extension"
set "OPEN_EXTENSIONS_PAGE=true"
set "LAUNCH_AFTER_INSTALL=true"
set "CLEANUP_AFTER_EXIT=true"
REM ==================================

echo.
echo [1] Preparing extension files...
echo.

if "%USE_LOCAL_ZIP%"=="true" (
    if not exist "%LOCAL_ZIP_PATH%" (
        echo [ERROR] Local ZIP file not found at: %LOCAL_ZIP_PATH%
        echo         Please place your extension.zip in the same folder as this script.
        echo [ERROR] Local ZIP not found: %LOCAL_ZIP_PATH% >> "%LOG_FILE%"
        goto :error
    )
    echo     Using local extension ZIP file.
    copy "%LOCAL_ZIP_PATH%" "%WORKDIR%\ext.zip" >nul || goto :error
) else (
    echo     Downloading extension from remote URL...
    echo [*] Downloading from: %DOWNLOAD_URL% >> "%LOG_FILE%"
    powershell -NoProfile -Command "& {$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing}" || goto :error
)

echo.
echo [2] Extracting extension files...
echo.

mkdir "%EXT_DIR%" 2>nul
echo [*] Extracting to: %EXT_DIR% >> "%LOG_FILE%"
powershell -NoProfile -Command "& {$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%EXT_DIR%' -Force}" || goto :error

REM Find the actual extension directory (in case it's nested)
if not exist "%EXT_DIR%\manifest.json" (
    for /D %%D in ("%EXT_DIR%\*") do (
        if exist "%%D\manifest.json" (
            set "EXT_DIR=%%D"
            goto :found_manifest
        )
    )
    echo [ERROR] manifest.json not found in extracted files.
    echo [ERROR] manifest.json not found >> "%LOG_FILE%"
    goto :error
)
:found_manifest

echo     Extension files extracted successfully.
echo [*] Final extension directory: %EXT_DIR% >> "%LOG_FILE%"

echo.
echo [3] Finding Chrome installation...
echo.

REM Detect Chrome installation
set "CHROME_PATH="
for %%P in (
    "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
    "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
    "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do (
    if exist "%%~P" (
        set "CHROME_PATH=%%~P"
        goto :found_chrome
    )
)

echo [ERROR] Chrome installation not found.
echo [ERROR] Chrome installation not found >> "%LOG_FILE%"
goto :error

:found_chrome
echo     Chrome found at: %CHROME_PATH%
echo [*] Chrome executable: %CHROME_PATH% >> "%LOG_FILE%"

echo.
echo [4] Checking for running Chrome instances...
echo.

REM Get process list to check if Chrome is running
powershell -NoProfile -Command "Get-Process chrome -ErrorAction SilentlyContinue" >nul 2>&1
if not errorlevel 1 (
    echo     Chrome is currently running. Closing all instances...
    echo [*] Closing running Chrome instances >> "%LOG_FILE%"
    
    echo     Please save any open work in Chrome before continuing.
    echo     Press any key to continue or Ctrl+C to abort...
    pause >nul
    
    taskkill /F /IM chrome.exe >nul 2>&1
    timeout /t 2 >nul
) else (
    echo     No Chrome instances detected.
)

echo.
echo [5] Creating launcher for Chrome with extension...
echo.

REM Create the VBS launcher
set "LAUNCHER=%WORKDIR%\launch.vbs"
set "STARTUP_URL=chrome://extensions"
if "%OPEN_EXTENSIONS_PAGE%"=="false" set "STARTUP_URL=about:blank"

echo [*] Creating VBS launcher >> "%LOG_FILE%"
(
    echo Set WshShell = CreateObject("WScript.Shell")
    echo Dim flags
    echo flags = "--load-extension=""%EXT_DIR%"" --disable-extensions-except=""%EXT_DIR%"""
    echo WshShell.Run "%CHROME_PATH% " ^& flags ^& " "%STARTUP_URL%"", 1, False
) > "%LAUNCHER%"

REM Create a shortcut for future use
set "SHORTCUT=%USERPROFILE%\Desktop\%EXTENSION_NAME%.lnk"
echo [*] Creating shortcut: %SHORTCUT% >> "%LOG_FILE%"
powershell -NoProfile -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT%'); $Shortcut.TargetPath = '%CHROME_PATH%'; $Shortcut.Arguments = '--load-extension=\"%EXT_DIR%\" --disable-extensions-except=\"%EXT_DIR%\"'; $Shortcut.IconLocation = '%CHROME_PATH%,0'; $Shortcut.Save()}"

echo.
echo [6] Launching Chrome with your extension...
echo.

if "%LAUNCH_AFTER_INSTALL%"=="true" (
    echo     Launching Chrome with your extension now...
    echo [*] Launching Chrome >> "%LOG_FILE%"
    cscript //nologo "%LAUNCHER%"
) else (
    echo     Extension prepared but not launched.
)

echo.
echo ========================================================
echo   INSTALLATION COMPLETE!
echo ========================================================
echo.
echo Your extension has been successfully set up!
echo.
echo A shortcut has been created on your desktop:
echo "%EXTENSION_NAME%"
echo.
echo Notes:
echo - This is a "portable" installation that doesn't use Chrome Web Store
echo - The extension will remain installed as long as the extension files exist
echo - Use the desktop shortcut to launch Chrome with your extension
echo.
echo ========================================================
goto :end

:error
echo.
echo [ERROR] Installation failed. See log file for details:
echo %LOG_FILE%
echo.

:end
if "%CLEANUP_AFTER_EXIT%"=="true" (
    if exist "%WORKDIR%\ext.zip" del "%WORKDIR%\ext.zip"
    if exist "%LAUNCHER%" del "%LAUNCHER%"
)

echo Press any key to exit...
pause >nul
exit /b
