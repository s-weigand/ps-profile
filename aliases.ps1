##################################
##            ALIASES           ##
##################################

# Pre-commit alias
function pa {
    pre-commit run -a
}

# Navigate to parent directory
function .. {
    Set-Location ..
}

# Update PowerShell profile
function update-ps-profile {
    param([switch]$AsAdmin)

    $RepoBase = 'https://raw.githubusercontent.com/s-weigand/ps-profile/main'
    $RepoConfigPath = Join-Path $PSScriptRoot 'ps-profile.repo.ps1'
    if (Test-Path $RepoConfigPath) {
        try {
            $RepoConfig = . $RepoConfigPath
            if ($RepoConfig -and $RepoConfig.Base) {
                $RepoBase = ('' + $RepoConfig.Base).TrimEnd('/')
            }
        } catch {
            Write-Warning "Failed to load profile repo config from '$RepoConfigPath': $($PSItem.Exception.Message)"
        }
    }

    $Shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
    $UpdateUrl = "$RepoBase/update.ps1"
    $ScriptCommand = "iex (irm '$UpdateUrl')"
    $StartProcessArgs = @{
        FilePath     = $Shell
        ArgumentList = @("-NoExit", "-Command", $ScriptCommand)
        Wait         = $True
    }

    if ($AsAdmin) { $StartProcessArgs.Verb = 'RunAs' }
    Start-Process @StartProcessArgs
}


# br function to handle changing directory
# This should be created by `broot --install` but isn't see ref:
# https://github.com/Canop/broot/issues/788
function br {
    $CmdFile = New-TemporaryFile

    try {
        # Use call operator with splatting for proper argument handling
        $BrootArgs = @('--outcmd', $CmdFile.FullName) + $Args
        & broot @BrootArgs
        $ExitCode = $LASTEXITCODE
    } catch {
        $ExitCode = 1
    }

    if ($ExitCode -eq 0) {
        $Cmd = Get-Content $CmdFile
        Remove-Item $CmdFile
        if ($Cmd -ne $Null) { Invoke-Expression -Command $Cmd }
    } else {
        Remove-Item $CmdFile
        Write-Host "`n" # Newline to tidy up broot unexpected termination
        Write-Error "broot.exe exited with error code $ExitCode"
    }
}
