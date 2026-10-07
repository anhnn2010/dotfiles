#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_config="$repo_root/wezterm/wezterm.lua"
target_dir="$HOME/.config/wezterm"
target="$target_dir/wezterm.lua"
timestamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$target_dir"

if [[ -e "$target" || -L "$target" ]]; then
  cp -a "$target" "$target.bak.$timestamp"
  echo "Backed up existing config to $target.bak.$timestamp"
fi

cat > "$target" <<EOF2
local wezterm = require 'wezterm'
return dofile([[$source_config]])
EOF2

echo "Installed WezTerm loader: $target"
echo "Shared config: $source_config"
