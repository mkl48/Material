--- A light glint that periodically sweeps across the icon to say "new" or
--- "shiny". Done with a moving gradient on an icon-sized frame, so nothing
--- ever extends past the icon and it can't bleed out. Toggle with
--- [[Icon:setShine]].
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

local SWEEP = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

return function(icon: any)
	local iconSpot = icon:getInstance("IconSpot")

	-- an icon-sized white frame; the gradient below makes all of it transparent
	-- except a narrow bright band, and we slide that band across via Offset.
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.fromScale(1, 1)
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0
	shine.BorderSizePixel = 0
	shine.ZIndex = 13
	shine.Visible = false
	local spotCorner = iconSpot:FindFirstChildOfClass("UICorner")
	local corner = Instance.new("UICorner")
	corner.CornerRadius = if spotCorner then spotCorner.CornerRadius else UDim.new(1, 0)
	corner.Parent = shine

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 20
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Offset = Vector2.new(-1.3, 0)
	gradient.Parent = shine
	shine.Parent = iconSpot

	local enabled = false
	local running = false
	local function loop()
		if running then
			return
		end
		running = true
		while enabled do
			gradient.Offset = Vector2.new(-1.3, 0)
			shine.Visible = true
			TweenService:Create(gradient, SWEEP, { Offset = Vector2.new(1.3, 0) }):Play()
			task.wait(0.55)
			shine.Visible = false
			task.wait(2.6)
		end
		running = false
	end

	local handle = {}
	function handle.set(bool: boolean)
		enabled = bool
		if bool then
			task.spawn(loop)
		end
	end
	return handle
end
