--- Rich hover tooltips for *any* GuiObject, not just icons. Attach one to a
--- button, a frame, anything — it follows the pointer, fades in after a short
--- delay, and cleans itself up. Returns a disconnect function.
---
--- ```lua tooltip on a custom button
--- Material.Tooltip.attach(myButton, "Buy 100 gems")
--- ```
--- @section Overlays
--- @client

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local UI = require(root.UI)
local Skin = require(root.Skin)

local Tooltip = {}

local TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOVER_DELAY = 0.4
local layer: ScreenGui? = nil

local function getLayer(): ScreenGui
	if layer then
		return layer
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	layer = UI.new("ScreenGui", {
		Name = "MaterialTooltips",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 200,
		Parent = playerGui,
	}) :: ScreenGui
	return layer :: ScreenGui
end

--- Attaches a tooltip to a GuiObject. Returns a function that removes it.
--- @param guiObject the element to hover
--- @param text the tooltip text (re-read each hover, so a function-less string is fine)
function Tooltip.attach(guiObject: GuiObject, text: string): () -> ()
	local hovering = false
	local bubble: Frame? = nil
	local moveConn: RBXScriptConnection? = nil

	local function hide()
		hovering = false
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
		local current = bubble
		bubble = nil
		if current then
			local tween = TweenService:Create(current, TWEEN, { BackgroundTransparency = 1 })
			tween:Play()
			tween.Completed:Once(function()
				current:Destroy()
			end)
		end
	end

	local function show()
		if bubble then
			return
		end
		local frame = UI.new("Frame", {
			Name = "Tooltip",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = Skin.Header,
			BackgroundTransparency = 1,
			Parent = getLayer(),
		}, {
			UI.corner(UDim.new(0, 6)),
			UI.stroke(Skin.Stroke, 1, 0.3),
			UI.padding(8),
		})
		UI.new("TextLabel", {
			Name = "Text",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Font = Skin.Font,
			Text = text,
			TextColor3 = Skin.Text,
			TextSize = 13,
			Parent = frame,
		})
		bubble = frame
		TweenService:Create(frame, TWEEN, { BackgroundTransparency = 0 }):Play()

		local function follow()
			local pos = UserInputService:GetMouseLocation()
			frame.Position = UDim2.fromOffset(pos.X + 16, pos.Y + 8)
		end
		follow()
		moveConn = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				follow()
			end
		end)
	end

	local enterConn = guiObject.MouseEnter:Connect(function()
		hovering = true
		task.delay(HOVER_DELAY, function()
			if hovering then
				show()
			end
		end)
	end)
	local leaveConn = guiObject.MouseLeave:Connect(hide)
	local destroyConn = guiObject.Destroying:Once(function()
		hide()
	end)

	return function()
		enterConn:Disconnect()
		leaveConn:Disconnect()
		destroyConn:Disconnect()
		hide()
	end
end

return Tooltip
