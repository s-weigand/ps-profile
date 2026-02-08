#!/usr/bin/env pwsh
#
# PowerShell Profile Updater
#
# Updates profile files and tools to latest versions
#

param(
    [string]$RepoOwner,
    [string]$RepoName,
    [string]$Branch
)

# Load persisted repo config if present (install.ps1 writes it)
$repoConfigPaths = @(
    (Join-Path $HOME 'Documents\PowerShell\ps-profile.repo.ps1'),
    (Join-Path $HOME 'Documents\WindowsPowerShell\ps-profile.repo.ps1')
)
foreach ($configPath in $repoConfigPaths) {
    if (Test-Path $configPath) {
        try { . $configPath; break } catch { }
    }
}

# Use params > config > upstream defaults
if ([string]::IsNullOrWhiteSpace($RepoOwner)) { $RepoOwner = if ($Global:PSProfileRepoOwner) { $Global:PSProfileRepoOwner } else { 's-weigand' } }
if ([string]::IsNullOrWhiteSpace($RepoName)) { $RepoName = if ($Global:PSProfileRepoName) { $Global:PSProfileRepoName } else { 'ps-profile' } }
if ([string]::IsNullOrWhiteSpace($Branch)) { $Branch = if ($Global:PSProfileRepoBranch) { $Global:PSProfileRepoBranch } else { 'main' } }

if ($Global:PSProfileRepoBase) {
    $RepoBase = $Global:PSProfileRepoBase
} else {
    $ref = $Branch.Trim('/')
    if ($ref -like '*/*' -and -not $ref.StartsWith('refs/')) { $ref = "refs/heads/$ref" }
    $RepoBase = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$ref"
}

Write-Host "Updating PowerShell Profile..." -ForegroundColor Cyan
Write-Host "Repository: https://github.com/$RepoOwner/$RepoName" -ForegroundColor Gray

$TempDir = Join-Path $env:TEMP 'ps-profile-update'

# Create temporary directory
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# Download latest profile files
Write-Host "Downloading latest profile files..." -ForegroundColor Yellow
$GitPromptStyle = if ($Global:PSProfileGitPromptStyle) { $Global:PSProfileGitPromptStyle } else { 'full' }

$FilesToDownload = @{
    'Profile.ps1' = "$RepoBase/Profile.ps1"
    'aliases.ps1' = "$RepoBase/aliases.ps1"
    'themes/ohmy-posh.omp.json' = "$RepoBase/themes/ohmy-posh.omp.json"
}

foreach ($File in $FilesToDownload.GetEnumerator()) {
    $LocalPath = Join-Path $TempDir $File.Key
    $LocalDir = Split-Path $LocalPath -Parent

    if (-not (Test-Path $LocalDir)) {
        New-Item -ItemType Directory -Path $LocalDir -Force | Out-Null
    }

    Invoke-RestMethod $File.Value -OutFile $LocalPath
    Write-Host "  ✓ $($File.Key)" -ForegroundColor Green
}

# Download fast theme if user prefers it (optional — may not exist on upstream)
if ($GitPromptStyle -eq 'fast') {
    $FastThemePath = Join-Path $TempDir 'themes/ohmy-posh-fast.omp.json'
    try {
        Invoke-RestMethod "$RepoBase/themes/ohmy-posh-fast.omp.json" -OutFile $FastThemePath
        Write-Host "  ✓ themes/ohmy-posh-fast.omp.json" -ForegroundColor Green
    } catch {
        # Fast theme not available on this branch — fall back to full
        Write-Host "  ⚠ Fast theme not available, using full" -ForegroundColor Yellow
        $GitPromptStyle = 'full'
    }
}

# Update PowerShell modules
Write-Host "Updating PowerShell modules..." -ForegroundColor Yellow
$Modules = @('PSReadLine', 'Terminal-Icons')
foreach ($Module in $Modules) {
    Update-Module -Name $Module -Force
    Write-Host "  ✓ $Module" -ForegroundColor Green
}

# Update external tools
Write-Host "Updating external tools..." -ForegroundColor Yellow
$Tools = @(
    'JanDeDobbeleer.OhMyPosh',
    'ajeetdsouza.zoxide',
    'BurntSushi.ripgrep.MSVC',
    'sharkdp.bat',
    'sharkdp.fd',
    'Schniz.fnm',
    'Dystroy.broot'
)
foreach ($Tool in $Tools) {
    winget upgrade $Tool --silent --accept-package-agreements
    Write-Host "  ✓ $Tool" -ForegroundColor Green
}

