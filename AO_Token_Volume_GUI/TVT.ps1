# Final Token Volume Tracker
# Save as TokenTracker.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Token Volume Tracker"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"
$form.Icon = [System.Drawing.SystemIcons]::Application

# Block range inputs
$lblStartBlock = New-Object System.Windows.Forms.Label
$lblStartBlock.Location = New-Object System.Drawing.Point(20, 20)
$lblStartBlock.Size = New-Object System.Drawing.Size(80, 20)
$lblStartBlock.Text = "Start Block:"
$form.Controls.Add($lblStartBlock)

$txtStartBlock = New-Object System.Windows.Forms.TextBox
$txtStartBlock.Location = New-Object System.Drawing.Point(110, 20)
$txtStartBlock.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($txtStartBlock)

$lblEndBlock = New-Object System.Windows.Forms.Label
$lblEndBlock.Location = New-Object System.Drawing.Point(230, 20)
$lblEndBlock.Size = New-Object System.Drawing.Size(80, 20)
$lblEndBlock.Text = "End Block:"
$form.Controls.Add($lblEndBlock)

$txtEndBlock = New-Object System.Windows.Forms.TextBox
$txtEndBlock.Location = New-Object System.Drawing.Point(320, 20)
$txtEndBlock.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($txtEndBlock)

# Run button
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Location = New-Object System.Drawing.Point(200, 60)
$btnRun.Size = New-Object System.Drawing.Size(100, 30)
$btnRun.Text = "Run All"
$form.Controls.Add($btnRun)

# Results label
$lblResults = New-Object System.Windows.Forms.Label
$lblResults.Location = New-Object System.Drawing.Point(20, 100)
$lblResults.Size = New-Object System.Drawing.Size(460, 30)
$lblResults.Text = "Results:"
$lblResults.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblResults)

# Summary labels
$tokensData = @(
    @{ Name = "wAR"; Y = 130 },
    @{ Name = "qAR"; Y = 160 },
    @{ Name = "wUSDC"; Y = 190 },
    @{ Name = "AO"; Y = 220 }
)

$tokenLabels = @{}
$tokenResults = @{}

foreach ($token in $tokensData) {
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, $token.Y)
    $label.Size = New-Object System.Drawing.Size(100, 20)
    $label.Text = "$($token.Name):"
    $label.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($label)
    $tokenLabels[$token.Name] = $label
    
    $result = New-Object System.Windows.Forms.Label
    $result.Location = New-Object System.Drawing.Point(120, $token.Y)
    $result.Size = New-Object System.Drawing.Size(360, 20)
    $result.Text = "Not run yet"
    $result.Font = New-Object System.Drawing.Font("Consolas", 10)
    $form.Controls.Add($result)
    $tokenResults[$token.Name] = $result
}

# Status and log
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(20, 260)
$lblStatus.Size = New-Object System.Drawing.Size(460, 20)
$lblStatus.Text = "Ready"
$lblStatus.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblStatus)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 290)
$txtLog.Size = New-Object System.Drawing.Size(460, 60)
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$form.Controls.Add($txtLog)

# Function to validate inputs
function ValidateInputs {
    $startBlock = $txtStartBlock.Text.Trim()
    $endBlock = $txtEndBlock.Text.Trim()
    
    if ([string]::IsNullOrEmpty($startBlock) -or [string]::IsNullOrEmpty($endBlock)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter both start and end block numbers.", "Input Error", "OK", "Error")
        return $false
    }
    
    if (-not [int]::TryParse($startBlock, [ref]$null) -or -not [int]::TryParse($endBlock, [ref]$null)) {
        [System.Windows.Forms.MessageBox]::Show("Block numbers must be integers.", "Input Error", "OK", "Error")
        return $false
    }
    
    $startBlockNum = [int]::Parse($startBlock)
    $endBlockNum = [int]::Parse($endBlock)
    
    if ($startBlockNum -ge $endBlockNum) {
        [System.Windows.Forms.MessageBox]::Show("End block must be greater than start block.", "Input Error", "OK", "Error")
        return $false
    }
    
    return $true
}

