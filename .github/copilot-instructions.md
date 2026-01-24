# Copilot instructions (ps-profile)

## Project overview
- This repo is a Windows-focused PowerShell profile setup.
- Core files:
  - `Profile.ps1`: user profile logic; imports modules/tools and then dot-sources `aliases.ps1`.
  - `aliases.ps1`: interactive helper functions (notably `update-ps-profile`).
  - `install.ps1`: installer; downloads profile files from GitHub raw, installs modules/tools, configures fonts/settings, and writes a persisted repo config.
  - `update.ps1`: updater; downloads latest profile files, updates modules/tools, and prints an upstream-ahead notice for forks.

## Repo selection + persistence (fork-aware)
- The installer persists where updates should pull from by writing `ps-profile.repo.ps1` into both:
  - `~\Documents\PowerShell\ps-profile.repo.ps1`
  - `~\Documents\WindowsPowerShell\ps-profile.repo.ps1`
- `Profile.ps1` loads this config early and exposes:
  - `$Global:PSProfileRepoBase` (raw URL base used by `update-ps-profile`)
  - upstream defaults (`$Global:PSProfileUpstream*`) for credit and the “upstream is newer” notice.
- `aliases.ps1` should never hardcode `raw.githubusercontent.com/s-weigand/...`; it should use `$Global:PSProfileRepoBase`.

## Safety / trust model
- `install.ps1` shows a blocking confirmation prompt when run from a fork (non-`s-weigand`).
  - It attempts to infer `<owner>/<repo>/<branch>` from `$MyInvocation.Line` (the common `iex "& { $(irm '.../install.ps1') }"` pattern).
  - The prompt requires typing `YES` exactly; otherwise it aborts.
- When editing installer/updater behavior, keep the security notice and upstream credit intact.

## Be careful editing system-modifying code
- `install.ps1` and `update.ps1` can modify system/user state (execution policy, `winget` installs/upgrades, Windows Terminal settings JSON, VS Code settings JSON).
- Prefer minimal, surgical edits in those sections; preserve JSON structure/serialization depth and existing backup behavior.

## Key workflows (Windows)
- Install (upstream):
  - `iex "& { $(irm 'https://raw.githubusercontent.com/s-weigand/ps-profile/main/install.ps1') }"`
- Install (fork): swap the raw URL to your fork.
- Update (preferred after install): run `update-ps-profile` from `aliases.ps1` (it uses the persisted repo config and elevates).

## Validation conventions for changes
- Avoid running `install.ps1`/`update.ps1` as part of validation because they modify the system (execution policy, Winget installs, Windows Terminal/VS Code settings).
- Instead, validate PowerShell syntax by parsing scripts:
  - `[System.Management.Automation.Language.Parser]::ParseFile(<path>, [ref]$null, [ref]$errs)` and ensure `$errs.Count -eq 0`.

## Style / patterns to follow
- Prefer computed repo bases and normalize with `.TrimEnd('/')` before concatenating paths.
- Keep changes minimal and consistent with the current scripting style (functions, `Write-Host` progress, non-fatal `try/catch` around optional steps).
