-- https://gist.github.com/xgungnir/a02f059b29adacaf7df884920e127533

-- Module state
obj.isMoving = false
obj.movingTimeout = nil -- Safety timeout timer to auto-reset isMoving

-- Constants
local MOUSE_OFFSET_X = 5
local MOUSE_OFFSET_Y = 18
local RELEASE_DELAY = 0.6
local MOVING_TIMEOUT_DURATION = 2.0 -- Maximum time before force-resetting isMoving

-- Helper to safely reset isMoving state and cancel timeout
local function resetMovingState(self)
  if self.movingTimeout then
    self.movingTimeout:stop()
    self.movingTimeout = nil
  end
  self.isMoving = false
end

-- Helper to start moving state with safety timeout
local function startMovingState(self)
  self.isMoving = true
  -- Cancel any existing timeout
  if self.movingTimeout then self.movingTimeout:stop() end
  -- Set safety timeout to auto-reset isMoving in case of failure
  self.movingTimeout = obj.hs.timer.doAfter(MOVING_TIMEOUT_DURATION, function()
    if self.isMoving then
      obj.hs.printf("[window.lua] Safety timeout: resetting isMoving after %.1fs", MOVING_TIMEOUT_DURATION)
      self.isMoving = false
    end
    self.movingTimeout = nil
  end)
end

local function simulateKeyEvent(modifier, key, callback)
  -- Post modifier key down
  obj.hs.eventtap.event.newKeyEvent(modifier, true):post()
  obj.hs.timer.doAfter(0.02, function()
    -- Post arrow key down
    obj.hs.eventtap.event.newKeyEvent(key, true):post()
    obj.hs.timer.doAfter(0.02, function()
      -- Release arrow key, then modifier
      obj.hs.eventtap.event.newKeyEvent(key, false):post()
      obj.hs.eventtap.event.newKeyEvent(modifier, false):post()
      if callback then callback() end
    end)
  end)
end

-- Shared helper to move window across spaces using async timer chain (no blocking usleep)
local function moveWindowAcrossSpace(self, direction)
  if self.isMoving then return end
  startMovingState(self)

  -- Get current active window and make it frontmost
  local win = self.hs.window.focusedWindow()
  if not win then
    resetMovingState(self)
    return
  end

  -- Guard: Finder Desktop pseudo-window can be larger than the screen resolution
  local app = win:application()
  local bundleID = app:bundleID()
  local screen = win:screen()
  local screenFrame = screen:frame()
  local winFrame = win:frame()
  if bundleID == "com.apple.finder" and winFrame.w > screenFrame.w and winFrame.h > screenFrame.h then
    resetMovingState(self)
    return
  end

  win:unminimize()
  win:raise()

  -- Bounds check based on direction
  local spaces = self.hs.spaces.spacesForScreen()
  local currentSpace = self.hs.spaces.focusedSpace()
  if direction == "right" then
    if currentSpace == spaces[#spaces] then
      self.hs.alert.show("Already at the rightmost desktop.")
      resetMovingState(self)
      return
    end
  else
    if currentSpace == spaces[1] then
      self.hs.alert.show("Already at the leftmost desktop.")
      resetMovingState(self)
      return
    end
  end

  -- Capture window position for drag-and-restore sequence
  local frame = win:frame()
  local originalFrame = { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
  local clickPos = self.hs.geometry.point(frame.x + MOUSE_OFFSET_X, frame.y + MOUSE_OFFSET_Y)
  local centerPos = self.hs.geometry.point(frame.x + frame.w / 2, frame.y + frame.h / 2)

  -- Forward declare step functions for async chain
  local step2_mouseDown, step3_dragWindow, step4_triggerDesktopSwitch, step5_releaseAndRestore

  -- Step 1: Move mouse to click position
  local function step1_moveMouse()
    self.hs.mouse.absolutePosition(clickPos)
    self.hs.timer.doAfter(0.02, step2_mouseDown) -- 20ms delay
  end

  -- Step 2: Mouse down on title bar
  step2_mouseDown = function()
    self.hs.eventtap.event.newMouseEvent(self.hs.eventtap.event.types.leftMouseDown, clickPos):post()
    self.hs.timer.doAfter(0.03, step3_dragWindow) -- 30ms delay
  end

  -- Step 3: Drag to establish drag state (required for macOS to recognize window-move gesture)
  step3_dragWindow = function()
    -- Post a small drag event to register the drag gesture
    local adjustedPos = self.hs.geometry.point(clickPos.x + 1, clickPos.y)
    self.hs.eventtap.event
      .newMouseEvent(self.hs.eventtap.event.types.leftMouseDragged, adjustedPos)
      :setProperty(self.hs.eventtap.event.properties.mouseEventDeltaX, 1)
      :post()

    -- Wait for drag state to register, then trigger desktop switch
    self.hs.timer.doAfter(0.05, step4_triggerDesktopSwitch)
  end

  -- Step 4: Trigger desktop switch via keyboard shortcut
  step4_triggerDesktopSwitch = function()
    -- Yield to event loop to ensure drag is processed
    self.hs.timer.doAfter(0, function()
      local key = (direction == "right") and "right" or "left"
      -- Use async keyboard simulation to avoid blocking
      simulateKeyEvent("ctrl", key, function()
        -- Schedule release after desktop animation
        self.hs.timer.doAfter(RELEASE_DELAY, step5_releaseAndRestore)
      end)
    end)
  end

  -- Step 5: Release mouse and restore window state
  step5_releaseAndRestore = function()
    local finalPos = self.hs.mouse.absolutePosition()
    self.hs.eventtap.event.newMouseEvent(self.hs.eventtap.event.types.leftMouseUp, finalPos):post()
    -- Restore original frame to undo the 1px drag offset
    -- Use doAfter to ensure mouse up is processed first
    self.hs.timer.doAfter(0.01, function()
      if win:isVisible() then win:setFrame(originalFrame) end
      win:raise()
      win:focus()
      self.hs.mouse.absolutePosition(centerPos)
      self.hs.timer.doAfter(0.1, function() resetMovingState(self) end)
    end)
  end

  -- Start the async sequence
  step1_moveMouse()
end

function obj:move_window_to_next_desktop() moveWindowAcrossSpace(self, "right") end

function obj:move_window_to_previous_desktop() moveWindowAcrossSpace(self, "left") end

-- ... inside obj:init()

-- move window to next/previous desktop
-- self.hs.hotkey.bind({"cmd", "ctrl"}, "i", function() self:move_window_to_next_desktop() end)
-- self.hs.hotkey.bind({"cmd", "ctrl"}, "u", function() self:move_window_to_previous_desktop() end)
