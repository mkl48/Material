--- A small status dot in the icon's top-right corner — online / new / alert —
--- distinct from the numbered notice badge. Set a colour with [[Icon:setPip]];
--- pass nil to hide it.
--- @section Elements
--- @client

return function(icon: any)
	local iconSpot = icon:getInstance("IconSpot")

	local pip = Instance.new("Frame")
	pip.Name = "StatusPip"
	pip.AnchorPoint = Vector2.new(1, 0)
	pip.Position = UDim2.new(1, -5, 0, 5)
	pip.Size = UDim2.fromOffset(10, 10)
	pip.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
	pip.BorderSizePixel = 0
	pip.ZIndex = 16
	pip.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = pip
	-- a dark ring so it reads on any icon colour
	local ring = Instance.new("UIStroke")
	ring.Color = Color3.fromRGB(18, 18, 21)
	ring.Thickness = 2
	ring.Parent = pip
	pip.Parent = iconSpot

	local handle = {}

	--- show the pip in the given colour (Color3 or a hex string), or hide it
	--- when `color` is nil.
	function handle.set(color: (Color3 | string)?)
		if color == nil then
			pip.Visible = false
			return
		end
		pip.BackgroundColor3 = if typeof(color) == "Color3"
			then color
			else Color3.fromHex(color :: string)
		pip.Visible = true
	end

	return handle
end
