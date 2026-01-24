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
    $UpdateScript = "iex (irm 'https://raw.githubusercontent.com/s-weigand/ps-profile/main/update.ps1')"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $UpdateScript -Verb RunAs -Wait
}
