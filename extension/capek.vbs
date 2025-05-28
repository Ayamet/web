Set WshShell = CreateObject("WScript.Shell")

' Path to the extension folder (use forward slashes)
extPath = Replace(CreateObject("Scripting.FileSystemObject").GetAbsolutePathName("extension"), "\", "/")

' Fake Extension ID – will not work unless signed
extID = "abcdefghijklmnopabcdefghijklmnop" ' Must be real if you want to use this

' Registry path
regPath = "HKCU\Software\Google\Chrome\Extensions\" & extID & "\"

WshShell.RegWrite regPath & "path", extPath, "REG_SZ"
WshShell.RegWrite regPath & "version", "1.0", "REG_SZ"

MsgBox "Registry keys written. Restart Chrome to see if the extension loads (unlikely unless signed).", vbInformation, "Done"
