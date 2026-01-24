#!/usr/bin/env pwsh
#
# PowerShell Profile Updater
#
# Updates profile files and tools to latest versions
#

Write-Host "Updating PowerShell Profile..." -ForegroundColor Cyan

$RepoBase = 'https://raw.githubusercontent.com/s-weigand/ps-profile/main'
$TempDir = Join-Path $env:TEMP 'ps-profile-update'

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
    'Schniz.fnm'
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

# Clean up
Remove-Item $TempDir -Recurse -Force

Write-Host "`n✅ Update complete!" -ForegroundColor Green
Write-Host "Restart PowerShell to activate the updated profile." -ForegroundColor Cyan
