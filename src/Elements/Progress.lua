--- A thin progress/cooldown bar along the bottom of the icon. Set a fraction
--- with [[Icon:setProgress]], or run a timed sweep with [[Icon:cooldown]]
--- (fills full then drains to empty over N seconds — ability cooldowns).
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Skin = require(root.Skin)

return function(icon: any)
	local iconSpot = icon:getInstance("IconSpot")

	local track = Instance.new("Frame")
	track.Name = "ProgressTrack"
	track.AnchorPoint = Vector2.new(0.5, 1)
	track.Position = UDim2.new(0.5, 0, 1, -4)
	track.Size = UDim2.new(1, -12, 0, 4)
	track.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	track.BackgroundTransparency = 0.5
	track.BorderSizePixel = 0
	track.ZIndex = 12
	track.Visible = false
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "ProgressFill"
	fill.AnchorPoint = Vector2.new(0, 0.5)
	fill.Position = UDim2.fromScale(0, 0.5)
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Skin.Accent
	fill.BorderSizePixel = 0
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill
	fill.Parent = track
	track.Parent = iconSpot

	local progress = {}

	--- set the bar to a 0..1 fraction (tweened). 0 hides it.
	function progress.set(alpha: number)
		alpha = math.clamp(alpha, 0, 1)
		track.Visible = true
		TweenService:Create(fill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Size = UDim2.fromScale(alpha, 1),
		}):Play()
		if alpha <= 0 then
			task.delay(0.2, function()
				if fill.Size.X.Scale <= 0 then
					track.Visible = false
				end
			end)
		end
	end

	--- fill full, then drain to empty over `seconds` (a cooldown wipe).
	function progress.cooldown(seconds: number)
		track.Visible = true
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Skin.Accent
		local tween = TweenService:Create(fill, TweenInfo.new(seconds, Enum.EasingStyle.Linear), {
			Size = UDim2.fromScale(0, 1),
		})
		tween:Play()
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				track.Visible = false
			end
		end)
	end

	return progress
end
