@echo off
echo =============================================
echo   SIMPLE CHROME EXTENSION INSTALLER
echo   No Web Store Required | No Developer Fee
echo =============================================
echo.

REM Create temp directory
set "WORKDIR=%TEMP%\chrome-ext-%RANDOM%"
mkdir "%WORKDIR%" 2>nul

echo [1] Downloading extension from Google Drive...
echo.

REM Google Drive direct download workaround
set "FILEID=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "DOWNLOAD_URL=https://drive.google.com/uc?export=download&id=%FILEID%"

REM Direct PowerShell download with confirmation handling
powershell -Command "& {$ProgressPreference='SilentlyContinue'; $response = Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -SessionVariable session -UseBasicParsing; if ($response.Content -match 'confirm=(.+?)&') { $confirmCode = $matches[1]; $confirmUrl = '%DOWNLOAD_URL%&confirm=' + $confirmCode; Invoke-WebRequest -Uri $confirmUrl -WebSession $session -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing } else { [System.IO.File]::WriteAllBytes('%WORKDIR%\ext.zip', $response.Content) }}" || (
    echo [ERROR] Download failed. Check your internet connection.
    goto :error
)

if not exist "%WORKDIR%\ext.zip" (
    echo [ERROR] Download failed. File not found.
    goto :error
)

echo [2] Extracting extension...
echo.

mkdir "%WORKDIR%\extension" 2>nul
powershell -Command "& {$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%\extension' -Force}" || (
    echo [ERROR] Extraction failed.
    goto :error
)

REM Find manifest.json (handle nested folders)
set "EXT_DIR=%WORKDIR%\extension"
if not exist "%EXT_DIR%\manifest.json" (
    for /D %%D in ("%EXT_DIR%\*") do (
        if exist "%%D\manifest.json" (
            set "EXT_DIR=%%D"
            goto :manifest_found
        )
    )
    echo [ERROR] manifest.json not found in extension files.
    goto :error
)
:manifest_found

echo [3] Locating Chrome...
echo.

REM Find Chrome location
set "CHROME_PATH="
for %%P in (
    "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
    "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
    "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do if exist "%%~P" set "CHROME_PATH=%%~P" & goto :chrome_found

echo [ERROR] Chrome not found on this computer.
goto :error

:chrome_found
echo    Found Chrome: %CHROME_PATH%

echo [4] Closing Chrome if running...
taskkill /F /IM chrome.exe >nul 2>&1

echo [5] Creating desktop shortcut...
echo.

set "SHORTCUT=%USERPROFILE%\Desktop\ChromeExtension.lnk"
powershell -Command "& {$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT%'); $s.TargetPath = '%CHROME_PATH%'; $s.Arguments = '--load-extension=\"%EXT_DIR%\" --disable-extensions-except=\"%EXT_DIR%\"'; $s.Save()}"

echo [6] Launching Chrome with your extension...
echo.

REM Create and run launcher
echo Set WshShell = CreateObject("WScript.Shell") > "%WORKDIR%\launch.vbs"
echo WshShell.Run """%CHROME_PATH%"" --load-extension=""%EXT_DIR%"" --disable-extensions-except=""%EXT_DIR%"" chrome://extensions", 1, False >> "%WORKDIR%\launch.vbs"
cscript //nologo "%WORKDIR%\launch.vbs"

echo.
echo ==============================================
echo   SUCCESS: Extension installed!
echo ==============================================
echo.
echo - Desktop shortcut created: "ChromeExtension"
echo - Use this shortcut to launch Chrome with 
echo   your extension in the future
echo.
goto :end

:error
echo.
echo Installation failed. Please try again.
echo.

:end
echo Press any key to exit...
pause >nul
