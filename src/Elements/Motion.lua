--- Attention animations — quick one-shot juice on an icon to draw the eye
--- ([[Icon:pulse]], [[Icon:bounce]], [[Icon:wobble]]). Drives a UIScale +
--- Rotation on the icon spot, so it never fights the widget's own layout.
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

return function(icon: any)
	local iconSpot = icon:getInstance("IconSpot")
	local scale = iconSpot:FindFirstChild("MotionScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		;(scale :: UIScale).Name = "MotionScale"
		;(scale :: UIScale).Parent = iconSpot
	end
	local uiScale = scale :: UIScale

	local function to(target: number, info: TweenInfo)
		TweenService:Create(uiScale, info, { Scale = target }):Play()
	end

	local motion = {}

	--- grow slightly, then settle
	function motion.pulse()
		to(1.14, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		task.delay(0.11, function()
			to(1, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
		end)
	end

	--- dip, then overshoot back up
	function motion.bounce()
		to(0.82, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		task.delay(0.09, function()
			to(1, TweenInfo.new(0.34, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out))
		end)
	end

	--- quick rotational shake
	function motion.wobble()
		local info = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 5, true)
		TweenService:Create(iconSpot, info, { Rotation = 8 }):Play()
		task.delay(0.07 * 12, function()
			iconSpot.Rotation = 0
		end)
	end

	return motion
end
