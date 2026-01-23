# PowerShell Profile

⚠️ **SECURITY NOTICE**: Review [install.ps1](install.ps1) thoroughly before running. Fork this repository and modify for your needs.

A universal PowerShell profile that works across PowerShell 5.x and 7+ on Windows, with enhanced command-line tools and productivity features.

## Quick Install

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/s-weigand/ps-profile/main/install.ps1') }"
```

## Tools Included

### PowerShell Modules

- **PSReadLine** - Enhanced command-line editing with custom key bindings
- **Terminal-Icons** - File icons in terminal

### External Tools

- **Oh-My-Posh** - Cross-shell prompt theme with git status, language versions
- **Zoxide** - Smart `z` command for directory navigation
- **Ripgrep** - Fast text search with PowerShell completions
- **Fast Node Manager (fnm)** - Node.js version manager

### Development Tools

- **Pre-commit** - Git hook framework (`pa` alias)

## Features

### Custom Key Bindings

- `Ctrl+RightArrow` - Forward word / Accept next suggestion
- `Ctrl+LeftArrow` - Backward word
- `Ctrl+Delete` - Delete word forward
- `Ctrl+Backspace` - Delete word backward
- `F7` - Interactive history search with Out-GridView

### Prompt Features

- Operating system indicator with WSL detection
- Current path with home directory shorthand
- Git status with branch, changes, and upstream info
- Language version detection (Node.js, Python, Go, Julia, Ruby)
- Azure Functions and AWS profile detection
- Admin/root indicator
- Execution time for long commands
- Current time

### Aliases

- `pa` - Run pre-commit on all files
- `..` - Navigate to parent directory
- `z` - Smart directory navigation (zoxide)

## Manual Installation

The [install.ps1](install.ps1) script handles all installation automatically, including:

1. Setting PowerShell execution policy to RemoteSigned
2. Installing PowerShell modules (PSReadLine, Terminal-Icons)
3. Installing external tools via winget (Oh-My-Posh, zoxide, ripgrep, fnm)
4. Downloading and copying profile files to PowerShell directories
5. Generating ripgrep completions

To install manually, review and run the install script or extract the individual commands from it.

## Update

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/s-weigand/ps-profile/main/update.ps1') }"
```

## Customization

Fork this repository and modify:

- [Profile.ps1](Profile.ps1) - Main profile logic
- [aliases.ps1](aliases.ps1) - Custom functions and aliases
- [themes/ohmy-posh.omp.json](themes/ohmy-posh.omp.json) - Prompt theme

The profile uses host detection to conditionally load features:

- PSReadLine configurations only load for console hosts
- Terminal-Icons only loads for PowerShell 7+
- All tools gracefully handle missing dependencies

## Compatibility

- **PowerShell 5.x** (Windows PowerShell)
- **PowerShell 7+** (PowerShell Core)
- **VS Code Terminal**
- **Windows Terminal**
- **Classic Console Host**

The profile automatically detects the host and loads appropriate features for maximum compatibility.
