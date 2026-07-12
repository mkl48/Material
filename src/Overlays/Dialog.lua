--- Centered confirm/prompt dialogs — a thin preset over a modal [[Window]]
--- (non-resizable, dimmed backdrop, a message and a row of buttons). Use it for
--- "Are you sure?" moments without hand-building a window.
---
--- ```lua a confirm dialog
--- Material.Dialog.confirm("Delete this save? This cannot be undone.", function()
---     deleteSave()
--- end)
--- ```
--- @section Overlays
--- @client

local root = script.Parent.Parent
local Types = require(root.Types)
local UI = require(root.UI)
local Skin = require(root.Skin)
local Window = require(root.Windows.Window)

local Dialog = {}

export type Button = Types.DialogButton
export type Options = Types.DialogOptions

--- Shows a modal dialog and returns its [[Window]] (already open). Headerless
--- and centered, like Roblox's respawn/confirm modals.
function Dialog.show(options: Options): any
	local width = options.width or 460
	local window = Window.new()
		:setSize(width, 240)
		:setResizable(false)
		:setModal(true, options.dismissable ~= false)
		:setHeaderVisible(false)
	window:center()

	local body = window:getBody()
	UI.new("UIPadding", {
		PaddingTop = UDim.new(0, 30), PaddingBottom = UDim.new(0, 26),
		PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 30),
		Parent = body,
	})

	-- title / message, centered in the upper area (Roblox modal style)
	UI.new("TextLabel", {
		Name = "Message",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, 0, 1, -64),
		BackgroundTransparency = 1,
		Font = Skin.TitleFont,
		Text = options.message,
		TextColor3 = Skin.Text,
		TextSize = 20,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = body,
	})

	-- buttons, centered along the bottom
	local buttonRow = UI.new("Frame", {
		Name = "Buttons",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = body,
	}, {
		UI.list(Enum.FillDirection.Horizontal, 12),
	})
	;(buttonRow:FindFirstChildOfClass("UIListLayout") :: UIListLayout).HorizontalAlignment = Enum.HorizontalAlignment.Center

	local buttons = options.buttons or { { text = "OK", primary = true } }
	for index, spec in buttons do
		local fill = if spec.danger then Skin.Danger elseif spec.primary then Skin.Accent else Skin.SurfaceRaised
		local button = UI.new("TextButton", {
			Name = "DialogButton",
			Size = UDim2.fromOffset(150, 46),
			BackgroundColor3 = fill,
			AutoButtonColor = true,
			Text = spec.text,
			Font = Skin.TitleFont,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 16,
			LayoutOrder = index,
			Parent = buttonRow,
		}, { UI.corner(UDim.new(0, 10)) })
		-- primary/danger get a white selection ring; others a faint outline
		if spec.primary or spec.danger then
			UI.new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = button })
		else
			UI.new("UIStroke", { Color = Skin.Stroke, Thickness = 1, Transparency = 0.7, Parent = button })
		end
		button.Activated:Connect(function()
			if spec.onClick then
				spec.onClick()
			end
			window:close()
			window:destroy()
		end)
	end

	window:open()
	return window
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
