--- A carousel container: a horizontal strip that shows a few icons and scrolls
--- through the rest, dropping from the parent icon when selected. Good for long
--- lists in a small space. Holds real icons, joined like a [[Menu]]. Created
--- through [[Icon:setCarousel]].
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Utility = require(root.Utility)

local OPEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

return function(icon: any, config: any)
	config = config or {}
	local Icon = require(icon.iconModule)
	local janitor = icon.dropdownJanitor
	local visible = config.visible or 4
	local cell = config.cell or 54
	local pad = 6
	local width = visible * cell + (visible + 1) * pad

	local container = Instance.new("Frame")
	container.Name = "Carousel"
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Position = UDim2.new(0.5, 0, 1, 10)
	container.Size = UDim2.fromOffset(width, 0)
	container.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
	container.BackgroundTransparency = 0.05
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.ZIndex = -2
	container.Visible = false
	container.Parent = icon.widget
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "CarouselScroller"
	scroller.Size = UDim2.new(1, 0, 0, cell + pad * 2)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.ScrollingDirection = Enum.ScrollingDirection.X
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroller.CanvasSize = UDim2.new()
	scroller.ScrollBarThickness = 3
	scroller.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	scroller.ScrollBarImageTransparency = 0.7
	scroller.Parent = container
	local scrollPad = Instance.new("UIPadding")
	local p = UDim.new(0, pad)
	scrollPad.PaddingTop, scrollPad.PaddingBottom, scrollPad.PaddingLeft, scrollPad.PaddingRight = p, p, p, p
	scrollPad.Parent = scroller
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, pad)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroller

	local carouselIcons = {}
	local openHeight = cell + pad * 2

	local function resize(open: boolean)
		if open then
			container.Visible = true
			TweenService:Create(container, OPEN, { Size = UDim2.fromOffset(width, openHeight) }):Play()
		else
			local tween = TweenService:Create(container, CLOSE, { Size = UDim2.fromOffset(width, 0) })
			tween:Play()
			tween.Completed:Once(function()
				if not icon.isSelected then
					container.Visible = false
				end
			end)
		end
	end
	janitor:add(icon.toggled:Connect(function()
		resize(icon.isSelected)
	end))

	local function themeChild(child: any)
		child:modifyTheme({
			{ "Widget", "MinimumWidth", cell },
			{ "Widget", "MinimumHeight", cell },
			{ "IconCorners", "CornerRadius", UDim.new(0, 10) },
		})
	end

	local handle = {}
	handle.container = container
	function handle.setIcons(arrayOfIcons: { any })
		for _, uid in carouselIcons do
			local existing = Icon.getIconByUID(uid)
			if existing then
				existing:destroy()
			end
		end
		table.clear(carouselIcons)
		for _, child in arrayOfIcons do
			Utility.joinFeature(child, icon, carouselIcons, scroller)
			themeChild(child)
		end
		resize(icon.isSelected)
		return handle
	end
	function handle.addIcon(child: any)
		Utility.joinFeature(child, icon, carouselIcons, scroller)
		themeChild(child)
		resize(icon.isSelected)
		return handle
	end
	return handle
end
