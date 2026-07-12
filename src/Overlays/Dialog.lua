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
local UI = require(root.UI)
local Skin = require(root.Skin)
local Window = require(root.Windows.Window)

local Dialog = {}

export type Button = {
	text: string,
	primary: boolean?,       -- accent-filled instead of subtle
	danger: boolean?,        -- danger-coloured
	onClick: (() -> ())?,    -- runs before the dialog closes
}

export type Options = {
	title: string?,
	message: string,
	buttons: { Button }?,    -- defaults to a single "OK"
	dismissable: boolean?,   -- click backdrop / close button to dismiss (default true)
	width: number?,
}

--- Shows a modal dialog and returns its [[Window]] (already open).
function Dialog.show(options: Options): any
	local width = options.width or 380
	local window = Window.new()
		:setTitle(options.title or "")
		:setSize(width, 180)
		:setResizable(false)
		:setModal(true, options.dismissable ~= false)
	window:center()

	local body = window:getBody()
	UI.new("UIPadding", {
		PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18),
		Parent = body,
	})

	UI.new("TextLabel", {
		Name = "Message",
		Size = UDim2.new(1, 0, 1, -48),
		BackgroundTransparency = 1,
		Font = Skin.Font,
		Text = options.message,
		TextColor3 = Skin.Text,
		TextSize = 15,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = body,
	})

	local buttonRow = UI.new("Frame", {
		Name = "Buttons",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = body,
	}, {
		UI.list(Enum.FillDirection.Horizontal, 8),
	})
	local layout = buttonRow:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right

	local buttons = options.buttons or { { text = "OK", primary = true } }
	for index, spec in buttons do
		local fill = if spec.danger then Skin.Danger elseif spec.primary then Skin.Accent else Skin.SurfaceRaised
		local textColor = if spec.primary or spec.danger then Color3.new(1, 1, 1) else Skin.Text
		local button = UI.new("TextButton", {
			Name = "DialogButton",
			Size = UDim2.fromOffset(96, 34),
			BackgroundColor3 = fill,
			AutoButtonColor = true,
			Text = spec.text,
			Font = Enum.Font.GothamMedium,
			TextColor3 = textColor,
			TextSize = 14,
			LayoutOrder = index,
			Parent = buttonRow,
		}, { UI.corner(UDim.new(0, 7)) })
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

return Dialog
