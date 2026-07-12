--- A radial menu: child icons fan out in an arc around the parent icon when it
--- is selected, and pull back in when deselected. Holds real icons (joined the
--- same way as a [[Dropdown]] or [[Menu]]), so they keep the theme and ratios.
--- Created through [[Icon:setRadial]].
---
--- ```lua a radial of actions
--- Material.new()
---     :setImage(rbxassetid)
---     :setRadial({
---         Material.new():setLabel("A"),
---         Material.new():setLabel("B"),
---         Material.new():setLabel("C"),
---     })
--- ```
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Utility = require(root.Utility)

local OUT_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local IN_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local CENTER = UDim2.fromScale(0.5, 0.5)

return function(icon: any, config: any)
	config = config or {}
	local Icon = require(icon.iconModule)
	local janitor = icon.dropdownJanitor
	local radius = config.radius or 62
	local arc = math.rad(config.arc or 150)       -- total spread
	local facing = math.rad(config.facing or -90) -- centre direction (-90 = up)

	local container = Instance.new("Frame")
	container.Name = "Radial"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = CENTER
	container.Size = UDim2.fromOffset(radius * 3, radius * 3)
	container.BackgroundTransparency = 1
	container.ClipsDescendants = false
	container.Active = false          -- never sink input meant for what's behind
	container.ZIndex = 40             -- fan sits on top, not cut off by neighbours
	container.Visible = false
	container.Parent = icon.widget

	local radialIcons = {}

	local function angleFor(index: number, total: number): number
		if total <= 1 then
			return facing
		end
		return facing + ((index - 1) / (total - 1) - 0.5) * arc
	end

	local function targetFor(index: number, total: number): UDim2
		local a = angleFor(index, total)
		return UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(math.cos(a) * radius, math.sin(a) * radius)
	end

	-- ensure each child widget is centred-anchored and has a UIScale to pop
	local function prepare(child: any)
		local widget = child.widget
		widget.AnchorPoint = Vector2.new(0.5, 0.5)
		local uiScale = widget:FindFirstChild("RadialScale") :: UIScale?
		if not uiScale then
			uiScale = Instance.new("UIScale")
			;(uiScale :: UIScale).Name = "RadialScale"
			;(uiScale :: UIScale).Parent = widget
		end
		return widget, uiScale :: UIScale
	end

	local function apply(open: boolean)
		local total = #radialIcons
		if open then
			container.Visible = true
		end
		for index, childUID in radialIcons do
			local child = Icon.getIconByUID(childUID)
			if not child then
				continue
			end
			local widget, uiScale = prepare(child)
			if open then
				widget.Position = CENTER
				uiScale.Scale = 0
				task.delay((index - 1) * 0.03, function()
					if not icon.isSelected then
						return
					end
					TweenService:Create(widget, OUT_TWEEN, { Position = targetFor(index, total) }):Play()
					TweenService:Create(uiScale, OUT_TWEEN, { Scale = 1 }):Play()
				end)
			else
				TweenService:Create(widget, IN_TWEEN, { Position = CENTER }):Play()
				TweenService:Create(uiScale, IN_TWEEN, { Scale = 0 }):Play()
			end
		end
		if not open then
			task.delay(IN_TWEEN.Time, function()
				if not icon.isSelected then
					container.Visible = false
				end
			end)
		end
	end

	janitor:add(icon.toggled:Connect(function()
		apply(icon.isSelected)
	end))

	local handle = {}
	handle.container = container

	--- Replaces the radial's icons with the given array.
	function handle.setIcons(arrayOfIcons: { any })
		for _, uid in radialIcons do
			local existing = Icon.getIconByUID(uid)
			if existing then
				existing:destroy()
			end
		end
		table.clear(radialIcons)
		for _, child in arrayOfIcons do
			Utility.joinFeature(child, icon, radialIcons, container)
			prepare(child)
		end
		apply(icon.isSelected)
		return handle
	end

	--- Adds one icon to the radial.
	function handle.addIcon(child: any)
		Utility.joinFeature(child, icon, radialIcons, container)
		prepare(child)
		apply(icon.isSelected)
		return handle
	end

	return handle
end
