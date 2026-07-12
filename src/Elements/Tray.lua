--- A tray container: a small shelf of icons that slides out from the parent
--- icon (and fades in) when selected, sliding back on deselect. Holds real
--- icons in a row, joined like a [[Menu]]. Created through [[Icon:setTray]].
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Utility = require(root.Utility)

local OPEN = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local OUT_POS = UDim2.new(0.5, 0, 1, 12)
local IN_POS = UDim2.new(0.5, 0, 1, -6)

return function(icon: any, config: any)
	config = config or {}
	local Icon = require(icon.iconModule)
	local janitor = icon.dropdownJanitor
	local cell = config.cell or 50
	local pad = 6

	local tray = Instance.new("CanvasGroup")
	tray.Name = "Tray"
	tray.AnchorPoint = Vector2.new(0.5, 0)
	tray.Position = IN_POS
	tray.Size = UDim2.fromOffset(0, cell + pad * 2)
	tray.AutomaticSize = Enum.AutomaticSize.X
	tray.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
	tray.BackgroundTransparency = 0.05
	tray.BorderSizePixel = 0
	tray.GroupTransparency = 1
	tray.ZIndex = 30
	tray.Visible = false
	tray.Parent = icon.widget
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = tray
	local trayPad = Instance.new("UIPadding")
	local p = UDim.new(0, pad)
	trayPad.PaddingTop, trayPad.PaddingBottom, trayPad.PaddingLeft, trayPad.PaddingRight = p, p, p, p
	trayPad.Parent = tray
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, pad)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = tray

	local trayIcons = {}

	local function slide(open: boolean)
		if open then
			tray.Visible = true
			TweenService:Create(tray, OPEN, { Position = OUT_POS, GroupTransparency = 0 }):Play()
		else
			local tween = TweenService:Create(tray, CLOSE, { Position = IN_POS, GroupTransparency = 1 })
			tween:Play()
			tween.Completed:Once(function()
				if not icon.isSelected then
					tray.Visible = false
				end
			end)
		end
	end
	janitor:add(icon.toggled:Connect(function()
		slide(icon.isSelected)
	end))

	local function themeChild(child: any)
		child:modifyTheme({
			{ "Widget", "MinimumWidth", cell },
			{ "Widget", "MinimumHeight", cell },
			{ "IconCorners", "CornerRadius", UDim.new(0, 10) },
		})
	end

	local handle = {}
	handle.container = tray
	function handle.setIcons(arrayOfIcons: { any })
		for _, uid in trayIcons do
			local existing = Icon.getIconByUID(uid)
			if existing then
				existing:destroy()
			end
		end
		table.clear(trayIcons)
		for _, child in arrayOfIcons do
			Utility.joinFeature(child, icon, trayIcons, tray)
			themeChild(child)
		end
		slide(icon.isSelected)
		return handle
	end
	function handle.addIcon(child: any)
		Utility.joinFeature(child, icon, trayIcons, tray)
		themeChild(child)
		slide(icon.isSelected)
		return handle
	end
	return handle
end
