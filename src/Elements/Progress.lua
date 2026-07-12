--- A circular progress/cooldown ring around the icon. Built from a UIStroke
--- (the ring) whose fill is revealed by a UIGradient, so it follows the icon's
--- shape and stays within its bounds. Set a fraction with [[Icon:setProgress]],
--- or run a timed drain with [[Icon:cooldown]] (fills, then empties over N
--- seconds — ability cooldowns).
--- @section Elements
--- @client

local TweenService = game:GetService("TweenService")

local ACCENT = Color3.fromRGB(0, 116, 189)
local THICKNESS = 3

return function(icon: any)
	local iconSpot = icon:getInstance("IconSpot")
	local spotCorner = iconSpot:FindFirstChildOfClass("UICorner")
	local radius = if spotCorner then spotCorner.CornerRadius else UDim.new(1, 0)

	-- dim track ring
	local track = Instance.new("Frame")
	track.Name = "ProgressTrack"
	track.Size = UDim2.fromScale(1, 1)
	track.BackgroundTransparency = 1
	track.ZIndex = 6
	track.Visible = false
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = radius
	trackCorner.Parent = track
	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = Color3.fromRGB(0, 0, 0)
	trackStroke.Thickness = THICKNESS
	trackStroke.Transparency = 0.55
	trackStroke.Parent = track
	track.Parent = iconSpot

	-- accent fill ring, revealed bottom-to-top by a gradient on its stroke
	local fill = Instance.new("Frame")
	fill.Name = "ProgressFill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundTransparency = 1
	fill.ZIndex = 7
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = radius
	fillCorner.Parent = fill
	local fillStroke = Instance.new("UIStroke")
	fillStroke.Color = ACCENT
	fillStroke.Thickness = THICKNESS
	fillStroke.Parent = fill
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90 -- vertical: 0 = top, 1 = bottom
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),   -- top: empty
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(0.5, 0), -- sharp edge -> bottom: filled
		NumberSequenceKeypoint.new(1, 0),
	})
	gradient.Offset = Vector2.new(0, 0.5) -- start empty
	gradient.Parent = fillStroke
	fill.Parent = iconSpot

	-- alpha 0..1 -> Offset.Y 0.5 (empty) .. -0.5 (full)
	local function offsetFor(alpha: number): Vector2
		return Vector2.new(0, 0.5 - math.clamp(alpha, 0, 1))
	end

	local progress = {}

	--- set the ring to a 0..1 fraction (tweened). 0 hides it.
	function progress.set(alpha: number)
		alpha = math.clamp(alpha, 0, 1)
		track.Visible = true
		TweenService:Create(gradient, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Offset = offsetFor(alpha),
		}):Play()
		if alpha <= 0 then
			task.delay(0.2, function()
				if gradient.Offset.Y >= 0.5 then
					track.Visible = false
				end
			end)
		end
	end

	--- fill, then drain to empty over `seconds` (a cooldown ring).
	function progress.cooldown(seconds: number)
		track.Visible = true
		gradient.Offset = offsetFor(1)
		local tween = TweenService:Create(gradient, TweenInfo.new(seconds, Enum.EasingStyle.Linear), {
			Offset = offsetFor(0),
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
