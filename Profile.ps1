# Universal PowerShell Profile
# Works with PowerShell 5.x and 7+ across all hosts

##################################
##        HOST DETECTION       ##
##################################

$IsConsoleHost = $Host.Name -eq 'ConsoleHost'
$IsVSCode = $Host.Name -eq 'Visual Studio Code Host'
$IsISE = $Host.Name -eq 'Windows PowerShell ISE Host'
$IsPowerShell7 = $PSVersionTable.PSEdition -eq 'Core'
$IsWindowsPowerShell = $PSVersionTable.PSEdition -eq 'Desktop'

##################################
##             TOOLS            ##
##################################

# PSReadLine - Enhanced command line editing
# Install: Install-Module -Name PSReadLine -Scope CurrentUser -Force
Import-Module PSReadLine

# Configure PSReadLine only for console hosts (skip ISE)
if ($IsConsoleHost) {
    Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ShellForwardWord
    Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function ShellBackwardWord
    Set-PSReadLineKeyHandler -Key Ctrl+Delete -Function ShellKillWord
    Set-PSReadLineKeyHandler -Key Ctrl+Backspace -Function ShellBackwardKillWord

    # Accept next suggestion word with Ctrl+RightArrow at end of line
    Set-PSReadLineKeyHandler -Key Ctrl+RightArrow `
        -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
        -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
        -ScriptBlock {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($cursor -lt $line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
        }
    }

    # F7 for history with Out-GridView
    Set-PSReadLineKeyHandler -Key F7 `
        -BriefDescription History `
        -LongDescription 'Show command history' `
        -ScriptBlock {
        $pattern = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
        if ($pattern) {
            $pattern = [regex]::Escape($pattern)
        }

        $history = [System.Collections.ArrayList]@(
            $last = ''
            $lines = ''
            foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath)) {
                if ($line.EndsWith('`')) {
                    $line = $line.Substring(0, $line.Length - 1)
                    $lines = if ($lines) {
                        "$lines`n$line"
                    }
                    else {
                        $line
                    }
                    continue
                }

                if ($lines) {
                    $line = "$lines`n$line"
                    $lines = ''
                }

                if (($line -cne $last) -and (!$pattern -or ($line -match $pattern))) {
                    $last = $line
                    $line
                }
            }
        )
        $history.Reverse()

        $command = $history | Out-GridView -Title History -PassThru
        if ($command) {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
        }
    }
}

# Terminal-Icons - File icons in terminal
# Install: Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
Import-Module -Name Terminal-Icons

# Oh-My-Posh - Cross-shell prompt theme
# Install: winget install JanDeDobbeleer.OhMyPosh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config ~/themes/ohmy-posh.omp.json | Invoke-Expression
}

# Fast Node Manager - Node.js version manager
# Install: winget install Schniz.fnm
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# Zoxide - Smart cd command
# Install: winget install ajeetdsouza.zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Ripgrep completions
# Generated with: rg --generate complete-powershell > completions/_rg.ps1
$RgCompletions = Join-Path $PSScriptRoot 'completions/_rg.ps1'
if (Test-Path $RgCompletions) {
    . $RgCompletions
}

# Load aliases and functions
$AliasesPath = Join-Path $PSScriptRoot 'aliases.ps1'
if (Test-Path $AliasesPath) {
    . $AliasesPath
}
