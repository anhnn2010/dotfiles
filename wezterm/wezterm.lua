local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback {
  'Cascadia Mono',
  'JetBrains Mono',
}
config.font_size = 12.0

config.scrollback_lines = 20000
config.audible_bell = 'Disabled'

config.default_cursor_style = 'BlinkingBar'

-- Tab bar
-- Inspired by KevinSilvester/wezterm-config's rounded retro tabs,
-- but kept intentionally small and adapted to this config.
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.show_tab_index_in_tab_bar = false

local nf = wezterm.nerdfonts
local TAB_LEFT = nf.ple_left_half_circle_thick   -- 
local TAB_RIGHT = nf.ple_right_half_circle_thick -- 
local UNSEEN = nf.fa_circle                     -- 

local TAB_COLORS = {
  bar = '#101010',
  active_bg = '#403e41',
  active_fg = '#fcfcfa',
  hover_bg = '#2d2a2e',
  hover_fg = '#fcfcfa',
  inactive_bg = '#242124',
  inactive_fg = '#939293',
  unseen = '#fc9867',
}

config.colors = {
  tab_bar = {
    background = TAB_COLORS.bar,

    -- format-tab-title draws the actual tabs; these mainly style the + button.
    new_tab = {
      bg_color = TAB_COLORS.bar,
      fg_color = TAB_COLORS.inactive_fg,
    },
    new_tab_hover = {
      bg_color = TAB_COLORS.hover_bg,
      fg_color = TAB_COLORS.hover_fg,
    },
  },
}

local function cwd_name(tab)
  local cwd = tab.active_pane.current_working_dir
  if not cwd then
    return nil
  end

  local path
  if type(cwd) == 'userdata' then
    path = cwd.file_path
  else
    -- Compatibility with older WezTerm versions where CWD was a URI string.
    path = tostring(cwd):gsub('^file://[^/]*', '')
  end

  if not path or #path == 0 then
    return nil
  end

  path = path:gsub('[\\/]+$', '')
  return path:match('([^\\/]+)$')
end

local function clean_process_name(process)
  if not process or #process == 0 then
    return ''
  end

  local name = process:gsub('.*[/\\](.*)', '%1')
  return name:gsub('%.exe$', '')
end

-- Hide contexts that add little information to a tab title.
-- In particular, HOME and drive roots add little useful context.
local function useful_context(cwd)
  if not cwd or #cwd == 0 then
    return nil
  end

  -- Hide the user's home directory on every OS.  This keeps titles useful
  -- without hard-coding a Windows or Linux username.
  local home = wezterm.home_dir and wezterm.home_dir:gsub('[\\/]+$', '') or ''
  local home_name = home:match('([^\\/]+)$')
  if home_name and cwd:lower() == home_name:lower() then
    return nil
  end

  -- Windows drive roots may reduce to "C:" after extracting the final
  -- path component.  They are not useful project context.
  if cwd:match('^[A-Za-z]:$') then
    return nil
  end

  return cwd
end

local function has_unseen_output(tab)
  if tab.is_active then
    return false
  end

  for _, pane in ipairs(tab.panes) do
    if pane.has_unseen_output then
      return true
    end
  end

  return false
end

-- Keep the useful context from the previous config, but present it in the
-- "process/profile ~ context" style used by the reference repo.
local function smart_tab_title(tab)
  -- Respect a title explicitly assigned by the user.
  if tab.tab_title and #tab.tab_title > 0 then
    return tab.tab_title
  end

  local pane = tab.active_pane
  local pane_title = pane.title or ''
  local title_lower = pane_title:lower()
  local cwd = useful_context(cwd_name(tab))
  local process = clean_process_name(pane.foreground_process_name)

  -- If a shell/SSH wrapper publishes a useful host in its pane title, keep it.
  -- Machine-specific hostnames themselves belong in local.lua, not here.
  local ssh_host = pane_title:match('[Ss][Ss][Hh]%s*[~:%-]?%s*([%w%._%-]+)')
  if ssh_host and ssh_host:lower() ~= 'ssh' then
    return 'SSH ~ ' .. ssh_host
  end

  -- Git Bash normally publishes MINGW in its pane title.
  if title_lower:find('mingw', 1, true) then
    return cwd and ('Git Bash ~ ' .. cwd) or 'Git Bash'
  end

  -- The Conda CMD launch profile sets the console title to Conda.
  if title_lower:find('conda', 1, true) then
    return cwd and ('Conda ~ ' .. cwd) or 'Conda'
  end

  -- Generic tabs follow the same basic idea as the reference repo:
  -- process name + useful context, rather than a long raw pane title.
  if process:lower() == 'ssh' then
    return cwd and ('SSH ~ ' .. cwd) or 'SSH'
  end

  if cwd and process ~= '' then
    return process .. ' ~ ' .. cwd
  end

  if cwd then
    return cwd
  end

  if process ~= '' then
    return process
  end

  if pane_title ~= '' then
    return pane_title
  end

  return 'Terminal'
