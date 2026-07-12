--- The shared visual constants for Material's windows and overlays, taken
--- straight from TopbarPlus's own theme so they match the icons: the panel
--- colour is the icon/dropdown colour (`18,18,21`), the font is **BuilderSans**
--- (Roblox's core-UI font), and the drop shadow is the shared TB+ asset. Panels
--- built from these read as part of the same topbar, not a separate UI.
--- @section Support
--- @client

export type Skin = {
	Backdrop: Color3,
	Panel: Color3,
	Divider: Color3,
	Text: Color3,
	TextMuted: Color3,
	Accent: Color3,
	Danger: Color3,
	Stroke: Color3,
	StrokeTransparency: number,
	CornerRadius: UDim,
	ButtonRadius: UDim,
	HeaderHeight: number,
	FontFace: Font,
	TitleFontFace: Font,
	ShadowImage: string,
}

local BUILDER = "rbxasset://fonts/families/BuilderSans.json"

local Skin: Skin = {
	Backdrop = Color3.fromRGB(0, 0, 0),            -- dim behind modal panels
	Panel = Color3.fromRGB(18, 18, 21),            -- == IconButton/Dropdown colour
	Divider = Color3.fromRGB(255, 255, 255),       -- used at high transparency
	Text = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(189, 190, 190),     -- TB+ caption secondary text
	Accent = Color3.fromRGB(0, 116, 189),          -- Roblox action blue
	Danger = Color3.fromRGB(226, 74, 74),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.9,
	CornerRadius = UDim.new(0, 12),
	ButtonRadius = UDim.new(0, 8),
	HeaderHeight = 48,
	FontFace = Font.new(BUILDER, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	TitleFontFace = Font.new(BUILDER, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	ShadowImage = "rbxassetid://124920646932671",  -- shared TB+ caption/dropdown shadow
}

return Skin