# Function to update the log
function LogMessage {
    param($message)
    $txtLog.AppendText("$message`r`n")
    $txtLog.ScrollToCaret()
}

# Function to run scripts and update UI
function RunScripts {
    $startBlock = $txtStartBlock.Text.Trim()
    $endBlock = $txtEndBlock.Text.Trim()
    
    # Clear results and disable button
    foreach ($token in $tokensData.Name) {
        $tokenResults[$token].Text = "Running..."
    }
    
    $txtLog.Text = "Starting scripts...`r`n"
    $btnRun.Enabled = $false
    $lblStatus.Text = "Running scripts..."
    
    # Run each script one by one
    $tokens = @("wAR", "qAR", "wUSDC", "AO")
    $completed = 0
    
    foreach ($token in $tokens) {
        LogMessage "Running ${token}.ps1..."
        $form.Refresh()
        
        try {
            # Set up the output file
            $outputFile = "$pwd\${token}_output.txt"
            
            # Run the script using cmd.exe
            $cmdPath = "$env:windir\System32\cmd.exe"
            $cmdArgs = "/c powershell ./${token}.ps1 $startBlock $endBlock > `"$outputFile`""
            
            $process = Start-Process -FilePath $cmdPath -ArgumentList $cmdArgs -PassThru -WindowStyle Hidden -Wait
            
            # Check if the output file exists and has content
            if (Test-Path $outputFile) {
                # Look for the final total line
                $finalLine = ""
                foreach ($line in (Get-Content -Path $outputFile)) {
                    if ($line -match "Final total:") {
                        $finalLine = $line
                    }
                }
                
                if ($finalLine -ne "") {
                    if ($finalLine -match "Final total: ([0-9,]+)") {
                        $result = $matches[1]
                        $tokenResults[$token].Text = $result
                        LogMessage "${token} result: $result"
                    } else {
                        $tokenResults[$token].Text = "Error: Couldn't parse result"
                        LogMessage "${token} error: Couldn't parse result from: $finalLine"
                    }
                } else {
                    $tokenResults[$token].Text = "Error: No result found"
                    LogMessage "${token} error: No 'Final total' line found"
                }
                
                # Clean up output file
                Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
            } else {
                $tokenResults[$token].Text = "Error: No output produced"
                LogMessage "${token} error: No output file produced"
            }
        } catch {
            $errorMsg = $_.Exception.Message
            $tokenResults[$token].Text = "Error: Script execution failed"
            LogMessage "${token} error: $errorMsg"
        }
        
        $completed++
        $lblStatus.Text = "Progress: $completed/4 completed"
        $form.Refresh()
    }
    
    # Done
    $lblStatus.Text = "All scripts completed"
    LogMessage "All scripts completed."
    $btnRun.Enabled = $true
}

# Run button click event
$btnRun.Add_Click({
    if (ValidateInputs) {
        RunScripts
    }
})

# Create a desktop shortcut function
function CreateDesktopShortcut {
    $scriptPath = (Resolve-Path -Path $MyInvocation.MyCommand.Path).Path
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcutPath = [System.IO.Path]::Combine($WshShell.SpecialFolders.Item("Desktop"), "Token Volume Tracker.lnk")
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $shortcut.WorkingDirectory = (Split-Path -Path $scriptPath)
    $shortcut.Description = "Launch Token Volume Tracker"
    $shortcut.IconLocation = "powershell.exe,0"
    $shortcut.Save()
    return $shortcutPath
}

# Add a menu for creating the shortcut
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

$toolsMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$toolsMenu.Text = "Tools"
$menuStrip.Items.Add($toolsMenu)

$createShortcutItem = New-Object System.Windows.Forms.ToolStripMenuItem
$createShortcutItem.Text = "Create Desktop Shortcut"
$createShortcutItem.Add_Click({
    try {
        $shortcutPath = CreateDesktopShortcut
        [System.Windows.Forms.MessageBox]::Show("Shortcut created at: $shortcutPath", "Success", "OK", "Information")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to create shortcut: $($_.Exception.Message)", "Error", "OK", "Error")
    }
})
$toolsMenu.DropDownItems.Add($createShortcutItem)

# Show the form
[void]$form.ShowDialog()