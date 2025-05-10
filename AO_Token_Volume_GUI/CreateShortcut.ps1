$scriptDir = $PSScriptRoot
$vbsPath = Join-Path $scriptDir "TVT.vbs"

if (-not (Test-Path $vbsPath)) {
    Write-Host "Missing VBS launcher at $vbsPath" -ForegroundColor Red
    exit
}

$WshShell = New-Object -ComObject WScript.Shell
$shortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Token Volume Tracker.lnk"
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = "`"$vbsPath`""
$shortcut.WorkingDirectory = $scriptDir
$shortcut.IconLocation = "wscript.exe,0"
$shortcut.Description = "Launch Token Volume Tracker GUI (Hidden)"
$shortcut.Save()

Write-Host "✅ Shortcut created: $shortcutPath" -ForegroundColor Green
