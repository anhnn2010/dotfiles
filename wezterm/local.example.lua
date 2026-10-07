-- Machine-specific WezTerm launch profiles.
-- Copy this file to local.lua and edit it for the current machine.
-- local.lua is ignored by Git.

return function(wezterm, config, add_profile)
  if wezterm.target_triple:find('windows') then
    add_profile('CMD', { 'cmd.exe' })

    -- Example:
    -- add_profile('Conda CMD', {
    --   'cmd.exe',
    --   '/K',
    --   'C:\\path\\to\\Scripts\\activate.bat C:\\path\\to\\env',
    -- })

    -- Example SSH launcher:
    -- add_profile('SSH Lab', {
    --   'cmd.exe',
    --   '/K',
    --   'C:\\path\\to\\ssh_lab.bat',
    -- })
  end

  -- Linux normally needs no explicit profile; WezTerm starts the user's
  -- login shell automatically.  Add one here only if you want alternatives.
  -- if wezterm.target_triple:find('linux') then
  --   add_profile('Fish', { '/usr/bin/fish' })
  -- end
end
