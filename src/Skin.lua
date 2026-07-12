--- The shared visual language for Material's windows and overlays — a dark,
--- rounded palette emulating Roblox's in-experience core UI (the store /
--- quick-access window look). One table so every surface matches; swap it to
--- reskin the whole emulator at once.
--- @section Support
--- @client

export type Skin = {
	Backdrop: Color3,
	Surface: Color3,
	SurfaceRaised: Color3,
	Header: Color3,
	Stroke: Color3,
	Divider: Color3,
	Text: Color3,
	TextMuted: Color3,
	Accent: Color3,
	Danger: Color3,
	CornerRadius: UDim,
	HeaderHeight: number,
	Font: Enum.Font,
	Shadow: Color3,
}

local Skin: Skin = {
	Backdrop = Color3.fromRGB(0, 0, 0),        -- dim behind modal windows
	Surface = Color3.fromRGB(28, 29, 33),      -- window body
	SurfaceRaised = Color3.fromRGB(38, 40, 46),-- inputs, dock buttons
	Header = Color3.fromRGB(23, 24, 28),       -- title bar
	Stroke = Color3.fromRGB(58, 61, 70),       -- window border
	Divider = Color3.fromRGB(48, 50, 58),      -- header/body separator
	Text = Color3.fromRGB(235, 238, 245),
	TextMuted = Color3.fromRGB(150, 156, 168),
	Accent = Color3.fromRGB(0, 162, 255),      -- Roblox blue
	Danger = Color3.fromRGB(236, 111, 98),
	CornerRadius = UDim.new(0, 10),
	HeaderHeight = 40,
	Font = Enum.Font.GothamMedium,
	Shadow = Color3.fromRGB(0, 0, 0),
}

return Skin
