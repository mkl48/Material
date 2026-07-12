--- Centered confirm/prompt modals — like Roblox's respawn dialog. A dimmed
--- backdrop, a themed panel, a message, and a row of buttons that are real
--- [[Icon]]s (so they match the theme). Self-contained: not tied to a topbar
--- icon.
---
--- ```lua a confirm dialog
--- Material.Dialog.confirm("Delete this save? This cannot be undone.", function()
---     deleteSave()
--- end)
--- ```
--- @section Overlays
--- @client

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Types = require(root.Types)
local UI = require(root.UI)
local Skin = require(root.Skin)

local Dialog = {}

export type Button = Types.DialogButton
export type Options = Types.DialogOptions

local OPEN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local layer: ScreenGui? = nil

local function getLayer(): ScreenGui
	if layer then
		return layer
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	layer = UI.new("ScreenGui", {
		Name = "MaterialDialogs",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 60,
		Parent = playerGui,
	}) :: ScreenGui
	return layer :: ScreenGui
end

--- Shows a modal dialog. Returns a handle with `:close()`.
function Dialog.show(options: Options): any
	local Icon = require(root) :: any  -- lazy: the Material module (avoids a load cycle)
	local width = options.width or 460
	local height = 240

	local backdrop = UI.new("Frame", {
		Name = "DialogBackdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Skin.Backdrop,
		BackgroundTransparency = 1,
		Parent = getLayer(),
	})

	local panel = UI.new("Frame", {
		Name = "DialogPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Skin.Panel,
		BorderSizePixel = 0,
		Parent = backdrop,
	}, {
		UI.corner(Skin.CornerRadius),
		UI.stroke(Skin.Stroke, 1, Skin.StrokeTransparency),
		UI.new("UIPadding", {
			PaddingTop = UDim.new(0, 30), PaddingBottom = UDim.new(0, 26),
			PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 30),
		}),
	})

	UI.new("ImageLabel", {
		Name = "DialogShadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 40, 1, 40),
		BackgroundTransparency = 1,
		Image = Skin.ShadowImage,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(12, 12, 13, 13),
		ZIndex = 0,
		Parent = panel,
	})

	UI.new("TextLabel", {
		Name = "Message",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, 0, 1, -64),
		BackgroundTransparency = 1,
		FontFace = Skin.TitleFontFace,
		Text = options.message,
		TextColor3 = Skin.Text,
		TextSize = 20,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = panel,
	})

	local buttonRow = UI.new("Frame", {
		Name = "Buttons",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = panel,
	}, {
		UI.list(Enum.FillDirection.Horizontal, 12),
	})
	;(buttonRow:FindFirstChildOfClass("UIListLayout") :: UIListLayout).HorizontalAlignment = Enum.HorizontalAlignment.Center

	local buttonIcons = {}
	local function close()
		for _, btn in buttonIcons do
			btn:destroy()
		end
		local tween = TweenService:Create(backdrop, OPEN, { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Once(function()
			backdrop:Destroy()
		end)
	end

	local buttons = options.buttons or { { text = "OK", primary = true } }
	for index, spec in buttons do
		local fill = if spec.danger then Skin.Danger elseif spec.primary then Skin.Accent else Skin.Panel
		local holder = UI.new("Frame", {
			Name = "ButtonHolder",
			Size = UDim2.fromOffset(150, 46),
			BackgroundTransparency = 1,
			LayoutOrder = index,
			ZIndex = 2,
			Parent = buttonRow,
		}, {
			UI.corner(UDim.new(0, 10)),
			UI.stroke(
				if spec.primary or spec.danger then Color3.new(1, 1, 1) else Skin.Stroke,
				if spec.primary or spec.danger then 2 else 1,
				if spec.primary or spec.danger then 0 else 0.7
			),
		})
		local btn = Icon.new()
		btn:modifyTheme({
			{ "IconLabel", "Text", spec.text, "Deselected" },
			{ "IconLabel", "Text", spec.text, "Selected" },
			{ "IconLabel", "FontFace", Skin.TitleFontFace },
			{ "IconLabel", "TextSize", 16 },
			{ "IconLabel", "TextColor3", Color3.new(1, 1, 1) },
			{ "IconImage", "Image", "" },
			{ "Widget", "MinimumWidth", 150 },
			{ "Widget", "MinimumHeight", 46 },
			{ "IconButton", "BackgroundColor3", fill, "Deselected" },
			{ "IconButton", "BackgroundColor3", fill, "Selected" },
			{ "IconButton", "BackgroundTransparency", 0, "Deselected" },
			{ "IconCorners", "CornerRadius", UDim.new(0, 10) },
		})
		btn:oneClick(true)
		btn:autoDeselect(false)  -- don't disturb the user's topbar icons
		btn.widget.Parent = holder
		btn.widget.Position = UDim2.fromScale(0, 0)
		table.insert(buttonIcons, btn)
		btn.selected:Connect(function()
			if spec.onClick then
				spec.onClick()
			end
			close()
		end)
	end

	-- dismiss on backdrop click
	if options.dismissable ~= false then
		backdrop.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				close()
			end
		end)
	end

	-- fade + scale in
	TweenService:Create(backdrop, OPEN, { BackgroundTransparency = 0.5 }):Play()
	panel.Size = UDim2.fromOffset(width * 0.96, height * 0.96)
	TweenService:Create(panel, OPEN, { Size = UDim2.fromOffset(width, height) }):Play()

	return { close = close }
end

--- Convenience: a two-button confirm/cancel dialog.
--- @param message the prompt text
--- @param onConfirm runs if the user confirms
--- @param onCancel optional, runs if the user cancels
function Dialog.confirm(message: string, onConfirm: () -> (), onCancel: (() -> ())?): any
	return Dialog.show({
		message = message,
		buttons = {
			{ text = "Cancel", onClick = onCancel },
			{ text = "Confirm", primary = true, onClick = onConfirm },
		},
	})
end

return (Dialog :: any) :: Types.Dialog
