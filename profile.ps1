# Universal PowerShell Profile
# Works with PowerShell 5.x and 7+ across all hosts

##################################
##             TOOLS            ##
##################################

# PSReadLine - Enhanced command line editing
# Install: Install-Module -Name PSReadLine -Scope CurrentUser -Force
Import-Module PSReadLine

Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ShellForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function ShellBackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+Delete -Function ShellKillWord
Set-PSReadLineKeyHandler -Key Ctrl+Backspace -Function ShellBackwardKillWord

# Accept next suggestion word with Ctrl+RightArrow at end of line
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow `
    -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
    -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
    -ScriptBlock {
    param($Key, $Arg)

    $Line = $Null
    $Cursor = $Null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line, [ref]$Cursor)

    if ($Cursor -lt $Line.Length) {
        [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($Key, $Arg)
    }
    else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($Key, $Arg)
    }
}

# F7 for history with Out-GridView
Set-PSReadLineKeyHandler -Key F7 `
    -BriefDescription History `
    -LongDescription 'Show command history' `
    -ScriptBlock {
    $Pattern = $Null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Pattern, [ref]$Null)
    if ($Pattern) {
        $Pattern = [regex]::Escape($Pattern)
    }

    $History = [System.Collections.ArrayList]@(
        $Last = ''
        $Lines = ''
        foreach ($Line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath)) {
            if ($Line.EndsWith('`')) {
                $Line = $Line.Substring(0, $Line.Length - 1)
                $Lines = if ($Lines) {
                    "$Lines`n$Line"
                }
                else {
                    $Line
                }
                continue
            }

            if ($Lines) {
                $Line = "$Lines`n$Line"
                $Lines = ''
            }

            if (($Line -cne $Last) -and (!$Pattern -or ($Line -match $Pattern))) {
                $Last = $Line
                $Line
            }
        }
    )
    $History.Reverse()

    $Command = $History | Out-GridView -Title History -PassThru
    if ($Command) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($Command -join "`n"))
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

if (Get-Command code -ErrorAction SilentlyContinue) {
    $Env:EDITOR = 'code'
}
