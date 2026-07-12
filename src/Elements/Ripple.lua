--- A Material-style ripple: a circle that expands from the press point across
--- the icon when it's clicked or tapped, then fades. Contained by the icon
--- button, so it reads as part of the icon. Toggle with [[Icon:setRipple]].
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

local RIPPLE = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

return function(icon: any)
	local clickRegion = icon:getInstance("ClickRegion")
	local iconSpot = icon:getInstance("IconSpot")

	-- a clip that fills the spot exactly, so ripples are contained by the icon
	-- (and its rounded corners) rather than bleeding into the wider widget
	local clip = Instance.new("Frame")
	clip.Name = "RippleClip"
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.ZIndex = 11
	local spotCorner = iconSpot:FindFirstChildOfClass("UICorner")
	local clipCorner = Instance.new("UICorner")
	clipCorner.CornerRadius = if spotCorner then spotCorner.CornerRadius else UDim.new(1, 0)
	clipCorner.Parent = clip
	clip.Parent = iconSpot

	icon.janitor:add(clickRegion.InputBegan:Connect(function(input)
		if icon.rippleEnabled == false or icon.locked then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local absPos = clip.AbsolutePosition
		local absSize = clip.AbsoluteSize
		local circle = Instance.new("Frame")
		circle.Name = "Ripple"
		circle.AnchorPoint = Vector2.new(0.5, 0.5)
		circle.Position = UDim2.fromOffset(input.Position.X - absPos.X, input.Position.Y - absPos.Y)
		circle.Size = UDim2.fromOffset(0, 0)
		circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		circle.BackgroundTransparency = 0.72
		circle.BorderSizePixel = 0
		circle.ZIndex = 12
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = circle
		circle.Parent = clip

		local reach = math.max(absSize.X, absSize.Y) * 2.2
		local tween = TweenService:Create(circle, RIPPLE, {
			Size = UDim2.fromOffset(reach, reach),
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			circle:Destroy()
		end)
	end))

	return {}
end
