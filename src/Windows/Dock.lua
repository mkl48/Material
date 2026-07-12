--- An OS-style taskbar of minimized windows. When a [[Window]] is minimized it
--- appears here as a button; click it to restore. The dock is fed automatically
--- by the [[WindowController]] and hides itself when empty.
---
--- ```lua turn the dock on
--- Material.Dock.setEnabled(true)   -- off by default
--- ```
--- @section Windows
--- @client

local Players = game:GetService("Players")

local root = script.Parent.Parent
local Janitor = require(root.Packages.Janitor)
local UI = require(root.UI)
local Skin = require(root.Skin)
local WindowController = require(script.Parent.WindowController)

local Dock = {}
Dock.enabled = false

local janitor = Janitor.new()
local bar: Frame? = nil
local buttons: { [string]: TextButton } = {}

local function build(): Frame
	if bar then
		return bar
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = UI.new("ScreenGui", {
		Name = "MaterialDock",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = WindowController.baseDisplayOrder - 1,
		Parent = playerGui,
	})
	local frame = UI.new("Frame", {
		Name = "Dock",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Skin.Header,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = screenGui,
	}, {
		UI.corner(UDim.new(0, 12)),
		UI.stroke(Skin.Stroke, 1, 0.3),
		UI.padding(6),
		UI.list(Enum.FillDirection.Horizontal, 6),
	})
	bar = frame
	return frame
end

local function refreshVisibility()
	if bar then
		bar.Visible = next(buttons) ~= nil
	end
end

local function addButton(window: any)
	if not Dock.enabled or buttons[window.UID] then
		return
	end
	local frame = build()
	local button = UI.new("TextButton", {
		Name = "DockItem",
		Size = UDim2.fromOffset(150, 32),
		BackgroundColor3 = Skin.SurfaceRaised,
		AutoButtonColor = true,
		Text = "  " .. window.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Skin.Font,
		TextColor3 = Skin.Text,
		TextSize = 13,
		Parent = frame,
	}, { UI.corner(UDim.new(0, 8)) })
	button.Activated:Connect(function()
		window:restore()
	end)
	buttons[window.UID] = button
	refreshVisibility()
end

local function removeButton(window: any)
	local button = buttons[window.UID]
	if button then
		button:Destroy()
		buttons[window.UID] = nil
		refreshVisibility()
	end
end

--- Turns the dock on or off. Off by default — enable it if you want minimized
--- windows to collect in a taskbar rather than just vanishing.
function Dock.setEnabled(bool: boolean)
	Dock.enabled = bool
	if bool then
		janitor:add(WindowController.windowMinimized:Connect(addButton))
		janitor:add(WindowController.windowRestored:Connect(removeButton))
		janitor:add(WindowController.windowUnregistered:Connect(removeButton))
	else
		janitor:clean()
		for uid, button in buttons do
			button:Destroy()
			buttons[uid] = nil
		end
		refreshVisibility()
	end
	return Dock
end

--- Returns the dock's Frame (building it on first call), for custom styling.
function Dock.getInstance(): Frame
	return build()
end

return Dock
