# dotfiles

Small cross-platform dotfiles repo, starting with WezTerm + Clink.

## Layout

```text
wezterm/
  wezterm.lua         shared Windows/Linux config
  local.example.lua  template for machine-specific launch profiles
  local.lua          current machine's private profiles; ignored by Git
clink/
  inputrc             Clink Readline binding (`Ctrl+E` accepts suggestion)
  apply-settings.cmd  reapplies chosen Clink settings
scripts/
  bootstrap-windows.ps1
  bootstrap-linux.sh
```

## WezTerm

The shared config keeps the current Monokai Pro Dark theme, Cascadia Mono
(with JetBrains Mono fallback), rounded tab titles, scrollback, cursor, and
other common behavior.

Machine-specific launchers live in `wezterm/local.lua`.  It is ignored by Git
so work paths, hostnames, usernames, and IP addresses do not get published.
Use `wezterm/local.example.lua` as the template on another machine.

### Windows

From PowerShell in the repo root:

```powershell
.\scripts\bootstrap-windows.ps1
```

This backs up any existing `%USERPROFILE%\.wezterm.lua` and writes a tiny
loader pointing to the shared repo config.  No symlink privileges are needed.

### Linux

From the repo root:

```bash
./scripts/bootstrap-linux.sh
```

This backs up an existing `~/.config/wezterm/wezterm.lua` and writes a tiny
loader pointing to the shared repo config.

Linux normally needs no launch profile: WezTerm starts the user's login shell.
The shared tab-title logic will show names such as `bash ~ project` or
`zsh ~ project`, while hiding the home-directory name as useless context.

## Clink

The repo currently records the custom binding:

```text
Ctrl+E -> clink-insert-suggested-line
```

Merge/copy `clink/inputrc` into `%USERPROFILE%\.inputrc` on Windows.
Reapply the selected Clink preferences with:

```cmd
clink\apply-settings.cmd
```

The script enables inline autosuggestions and leaves the suggestion list off
by default, so `F2` can still toggle the list on demand.

`clink-completions` is intentionally not vendored into this repo.  Keep it as
its own Git checkout and update it with `git pull`.

## Start tracking with Git

This package is already initialized as a Git repository.  After reviewing the
files, create the first commit with your own Git identity:

```bash
git add .
git commit -m "Initial dotfiles"
```

Then add your preferred remote and push.  Starting with a private remote is a
safe default; machine-specific secrets should remain in ignored local files.