end

local function fit_title(text, width)
  width = math.max(1, width)

  local current = wezterm.column_width(text)
  if current > width then
    return wezterm.truncate_right(text, width)
  end

  return text .. string.rep(' ', width - current)
end

wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local bg
  local fg

  if tab.is_active then
    bg = TAB_COLORS.active_bg
    fg = TAB_COLORS.active_fg
  elseif hover then
    bg = TAB_COLORS.hover_bg
    fg = TAB_COLORS.hover_fg
  else
    bg = TAB_COLORS.inactive_bg
    fg = TAB_COLORS.inactive_fg
  end

  local unseen = has_unseen_output(tab)
  local index = tostring(tab.tab_index + 1)
  local title = index .. '  ' .. smart_tab_title(tab)

  -- 2 cells for the rounded ends, 2 for inner padding, and 2 more when the
  -- unseen-output indicator is present. Padding shorter titles makes the tabs
  -- visually uniform, while WezTerm can still reduce max_width when needed.
  local inset = unseen and 6 or 4
  title = fit_title(title, max_width - inset)

  local items = {
    { Background = { Color = TAB_COLORS.bar } },
    { Foreground = { Color = bg } },
    { Text = TAB_LEFT },

    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
    { Text = ' ' .. title },
  }

  if unseen then
    table.insert(items, { Foreground = { Color = TAB_COLORS.unseen } })
    table.insert(items, { Text = ' ' .. UNSEEN })
  end

  table.insert(items, { Background = { Color = bg } })
  table.insert(items, { Foreground = { Color = fg } })
  table.insert(items, { Text = ' ' })

  table.insert(items, { Background = { Color = TAB_COLORS.bar } })
  table.insert(items, { Foreground = { Color = bg } })
  table.insert(items, { Text = TAB_RIGHT })

  return items
end)

--config.color_scheme = 'Gruvbox Dark (Gogh)'
--config.color_scheme = 'Dracula'
--config.color_scheme = 'OneDark (base16)'
--config.color_scheme = 'Monokai Pro Ristretto (Gogh)'
--config.color_scheme = 'Monokai Pro (Gogh)'

local scheme = wezterm.color.get_builtin_schemes()['Monokai Pro (Gogh)']
--scheme.background = '#1e1e1e'
--scheme.background = '#181818'
scheme.background = '#101010'

config.color_schemes = {
  ['Monokai Pro Dark'] = scheme,
}

config.color_scheme = 'Monokai Pro Dark'

-- Launch profiles
-- Add new profiles with add_profile(label, args [, cwd]).
local launch_menu = {}

local function add_profile(label, args, cwd)
  local profile = {
    label = label,
    args = args,
  }

  if cwd then
    profile.cwd = cwd
  end

  table.insert(launch_menu, profile)
end

-- Machine-specific profiles live in wezterm/local.lua.  That file is ignored
-- by Git so work paths, hostnames, and IP addresses do not leak into the
-- shared dotfiles repository.  Copy local.example.lua to local.lua on each
-- machine and customize it there.
local function current_file_dir()
  local source = debug.getinfo(1, 'S').source
  if source:sub(1, 1) == '@' then
    return source:sub(2):match('^(.*)[/\\]')
  end
  return wezterm.config_dir
end

local local_config = current_file_dir() .. '/local.lua'
local ok, local_profiles = pcall(dofile, local_config)
if ok and type(local_profiles) == 'function' then
  local_profiles(wezterm, config, add_profile)
end

config.launch_menu = launch_menu

return config
