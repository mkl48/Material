--- The window manager: one singleton owning the shared `MaterialWindows`
--- ScreenGui, the registry of every open [[Window]], z-ordering and focus, the
--- optional modal backdrop, and the [[Dock]] feed. You rarely touch it
--- directly — [[Window]] registers itself — but it's the source of truth for
--- "which windows exist" and "which one is active".
---
--- ```lua react to any window opening
--- Material.WindowController.windowRegistered:Connect(function(window)
---     print("opened", window.title)
--- end)
--- ```
--- @section Windows
--- @client

local Players = game:GetService("Players")

local root = script.Parent.Parent
local Signal = require(root.Packages.GoodSignal)
local UI = require(root.UI)
local Skin = require(root.Skin)

local WindowController = {}
WindowController.windows = {}                         -- [UID] = Window
WindowController.activeWindow = nil                   -- the focused Window, or nil
WindowController.windowRegistered = Signal.new()      -- (window)
WindowController.windowUnregistered = Signal.new()    -- (window)
WindowController.windowMinimized = Signal.new()       -- (window)
WindowController.windowRestored = Signal.new()        -- (window)
WindowController.activeChanged = Signal.new()         -- (window | nil)
WindowController.baseDisplayOrder = 50

local topZ = 0
local layer: ScreenGui? = nil
local backdrop: Frame? = nil

local function buildLayer(): ScreenGui
	if layer then
		return layer
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = UI.new("ScreenGui", {
		Name = "MaterialWindows",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = WindowController.baseDisplayOrder,
		Parent = playerGui,
	})
	backdrop = UI.new("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Skin.Backdrop,
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 0,
		Parent = screenGui,
	}) :: Frame
	layer = screenGui
	return screenGui
end

--- Returns the shared ScreenGui every window is parented to, building it (and
--- the modal backdrop) on first call.
function WindowController.getLayer(): ScreenGui
	return buildLayer()
end

--- Returns the shared modal backdrop frame (behind the active modal window).
function WindowController.getBackdrop(): Frame
	buildLayer()
	return backdrop :: Frame
end

--- Registers a window and focuses it. Called by [[Window]] on open.
function WindowController.register(window: any)
	WindowController.windows[window.UID] = window
	WindowController.windowRegistered:Fire(window)
	WindowController.focus(window)
end

-- when the active window goes away (close/minimize), raise the next top-most
local function promoteNext(goneWindow: any)
	if WindowController.activeWindow ~= goneWindow then
		return
	end
	WindowController.activeWindow = nil
	local topMost, bestZ = nil, -math.huge
	for _, other in WindowController.windows do
		if other ~= goneWindow and other.isOpen and not other.isMinimized and other._z > bestZ then
			topMost, bestZ = other, other._z
		end
	end
	if topMost then
		WindowController.focus(topMost)
	else
		WindowController.activeChanged:Fire(nil)
	end
end

--- Unregisters a window and, if it was active, promotes the next top-most
--- window (or clears the active window). Called by [[Window]] on close.
function WindowController.unregister(window: any)
	if WindowController.windows[window.UID] == nil then
		return
	end
	WindowController.windows[window.UID] = nil
	WindowController.windowUnregistered:Fire(window)
	promoteNext(window)
end

--- Called by [[Window:minimize]]: keeps the window registered (so the [[Dock]]
--- can list it) but yields focus to the next top-most window.
function WindowController.notifyMinimized(window: any)
	WindowController.windowMinimized:Fire(window)
	promoteNext(window)
end

--- Called by [[Window:restore]] when a minimized window returns.
function WindowController.notifyRestored(window: any)
	WindowController.windowRestored:Fire(window)
end

--- Brings a window to the front and marks it active — raising its ZIndex above
--- every other window and firing the `activeChanged` signal.
function WindowController.focus(window: any)
	topZ += 1
	window._z = topZ
	if window.root then
		window.root.ZIndex = topZ
	end
	if WindowController.activeWindow ~= window then
		WindowController.activeWindow = window
		WindowController.activeChanged:Fire(window)
	end
end

--- Returns the registry of open windows, keyed by UID.
function WindowController.getWindows()
	return WindowController.windows
end

--- Closes every open window.
function WindowController.closeAll()
	for _, window in WindowController.windows do
		window:close()
	end
end

return WindowController
