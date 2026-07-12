--- A grid container: child icons arranged in rows × columns that drops from the
--- parent icon when selected (inventories, shops, emote pickers). Holds real
--- icons, joined like a [[Dropdown]]. Created through [[Icon:setGrid]].
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local Utility = require(root.Utility)

local OPEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

return function(icon: any, config: any)
	config = config or {}
	local Icon = require(icon.iconModule)
	local janitor = icon.dropdownJanitor
	local columns = config.columns or 3
	local cell = config.cell or 54
	local pad = 6
	local width = columns * cell + (columns + 1) * pad

	local container = Instance.new("Frame")
	container.Name = "Grid"
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

	local content = Instance.new("Frame")
	content.Name = "GridContent"
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.Parent = container
	local gridPad = Instance.new("UIPadding")
	local p = UDim.new(0, pad)
	gridPad.PaddingTop, gridPad.PaddingBottom, gridPad.PaddingLeft, gridPad.PaddingRight = p, p, p, p
	gridPad.Parent = content
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(cell, cell)
	grid.CellPadding = UDim2.fromOffset(pad, pad)
	grid.FillDirectionMaxCells = columns
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = content

	local gridIcons = {}

	local function resize(open: boolean)
		if open then
			container.Visible = true
			RunService.Heartbeat:Wait()
			local height = content.AbsoluteSize.Y
			TweenService:Create(container, OPEN, { Size = UDim2.fromOffset(width, height) }):Play()
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
		for _, uid in gridIcons do
			local existing = Icon.getIconByUID(uid)
			if existing then
				existing:destroy()
			end
		end
		table.clear(gridIcons)
		for _, child in arrayOfIcons do
			Utility.joinFeature(child, icon, gridIcons, content)
			themeChild(child)
		end
		resize(icon.isSelected)
		return handle
	end
	function handle.addIcon(child: any)
		Utility.joinFeature(child, icon, gridIcons, content)
		themeChild(child)
		resize(icon.isSelected)
		return handle
	end
	return handle
end
