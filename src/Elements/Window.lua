--- A window panel that belongs to an icon — it drops from the icon and grows
--- open when the icon is selected, closes when deselected, exactly like a
--- [[Dropdown]] but as a titled panel. Built onto `icon.widget` and themed
--- through the icon, so it matches the topbar (colour, ratios, BuilderSans).
---
--- Created through [[Icon:setWindow]], which returns a handle:
---
--- ```lua a shop panel that drops from its icon
--- local shop = Material.new()
---     :setImage(14723463500)
---     :setCaption("Shop")
---     :setWindow({ title = "Shop", width = 320, height = 360 })
---
--- shop:addToWindow(playerGui.ShopGui.Root)   -- add your own content
--- -- or fill it with icons, like a dropdown:
--- shop:addIcon(Material.new():setLabel("Swords"))
--- shop:addIcon(Material.new():setLabel("Potions"))
--- ```
--- @section Windows
--- @client

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local root = script.Parent.Parent
local UI = require(root.UI)
local Skin = require(root.Skin)
local Utility = require(root.Utility)

local OPEN_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

return function(icon: any, config: any)
	config = config or {}
	local Icon = require(icon.iconModule)
	local janitor = icon.windowJanitor
	local openSize = Vector2.new(config.width or 300, config.height or 320)

	-- the panel, parented into the icon's widget (clipOutside is applied by
	-- Icon:setWindow so it can exceed the widget's bounds, like a dropdown)
	local window = UI.new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 10),
		Size = UDim2.fromOffset(openSize.X, 0),
		BackgroundColor3 = Skin.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = -2,
		Visible = false,
		Parent = icon.widget,
	}, {
		UI.corner(Skin.CornerRadius),
		UI.stroke(Skin.Stroke, 1, Skin.StrokeTransparency),
	}) :: Frame

	UI.new("ImageLabel", {
		Name = "WindowShadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 40, 1, 40),
		BackgroundTransparency = 1,
		Image = Skin.ShadowImage,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(12, 12, 13, 13),
		ZIndex = -3,
		Parent = window,
	})

	-- respect each player's PreferredTransparency, like the dropdown
	icon:setBehaviour("Window", "BackgroundTransparency", function(value)
		if value == 1 then
			return value
		end
		return value * GuiService.PreferredTransparency
	end)
	janitor:add(GuiService:GetPropertyChangedSignal("PreferredTransparency"):Connect(function()
		icon:refreshAppearance(window, "BackgroundTransparency")
	end))

	-- header (title + a real close Icon on the left)
	local header = UI.new("Frame", {
		Name = "WindowHeader",
		Size = UDim2.new(1, 0, 0, Skin.HeaderHeight),
		BackgroundTransparency = 1,
		ZIndex = -1,
		Parent = window,
	})
	local title = UI.new("TextLabel", {
		Name = "WindowTitle",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 52, 0.5, 0),
		Size = UDim2.new(1, -62, 1, 0),
		BackgroundTransparency = 1,
		FontFace = Skin.TitleFontFace,
		Text = config.title or "",
		TextColor3 = Skin.Text,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = -1,
		Parent = header,
	}) :: TextLabel
	UI.new("Frame", {
		Name = "WindowDivider",
		Position = UDim2.new(0, 0, 0, Skin.HeaderHeight),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Skin.Divider,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		ZIndex = -1,
		Parent = window,
	})

	local closeHolder = UI.new("Frame", {
		Name = "WindowCloseHolder",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundTransparency = 1,
		ZIndex = -1,
		Parent = header,
	})
	local closeIcon = Icon.new()
	closeIcon:modifyTheme({
		{ "IconLabel", "Text", "\u{2715}", "Deselected" },
		{ "IconLabel", "Text", "\u{2715}", "Selected" },
		{ "IconLabel", "FontFace", Skin.TitleFontFace },
		{ "IconLabel", "TextSize", 18 },
		{ "IconImage", "Image", "" },
		{ "Widget", "MinimumWidth", 38 },
		{ "Widget", "MinimumHeight", 38 },
		{ "IconButton", "BackgroundTransparency", 1, "Deselected" },
	})
	closeIcon:oneClick(true)
	closeIcon:autoDeselect(false)
	closeIcon.widget.Parent = closeHolder
	closeIcon.widget.Position = UDim2.fromScale(0, 0)
	janitor:add(function()
		closeIcon:destroy()
	end)
	janitor:add(closeIcon.selected:Connect(function()
		icon:deselect("WindowClose", icon)
	end))

	-- body: a scrolling content area. Adopted content and joined icons both
	-- flow through its list, so a window can hold icons like a dropdown.
	local body = UI.new("ScrollingFrame", {
		Name = "WindowBody",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 1, -Skin.HeaderHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ClipsDescendants = true,
		ZIndex = -1,
		Parent = window,
	}, {
		UI.list(Enum.FillDirection.Vertical, 6),
		UI.padding(10),
	}) :: ScrollingFrame

	-- open/close on the icon's toggle: grow the height from 0 (like a dropdown)
	local windowIcons = {}
	local function resize(open: boolean)
		if open then
			window.Visible = true
			TweenService:Create(window, OPEN_TWEEN, { Size = UDim2.fromOffset(openSize.X, openSize.Y) }):Play()
		else
			local tween = TweenService:Create(window, CLOSE_TWEEN, { Size = UDim2.fromOffset(openSize.X, 0) })
			tween:Play()
			tween.Completed:Once(function()
				if not icon.isSelected then
					window.Visible = false
				end
			end)
		end
	end
	janitor:add(icon.toggled:Connect(function()
		resize(icon.isSelected)
	end))
	resize(icon.isSelected)

	-- the handle Icon:setWindow returns
	local handle = {}
	handle.frame = window
	handle.body = body
	handle.icon = icon

	function handle:setTitle(text: string)
		title.Text = text
		return handle
	end
	function handle:setSize(width: number, height: number)
		openSize = Vector2.new(width, height)
		window.Size = UDim2.fromOffset(width, if icon.isSelected then height else 0)
		return handle
	end
	function handle:getBody(): ScrollingFrame
		return body
	end
	--- Parents a GuiObject into the window body.
	function handle:addToWindow(guiObject: GuiObject)
		guiObject.Parent = body
		return handle
	end
	--- Joins an icon into the window, like adding one to a dropdown/menu.
	function handle:addIcon(childIcon: any)
		Utility.joinFeature(childIcon, icon, windowIcons, body)
		childIcon:modifyTheme({
			{ "Widget", "MinimumWidth", openSize.X - 20 },
			{ "Widget", "MinimumHeight", 50 },
			{ "IconLabel", "TextSize", 18 },
			{ "ContentsList", "HorizontalAlignment", Enum.HorizontalAlignment.Left },
		})
		return handle
	end

	return handle
end
