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

# Update PowerShell profile as admin
function update-ps-profile {
    $repoBase = $null
    if ($Global:PSProfileRepoBase) {
        $repoBase = "$Global:PSProfileRepoBase".TrimEnd('/')
    } elseif (Get-Command Get-PSProfileRepoBase -ErrorAction SilentlyContinue) {
        $repoBase = (Get-PSProfileRepoBase).TrimEnd('/')
    } else {
        $repoBase = 'https://raw.githubusercontent.com/s-weigand/ps-profile/main'
    }

    $updateUrl = "$repoBase/update.ps1"
    $UpdateScript = "iex (irm '$updateUrl')"

    $shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
    Start-Process $shell -ArgumentList "-NoExit", "-Command", $UpdateScript -Verb RunAs -Wait
}


# br function to handle changing directory
# This should be created by `broot --install` but isn't see ref:
# https://github.com/Canop/broot/issues/788
function br {
    $cmd_file = New-TemporaryFile

    try {
        # Use call operator with splatting for proper argument handling
        $brootArgs = @('--outcmd', $cmd_file.FullName) + $args
        & broot @brootArgs
        $exitCode = $LASTEXITCODE
    } catch {
        $exitCode = 1
    }

    If ($exitCode -eq 0) {
        $cmd = Get-Content $cmd_file
        Remove-Item $cmd_file
        If ($cmd -ne $null) { Invoke-Expression -Command $cmd }
    } Else {
        Remove-Item $cmd_file
        Write-Host "`n" # Newline to tidy up broot unexpected termination
        Write-Error "broot.exe exited with error code $exitCode"
    }
}