# Update profile files
Write-Host "Updating profile files..." -ForegroundColor Yellow

# PowerShell 7+
$PS7ProfileDir = "$HOME\Documents\PowerShell"
Copy-Item (Join-Path $TempDir 'Profile.ps1') "$PS7ProfileDir\Profile.ps1" -Force
Copy-Item (Join-Path $TempDir 'aliases.ps1') "$PS7ProfileDir\aliases.ps1" -Force

# Windows PowerShell 5.x
$PS5ProfileDir = "$HOME\Documents\WindowsPowerShell"
Copy-Item (Join-Path $TempDir 'Profile.ps1') "$PS5ProfileDir\Profile.ps1" -Force
Copy-Item (Join-Path $TempDir 'aliases.ps1') "$PS5ProfileDir\aliases.ps1" -Force

# Update theme (respects git prompt style preference from install)
$ThemeSource = if ($GitPromptStyle -eq 'fast') { 'themes/ohmy-posh-fast.omp.json' } else { 'themes/ohmy-posh.omp.json' }
Copy-Item (Join-Path $TempDir $ThemeSource) "$HOME\themes\ohmy-posh.omp.json" -Force

Write-Host "  ✓ Profile files updated" -ForegroundColor Green

# Regenerate completions
Write-Host "Regenerating completions..." -ForegroundColor Yellow
if (Get-Command rg -ErrorAction SilentlyContinue) {
    # Create completions directories if they don't exist
    $PS7CompletionsDir = "$PS7ProfileDir\completions"
    $PS5CompletionsDir = "$PS5ProfileDir\completions"
    if (-not (Test-Path $PS7CompletionsDir)) {
        New-Item -ItemType Directory -Path $PS7CompletionsDir -Force | Out-Null
    }
    if (-not (Test-Path $PS5CompletionsDir)) {
        New-Item -ItemType Directory -Path $PS5CompletionsDir -Force | Out-Null
    }

    # Generate completions directly to profile directories
    rg --generate complete-powershell | Out-File "$PS7CompletionsDir\_rg.ps1" -Encoding utf8
    rg --generate complete-powershell | Out-File "$PS5CompletionsDir\_rg.ps1" -Encoding utf8
    Write-Host "  ✓ Ripgrep completions" -ForegroundColor Green
}

# Configure Windows Terminal keybindings
Write-Host "Configuring Windows Terminal keybindings..." -ForegroundColor Yellow
$TerminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $TerminalSettingsPath) {
    try {
        $TerminalSettings = Get-Content $TerminalSettingsPath -Raw | ConvertFrom-Json

        # Disable Alt+Enter keybinding if not already disabled
        if (-not $TerminalSettings.actions) {
            $TerminalSettings | Add-Member -MemberType NoteProperty -Name 'actions' -Value @() -Force
        }
        
        # Check if Alt+Enter is already unbound
        $altEnterUnbound = $TerminalSettings.actions | Where-Object { 
            $_.keys -eq 'alt+enter' -and $null -eq $_.command
        }
        
        if (-not $altEnterUnbound) {
            # Convert to array if not already
            if ($TerminalSettings.actions -isnot [System.Array]) {
                $TerminalSettings.actions = @($TerminalSettings.actions)
            }
            
            # Add the unbound keybinding
            $TerminalSettings.actions = @($TerminalSettings.actions) + @([PSCustomObject]@{
                command = $null
                keys    = 'alt+enter'
            })
            
            # Save settings with proper formatting and depth
            $TerminalSettings | ConvertTo-Json -Depth 10 | Set-Content $TerminalSettingsPath -Encoding utf8
            Write-Host "  ✓ Windows Terminal Alt+Enter keybinding disabled" -ForegroundColor Green
        } else {
            Write-Host "  ✓ Windows Terminal Alt+Enter keybinding already disabled" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ✗ Failed to configure Windows Terminal keybindings: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  ✓ Windows Terminal settings not found" -ForegroundColor Gray
}

# Clean up
Remove-Item $TempDir -Recurse -Force

Write-Host "`n✅ Update complete!" -ForegroundColor Green
Write-Host "Restart PowerShell to activate the updated profile." -ForegroundColor Cyan
