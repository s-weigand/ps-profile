# **What happens if I install it?**

- **Installs & configures:** Running the installer copies this profile and runs `install.ps1` to set an execution policy, install key PowerShell modules (PSReadLine, Terminal-Icons) and common CLI tools via `winget` (Oh-My-Posh, zoxide, ripgrep, bat, fd, fnm, broot, uv).
- **Sets up your shell:** Your `Profile.ps1` is enabled — it configures `PSReadLine` keybindings, an Oh-My-Posh prompt with git/language indicators, loads aliases from `aliases.ps1`, and sources ripgrep completions if present.
- **Fonts & visuals:** The installer attempts to install/configure the MesloLGS NF font for Windows Terminal and VS Code so icons and glyphs render correctly.
- **Safe defaults:** Integrations are conditional — missing tools are skipped and the profile avoids hard failures.
- **After install:** Reopen PowerShell (or source your profile) to see the prompt, keybindings, and aliases. Update later with `update-ps-profile` or the `update.ps1` script.
- **Security:** Inspect `install.ps1` before running; the installer executes system installs and may change your execution policy.

# PowerShell Profile

⚠️ **SECURITY NOTICE**: Review [install.ps1](install.ps1) thoroughly before running. Fork this repository and modify for your needs.

Credit: this profile is based on (and defaults to updating from) the upstream repo: https://github.com/s-weigand/ps-profile

A universal PowerShell profile that works across PowerShell 5.x and 7+ on Windows, with enhanced command-line tools and productivity features.

## Quick Install

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/s-weigand/ps-profile/main/install.ps1') }"
```

### If `iex` / `irm` is blocked by antivirus

Some antivirus products may block “download + execute” one-liners (and show an error like “This script contains malicious content…”), even for benign scripts.

Regardless of install method (and especially if you’re using a fork), review the scripts before running them so you understand what they will change on your PC.

The recommended workaround is to install locally:

1) Download the repo as a ZIP from GitHub (or `git clone` it)
2) Review the scripts (especially [install.ps1](install.ps1) and [update.ps1](update.ps1))
3) Run the installer from the local folder:

```powershell
cd <path-to-ps-profile>
./install.ps1
```

## Install from your fork

Swap the URL to your fork:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/<your-user-or-org>/ps-profile/main/install.ps1') }"
```

The installer writes a small config file so `update-ps-profile` keeps updating from your fork automatically (`~\Documents\PowerShell\ps-profile.repo.ps1` and `~\Documents\WindowsPowerShell\ps-profile.repo.ps1`).

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

If you installed from a fork, use `update-ps-profile` (from [aliases.ps1](aliases.ps1)). It reads your persisted repo config and updates from your fork automatically.

When updating from a fork, the updater will also print a friendly note if the upstream repo has newer changes on `main` so you can decide whether to merge/rebase.

## Customization

Fork this repository and modify:

- [Profile.ps1](Profile.ps1) - Main profile logic
- [aliases.ps1](aliases.ps1) - Custom functions and aliases
- [themes/ohmy-posh.omp.json](themes/ohmy-posh.omp.json) - Prompt theme (try the [visual configurator](https://github.com/jamesmontemagno/ohmyposh-configurator))

All tools gracefully handle missing dependencies with conditional checks.
