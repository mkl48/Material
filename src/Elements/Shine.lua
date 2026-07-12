--- A light glint that periodically sweeps across the icon to say "new" or
--- "shiny". Contained by the icon button. Toggle with [[Icon:setShine]].
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

local SWEEP = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

return function(icon: any)
	local iconSpot = icon:getInstance("IconSpot")

	-- a clip that fills the spot exactly (and matches its rounded corners), so
	-- the sweep is contained by the icon rather than the wider widget/button
	local clip = Instance.new("Frame")
	clip.Name = "ShineClip"
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.ZIndex = 13
	local spotCorner = iconSpot:FindFirstChildOfClass("UICorner")
	local corner = Instance.new("UICorner")
	corner.CornerRadius = if spotCorner then spotCorner.CornerRadius else UDim.new(1, 0)
	corner.Parent = clip
	clip.Parent = iconSpot

	local streak = Instance.new("Frame")
	streak.Name = "Shine"
	streak.AnchorPoint = Vector2.new(0.5, 0.5)
	streak.Position = UDim2.new(-0.3, 0, 0.5, 0)
	streak.Size = UDim2.new(0, 14, 2, 0)
	streak.Rotation = 18
	streak.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	streak.BorderSizePixel = 0
	streak.ZIndex = 13
	streak.Visible = false
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = 90
	gradient.Parent = streak
	streak.Parent = clip

	local enabled = false
	local running = false
	local function loop()
		if running then
			return
		end
		running = true
		while enabled do
			streak.Position = UDim2.new(-0.3, 0, 0.5, 0)
			streak.Visible = true
			TweenService:Create(streak, SWEEP, { Position = UDim2.new(1.3, 0, 0.5, 0) }):Play()
			task.wait(0.55)
			streak.Visible = false
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
