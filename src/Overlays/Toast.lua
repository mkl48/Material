--- Transient snackbar notifications that stack in a screen corner and dismiss
--- themselves — distinct from an [[Icon]]'s notice badge. Fire-and-forget:
--- one call shows a message, optionally with an action button.
---
--- ```lua a toast with an action
--- Material.Toast.show("Item purchased", {
---     duration = 4,
---     action = "Undo",
---     onAction = function() refund() end,
--- })
--- ```
--- @section Overlays
--- @client

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Types = require(root.Types)
local UI = require(root.UI)
local Skin = require(root.Skin)

local Toast = {}

export type Options = Types.ToastOptions

local TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local container: Frame? = nil

local function build(): Frame
	if container then
		return container
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = UI.new("ScreenGui", {
		Name = "MaterialToasts",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		Parent = playerGui,
	})
	local frame = UI.new("Frame", {
		Name = "ToastStack",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(380, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = screenGui,
	}, {
		UI.list(Enum.FillDirection.Vertical, 8),
	})
	local layout = frame:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	container = frame
	return frame
end

--- Shows a toast. Returns a `dismiss` function you can call to remove it early;
--- otherwise it fades out after `options.duration` seconds.
--- @param text the message
--- @param options duration, an optional action button, accent colour
function Toast.show(text: string, options: Options?): () -> ()
	local opts = options or {}
	local stack = build()

	local toast = UI.new("Frame", {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Skin.Panel,
		BackgroundTransparency = 1,
		Parent = stack,
	}, {
		UI.corner(UDim.new(0, 10)),
		UI.stroke(Skin.Stroke, 1, 0.9),
		UI.padding(12),
		UI.list(Enum.FillDirection.Horizontal, 10),
	})
	;(toast:FindFirstChildOfClass("UIListLayout") :: UIListLayout).VerticalAlignment = Enum.VerticalAlignment.Center

	local iconImage: ImageLabel? = nil
	if opts.icon then
		iconImage = UI.new("ImageLabel", {
			Name = "Icon",
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1,
			Image = if tonumber(opts.icon) then `rbxassetid://{opts.icon}` else opts.icon,
			ImageColor3 = Skin.Text,
			ImageTransparency = 1,
			LayoutOrder = 0,
			Parent = toast,
		}) :: ImageLabel
	end

	local textInset = (if opts.action then 90 else 0) + (if iconImage then 32 else 0) + 4
	local label = UI.new("TextLabel", {
		Name = "Message",
		Size = UDim2.new(1, -textInset, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		FontFace = Skin.FontFace,
		Text = text,
		TextColor3 = Skin.Text,
		TextSize = 15,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = toast,
	})
	label.TextTransparency = 1

	local dismissed = false
	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true
		TweenService:Create(toast, TWEEN, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, TWEEN, { TextTransparency = 1 }):Play()
		if iconImage then
			TweenService:Create(iconImage, TWEEN, { ImageTransparency = 1 }):Play()
		end
		local tween = TweenService:Create(toast, TWEEN, { Size = UDim2.new(1, 0, 0, 0) })
		tween:Play()
		tween.Completed:Once(function()
			toast:Destroy()
		end)
	end

	if opts.action then
		local button = UI.new("TextButton", {
			Name = "Action",
			Size = UDim2.fromOffset(70, 28),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = opts.color or Skin.Accent,
			AutoButtonColor = true,
			Text = opts.action,
			FontFace = Skin.TitleFontFace,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			LayoutOrder = 2,
			Parent = toast,
		}, { UI.corner(UDim.new(0, 6)) })
		button.Activated:Connect(function()
			if opts.onAction then
				opts.onAction()
			end
			dismiss()
		end)
	end

	-- fade in
	TweenService:Create(toast, TWEEN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(label, TWEEN, { TextTransparency = 0 }):Play()
	if iconImage then
		TweenService:Create(iconImage, TWEEN, { ImageTransparency = 0 }):Play()
	end

	task.delay(opts.duration or 3, dismiss)
	return dismiss
end

return (Toast :: any) :: Types.Toast
