@echo off
echo Disabling Microsoft Defender SmartScreen...

:: System-wide SmartScreen (File Explorer)
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d Off /f

:: SmartScreen for Microsoft Edge
reg add "HKCU\Software\Microsoft\Edge\SmartScreenEnabled" /v SmartScreenEnabled /t REG_DWORD /d 0 /f

:: SmartScreen for Windows Store apps (App & browser control)
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\SystemProtectedUserData\S-1-5-18\AnyoneRead\Default\SmartScreenEnabled" /v SmartScreenEnabled /t REG_DWORD /d 0 /f

echo Done. Please restart your computer for all changes to take effect.
pause
