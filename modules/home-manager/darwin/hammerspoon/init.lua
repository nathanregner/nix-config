-- Tap control for `escape` and hold for `control`
hs.loadSpoon("ControlEscape"):start()
-- TODO: auto-generate
-- hs.loadSpoon("EmmyLua"):start()

---@type hs.screen[]
local screens = hs.screen.allScreens()
for _, screen in ipairs(screens) do
  print(screen:id(), screen:name())
  local spaces = hs.spaces.spacesForScreen(screen)
  print(spaces)
end

-- for i, x in ipairs(hs.application.runningApplications()) do
--   print(x:bundleID())
-- end

require("autolayout").start({
  applications = {
    ["Firefox"] = {
      bundleID = "org.mozilla.firefoxdeveloperedition",
      preferred_display = 2,
      preferred_space = 1,
    },
    ["Slack"] = {
      bundleID = "com.tinyspeck.slackmacgap",
      preferred_display = 2,
      preferred_space = 2,
    },
    ["Outlook"] = {
      bundleID = "com.microsoft.Outlook",
      preferred_display = 2,
      preferred_space = 3,
    },
  },
})
