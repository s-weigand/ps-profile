#!/usr/bin/env pwsh
#
# PowerShell Profile Updater
#
# Updates profile files and tools to latest versions
#

param(
    [string]$RepoOwner,
    [string]$RepoName,
    [string]$Branch,
    # Optional override for raw base URL (advanced)
    [string]$RepoBase
)

function Get-RepoBase {
    param(
        [Parameter(Mandatory = $true)][string]$Owner,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Branch
    )

    $base = "https://raw.githubusercontent.com/$Owner/$Name/$Branch"
    return $base.TrimEnd('/')
}

$UpstreamOwner = 's-weigand'
$UpstreamName = 'ps-profile'
$UpstreamBranch = 'main'
$UpstreamBase = 'https://raw.githubusercontent.com/s-weigand/ps-profile/main'

# Load persisted repo config if present (install.ps1 writes it)
try {
    $scriptDir = $null
    if ($PSCommandPath) {
        $scriptDir = Split-Path -Parent $PSCommandPath
    } elseif ($MyInvocation.PSCommandPath) {
        $scriptDir = Split-Path -Parent $MyInvocation.PSCommandPath
    }

    $repoConfigCandidates = @(
        (if ($scriptDir) { Join-Path $scriptDir 'ps-profile.repo.ps1' }),
        (Join-Path $HOME 'Documents\PowerShell\ps-profile.repo.ps1'),
        (Join-Path $HOME 'Documents\WindowsPowerShell\ps-profile.repo.ps1')
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

    foreach ($candidate in $repoConfigCandidates) {
        . $candidate
        break
    }
} catch {
    # Non-fatal: updater can still run with defaults/params
}

# Fill missing params from config (if loaded), otherwise upstream defaults
if ([string]::IsNullOrWhiteSpace($RepoOwner) -and $Global:PSProfileRepoOwner) { $RepoOwner = $Global:PSProfileRepoOwner }
if ([string]::IsNullOrWhiteSpace($RepoName) -and $Global:PSProfileRepoName) { $RepoName = $Global:PSProfileRepoName }
if ([string]::IsNullOrWhiteSpace($Branch) -and $Global:PSProfileRepoBranch) { $Branch = $Global:PSProfileRepoBranch }
if ([string]::IsNullOrWhiteSpace($RepoBase) -and $Global:PSProfileRepoBase) { $RepoBase = $Global:PSProfileRepoBase }

if ([string]::IsNullOrWhiteSpace($RepoOwner)) { $RepoOwner = $UpstreamOwner }
if ([string]::IsNullOrWhiteSpace($RepoName)) { $RepoName = $UpstreamName }
if ([string]::IsNullOrWhiteSpace($Branch)) { $Branch = $UpstreamBranch }

if ([string]::IsNullOrWhiteSpace($RepoBase)) {
    $RepoBase = Get-RepoBase -Owner $RepoOwner -Name $RepoName -Branch $Branch
} else {
    $RepoBase = $RepoBase.TrimEnd('/')
}

Write-Host "Updating PowerShell Profile..." -ForegroundColor Cyan
Write-Host "Upstream:  https://github.com/$UpstreamOwner/$UpstreamName" -ForegroundColor Gray
Write-Host "Updating:  https://github.com/$RepoOwner/$RepoName" -ForegroundColor Gray
$TempDir = Join-Path $env:TEMP 'ps-profile-update'

function Get-LatestCommitDate {
    param(
        [Parameter(Mandatory = $true)][string]$Owner,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Branch
    )

    try {
        $headers = @{ 'User-Agent' = 'ps-profile-updater' }
        $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Name/commits/$Branch" -Headers $headers -ErrorAction Stop
        return [datetime]$commit.commit.committer.date
    } catch {
        return $null
    }
}

# Friendly notice if upstream is ahead (non-blocking)
if ("$RepoOwner/$RepoName" -ne "$UpstreamOwner/$UpstreamName") {
    $upstreamDate = Get-LatestCommitDate -Owner $UpstreamOwner -Name $UpstreamName -Branch $UpstreamBranch
    $currentDate = Get-LatestCommitDate -Owner $RepoOwner -Name $RepoName -Branch $Branch
    if ($upstreamDate -and $currentDate -and ($upstreamDate -gt $currentDate)) {
        Write-Host "Note: Upstream ($UpstreamOwner/$UpstreamName) has newer changes on '$UpstreamBranch' ($upstreamDate). Consider merging/rebasing your fork." -ForegroundColor Yellow
    }
}

# Create temporary directory
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# Download latest profile files
Write-Host "Downloading latest profile files..." -ForegroundColor Yellow
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

# Update theme
Copy-Item (Join-Path $TempDir 'themes\ohmy-posh.omp.json') "$HOME\themes\ohmy-posh.omp.json" -Force

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
