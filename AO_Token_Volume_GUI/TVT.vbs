Set objShell = CreateObject("Wscript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = scriptDir & "\TVT.ps1"

' Launch PowerShell GUI silently
objShell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command ""Start-Sleep -Milliseconds 250; & '" & psScript & "'""", 0, False

