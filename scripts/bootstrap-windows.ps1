$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$WezTermConfig = Join-Path $RepoRoot 'wezterm\wezterm.lua'
$Target = Join-Path $HOME '.wezterm.lua'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if (-not (Test-Path $WezTermConfig)) {
    throw "Cannot find WezTerm config: $WezTermConfig"
}

if (Test-Path $Target) {
    $Backup = "$Target.bak.$Timestamp"
    Copy-Item $Target $Backup
    Write-Host "Backed up existing config to $Backup"
}

# Use a tiny loader instead of a symlink.  This works on managed Windows
# machines without Developer Mode or administrator privileges.
$LuaPath = $WezTermConfig.Replace('\\', '/')
$Loader = @"
local wezterm = require 'wezterm'
return dofile([[$LuaPath]])
"@

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Target, $Loader, $Utf8NoBom)
Write-Host "Installed WezTerm loader: $Target"
Write-Host "Shared config: $WezTermConfig"
Write-Host ""
Write-Host "Clink: copy/merge clink\inputrc into $HOME\.inputrc if needed,"
Write-Host "then run clink\apply-settings.cmd to restore the chosen Clink settings."
