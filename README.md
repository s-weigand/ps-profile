# PowerShell Profile

⚠️ **SECURITY NOTICE**: Review [install.ps1](install.ps1) thoroughly before running. Fork this repository and modify for your needs.

A universal PowerShell profile that works across PowerShell 5.x and 7+ on Windows, with enhanced command-line tools and productivity features.

## Quick Install (from upstream)

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/s-weigand/ps-profile/main/install.ps1') }"
```

## Install from your fork

```powershell
# Via parameters (recommended)
./install.ps1 -RepoOwner your-user -RepoName ps-profile -Branch develop
```

You can also install directly from a fork/branch URL and pass matching arguments:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/your-user/your-repo/refs/heads/your-branch/install.ps1') } -RepoOwner your-user -RepoName your-repo -Branch your-branch"
```

The installer always shows the repository and branch source.
When installing from a non-upstream source, it asks for confirmation with `Continue? [Y/n]` (default is Yes).

When installing from a fork, the installer writes a config file so `update-ps-profile` updates from your fork automatically.

Priority: explicit parameter > upstream default.

### Git prompt style

During installation you can choose between two git prompt modes:

- **Full status** (default) — shows branch, dirty/staged files, ahead/behind, stash count. May be slow in large repos or with antivirus scanning.
- **Fast** — shows branch name only. Recommended if you experience prompt lag.

Your choice is persisted and respected by `update-ps-profile`. To switch later, re-run the installer.

## Tools Included

### PowerShell Modules

- **[PSReadLine](https://github.com/PowerShell/PSReadLine)** - Enhanced command-line editing with custom key bindings
- **[Terminal-Icons](https://github.com/devblackops/Terminal-Icons)** - File icons in terminal

### External Tools

- **[Oh-My-Posh](https://ohmyposh.dev/)** - Cross-shell prompt theme with git status, language versions
- **[Zoxide](https://github.com/ajeetdsouza/zoxide)** - Smart `z` command for directory navigation
- **[Ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast text search with PowerShell completions
- **[bat](https://github.com/sharkdp/bat)** - A cat clone with syntax highlighting and Git integration
- **[fd](https://github.com/sharkdp/fd)** - A fast and user-friendly alternative to find
- **[Fast Node Manager (fnm)](https://github.com/Schniz/fnm)** - Node.js version manager
- **[broot](https://github.com/Dystroy/broot)** - A better way to navigate directories
- **[uv](https://github.com/astral-sh/uv)** - Fast Python package installer and resolver
- **[MesloLGS NF Font](https://github.com/romkatv/powerlevel10k-media)** - Powerline-compatible font with icons (auto-configured for Windows Terminal and VS Code)

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
- `update-ps-profile` - Update profile files and tools to latest versions

## Manual Installation

The [install.ps1](install.ps1) script automates:

1. Setting PowerShell execution policy to RemoteSigned
2. Installing PowerShell modules (PSReadLine, Terminal-Icons)
3. Installing external tools via winget (Oh-My-Posh, zoxide, ripgrep, bat, fd, fnm, uv)
4. Installing and auto-configuring MesloLGS NF font for Windows Terminal and VS Code
5. Copying profile files to PowerShell directories
6. Generating ripgrep completions

### Manual Tool Installation

If you prefer to install components individually:

```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install PowerShell modules
Install-Module -Name PSReadLine -Scope CurrentUser -Force
Install-Module -Name Terminal-Icons -Scope CurrentUser -Force

# Install external tools via winget
winget install JanDeDobbeleer.OhMyPosh --silent -s winget
winget install ajeetdsouza.zoxide --silent -s winget
winget install BurntSushi.ripgrep.MSVC --silent -s winget
winget install sharkdp.bat --silent -s winget
winget install sharkdp.fd --silent -s winget
winget install Schniz.fnm --silent -s winget
winget install Dystroy.broot --silent -s winget
winget install astral-sh.uv --silent -s winget

# Generate ripgrep completions
rg --generate complete-powershell | Out-File ~\Documents\PowerShell\completions\_rg.ps1 -Encoding utf8
rg --generate complete-powershell | Out-File ~\Documents\WindowsPowerShell\completions\_rg.ps1 -Encoding utf8

# Download and install profile files manually from the repository
```

## Update

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/s-weigand/ps-profile/main/update.ps1') }"
```

Or use the `update-ps-profile` alias (updates from your configured repo).

## Customization

Fork this repository and modify:

- [profile.ps1](profile.ps1) - Main profile logic
- [aliases.ps1](aliases.ps1) - Custom functions and aliases
- [themes/ohmy-posh.omp.json](themes/ohmy-posh.omp.json) - Prompt theme (try the [visual configurator](https://github.com/jamesmontemagno/ohmyposh-configurator))

All tools gracefully handle missing dependencies with conditional checks.
