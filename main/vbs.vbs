Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "C:\path\to\yourscript.bat" & chr(34), 0
Set WshShell = Nothing
