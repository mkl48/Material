--- The shared visual language for Material's windows and overlays — a dark,
--- rounded palette emulating Roblox's in-experience core UI (the store /
--- quick-access window look). One table so every surface matches; swap it to
--- reskin the whole emulator at once.
--- @section Support
--- @client

export type Skin = {
	Backdrop: Color3,
	Surface: Color3,
	SurfaceTop: Color3,
	SurfaceBottom: Color3,
	SurfaceRaised: Color3,
	Header: Color3,
	Stroke: Color3,
	StrokeTransparency: number,
	Divider: Color3,
	Text: Color3,
	TextMuted: Color3,
	Accent: Color3,
	Info: Color3,
	Danger: Color3,
	CornerRadius: UDim,
	ButtonRadius: UDim,
	HeaderHeight: number,
	Font: Enum.Font,
	TitleFont: Enum.Font,
	Shadow: Color3,
}

-- Tuned to Roblox's in-experience core UI (the store / quick-access panels):
-- near-black headers, a subtly graded dark body, Roblox blue, thin controls.
local Skin: Skin = {
	Backdrop = Color3.fromRGB(0, 0, 0),          -- dim behind modal windows
	Surface = Color3.fromRGB(24, 26, 31),        -- body base (solid fallback)
	SurfaceTop = Color3.fromRGB(31, 34, 40),     -- body gradient, top
	SurfaceBottom = Color3.fromRGB(14, 15, 19),  -- body gradient, bottom
	SurfaceRaised = Color3.fromRGB(38, 41, 48),  -- inputs, dock buttons
	Header = Color3.fromRGB(13, 13, 16),         -- near-black title bar
	Stroke = Color3.fromRGB(255, 255, 255),      -- border, used at StrokeTransparency
	StrokeTransparency = 0.9,
	Divider = Color3.fromRGB(40, 43, 50),        -- header/body separator
	Text = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(162, 166, 176),
	Accent = Color3.fromRGB(51, 95, 255),        -- Roblox blue (#335FFF)
	Info = Color3.fromRGB(80, 128, 240),         -- the shop info-banner blue
	Danger = Color3.fromRGB(226, 74, 74),
	CornerRadius = UDim.new(0, 12),
	ButtonRadius = UDim.new(0, 8),
	HeaderHeight = 48,
	Font = Enum.Font.GothamMedium,
	TitleFont = Enum.Font.GothamBold,
	Shadow = Color3.fromRGB(0, 0, 0),
}

return Skin
