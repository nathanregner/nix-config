local M = {}

M.num_of_screens = 0

M.config = {}

M.target_display = function(screen_index)
  ---@type hs.screen[]
  ---@diagnostic disable-next-line: assign-type-mismatch
  local screens = hs.screen.allScreens()
  if screens[screen_index] ~= nil then
    return screens[screen_index]
  else
    return hs.screen.primaryScreen()
  end
end

M.auto_layout = function()
  for app_name, app_config in pairs(M.config.applications) do
    if app_config.preferred_display ~= nil then
      local application = hs.application.find(app_config.bundleID)
      if application == nil or application:mainWindow() == nil then goto continue end

      local target_space = app_config.preferred_space
      local target_screen = M.target_display(app_config.preferred_display)
      print("Moving ", app_name, " to screen", target_screen)

      application:mainWindow():moveToScreen(target_screen, false, true, 0):moveToUnit(hs.layout.maximized)

      -- FIXME: https://github.com/Hammerspoon/hammerspoon/issues/3698
      if target_space ~= nil then
        -- create workspaces
        local spaces = hs.spaces.spacesForScreen(target_screen)
        while #spaces < target_space and hs.spaces.addSpaceToScreen(target_screen) do
          spaces = #hs.spaces.spacesForScreen(target_screen)
        end
        local space_id = spaces[target_space]
        print("Moving ", app_name, " to space", space_id)
        print(hs.spaces.moveWindowToSpace(application:mainWindow(), space_id, true))
      end
    end
    ::continue::
  end
end

-- initialize watchers
M.start = function(config)
  M.config = config
  M.auto_layout()

  local num_of_screens = #hs.screen.allScreens()
  hs.screen.watcher
    .new(function()
      if num_of_screens ~= #hs.screen.allScreens() then
        M.auto_layout()
        num_of_screens = #hs.screen.allScreens()
      end
    end)
    :start()
end

return M
