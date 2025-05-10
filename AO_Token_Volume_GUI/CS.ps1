# Create Desktop Shortcut for Token Volume Tracker
# Save this as CreateShortcut.ps1 and run it once

# Get the path to TokenTracker.ps1
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "TVT.ps1"

# Make sure the script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: Could not find TokenTracker.ps1 in the current directory." -ForegroundColor Red
    Write-Host "Please make sure you've saved the main script as TokenTracker.ps1 in the same directory as this script." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Create the shortcut
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcutPath = [System.IO.Path]::Combine($WshShell.SpecialFolders.Item("Desktop"), "Token Volume Tracker.lnk")
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe" 
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $shortcut.WorkingDirectory = (Split-Path -Path $scriptPath)
    $shortcut.Description = "Launch Token Volume Tracker"
    $shortcut.IconLocation = "powershell.exe,0"
    $shortcut.Save()
    
    Write-Host "Shortcut created successfully at: $shortcutPath" -ForegroundColor Green
    Write-Host "You can now launch the Token Volume Tracker by double-clicking this shortcut." -ForegroundColor Green
}
catch {
    Write-Host "Error creating shortcut: $($_.Exception.Message)" -ForegroundColor Red
}

Read-Host "Press Enter to exit"