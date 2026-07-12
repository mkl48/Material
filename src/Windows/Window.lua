--- A Roblox-style panel an icon opens — the in-experience store / quick-access
--- look. Not a draggable OS window: it belongs to an [[Icon]], opens when that
--- icon is selected and closes when it's deselected, and is built from the same
--- TopbarPlus theme (panel colour, BuilderSans, shared shadow) so it matches the
--- topbar. Its close button is a real [[Icon]].
---
--- Created through [[Icon:setWindow]] rather than directly:
---
--- ```lua a shop panel opened from the topbar
--- local shop = Material.new()
---     :setImage(14723463500)
---     :setCaption("Shop")
---     :setWindow({ title = "Shop", width = 560, height = 400 })
---
--- shop:adopt(playerGui.ShopGui.Root)   -- reparent your existing UI in
--- ```
--- @section Windows
--- @client

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local root = script.Parent.Parent
local Types = require(root.Types)
local Janitor = require(root.Packages.Janitor)
local UI = require(root.UI)
local Skin = require(root.Skin)

export type Window = Types.Window

local OPEN_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Window = {}
Window.__index = Window

local layer: ScreenGui? = nil
local backdrop: Frame? = nil

local function getLayer(): (ScreenGui, Frame)
	if layer then
		return layer, backdrop :: Frame
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = UI.new("ScreenGui", {
		Name = "MaterialWindows",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 50,
		Parent = playerGui,
	}) :: ScreenGui
	backdrop = UI.new("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Skin.Backdrop,
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 0,
		Parent = screenGui,
	}) :: Frame
	layer = screenGui
	return screenGui, backdrop :: Frame
end

local function viewport(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(1280, 720)
end

--- Creates a panel. With an `ownerIcon` it opens/closes with that icon (the
--- [[Icon:setWindow]] path); without one it's a free-standing modal you open and
--- close yourself (used by [[Dialog]]).
function Window.new(ownerIcon: any?)
	local self = setmetatable({}, Window)
	self.janitor = Janitor.new()
	self.ownerIcon = ownerIcon
	self.title = ""
	self.isOpen = false
	self.isModal = false
	self.dismissable = true
	self.headerVisible = true
	self._size = Vector2.new(480, 320)
	self._dock = "center"
	self._adopted = {}

	self.opened = self.janitor:add(require(root.Packages.GoodSignal).new())
	self.closed = self.janitor:add(require(root.Packages.GoodSignal).new())

	self:_build()

	-- when owned by an icon, open/close follow its selection
	if ownerIcon then
		self.janitor:add(ownerIcon.selected:Connect(function()
			self:open()
		end))
		self.janitor:add(ownerIcon.deselected:Connect(function()
			self:close()
		end))
	end
	self.janitor:add(function()
		self:release()
		if self.root then
			self.root:Destroy()
		end
	end)
	return self
end

function Window:_build()
	local screenGui = getLayer()

	-- transparent geometry frame holding the shadow + the clipped panel
	local rootFrame = UI.new("Frame", {
		Name = "Window",
		Size = UDim2.fromOffset(self._size.X, self._size.Y),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screenGui,
	})
	self.root = rootFrame

	UI.new("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 40, 1, 40),
		BackgroundTransparency = 1,
		Image = Skin.ShadowImage,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(12, 12, 13, 13),
		ZIndex = 0,
		Parent = rootFrame,
	})

	local panel = UI.new("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Skin.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = rootFrame,
	}, {
		UI.corner(Skin.CornerRadius),
		UI.stroke(Skin.Stroke, 1, Skin.StrokeTransparency),
	})
	self.panel = panel

	-- header
	local header = UI.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, Skin.HeaderHeight),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = panel,
	})
	self.header = header

	self.titleLabel = UI.new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 52, 0.5, 0),
		Size = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		FontFace = Skin.TitleFontFace,
		Text = self.title,
		TextColor3 = Skin.Text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = header,
	})

	self.titleIcon = UI.new("ImageLabel", {
		Name = "TitleIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 52, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = header,
	})

	-- a holder the close Icon's widget is parented into (left, Roblox style)
	self.closeHolder = UI.new("Frame", {
		Name = "CloseHolder",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = header,
	})
	self:_buildCloseIcon()

	-- divider under the header
	self.divider = UI.new("Frame", {
		Name = "Divider",
		Position = UDim2.new(0, 0, 0, Skin.HeaderHeight),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Skin.Divider,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = panel,
	})

	-- body (transparent; adopted content renders here)
	self.body = UI.new("Frame", {
		Name = "Body",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 1, -Skin.HeaderHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = panel,
	})

	self:_place()
end

-- the close button is a real Icon (matches the theme, ratios, hover)
function Window:_buildCloseIcon()
	local Icon = require(root) :: any  -- lazy: the Material module (init.lua)
	local closeIcon = Icon.new()
	closeIcon:setLabel("\u{2715}")
	closeIcon:modifyTheme({
		{ "IconLabel", "Text", "\u{2715}", "Deselected" },
		{ "IconLabel", "Text", "\u{2715}", "Selected" },
		{ "IconLabel", "FontFace", Skin.TitleFontFace },
		{ "IconLabel", "TextSize", 18 },
		{ "IconImage", "Image", "" },
		{ "Widget", "MinimumWidth", 38 },
		{ "Widget", "MinimumHeight", 38 },
		{ "IconButton", "BackgroundTransparency", 1, "Deselected" },
	})
	closeIcon:oneClick(true)
	closeIcon:autoDeselect(false)  -- don't deselect the user's other topbar icons
	closeIcon.widget.Parent = self.closeHolder
	closeIcon.widget.Position = UDim2.fromScale(0, 0)
	self.closeIcon = closeIcon
	self.janitor:add(function()
		closeIcon:destroy()
	end)
	self.janitor:add(closeIcon.selected:Connect(function()
		if self.ownerIcon then
			self.ownerIcon:deselect("WindowClose", self.ownerIcon)
		else
			self:close()
		end
	end))
end

-- position the panel per its dock + size
function Window:_place()
	local vp = viewport()
	if self._dock == "top" then
		self.root.AnchorPoint = Vector2.new(0.5, 0)
		self.root.Position = UDim2.new(0.5, 0, 0, 8)
		self.root.Size = UDim2.new(1, -16, 0, self._size.Y)
	else -- center
		self.root.AnchorPoint = Vector2.new(0.5, 0.5)
		self.root.Position = UDim2.fromScale(0.5, 0.5)
		self.root.Size = UDim2.fromOffset(math.min(self._size.X, vp.X - 24), math.min(self._size.Y, vp.Y - 24))
	end
end

--- Sets the panel title.
function Window:setTitle(text: string)
	self.title = text
	self.titleLabel.Text = text
	return self
end

--- Sets a small icon shown left of the title (asset id or asset string).
function Window:setIcon(imageId: (number | string)?)
	if imageId == nil then
		self.titleIcon.Visible = false
		self.titleLabel.Position = UDim2.new(0, 52, 0.5, 0)
	else
		self.titleIcon.Image = if tonumber(imageId) then `rbxassetid://{imageId}` else imageId
		self.titleIcon.Visible = true
		self.titleLabel.Position = UDim2.new(0, 82, 0.5, 0)
	end
	return self
end

--- Sets the panel's pixel size (used by the `center` dock).
function Window:setSize(width: number, height: number)
	self._size = Vector2.new(width, height)
	self:_place()
	return self
end

--- Docks the panel `"center"` (default) or `"top"` (full-width, like the Shop).
function Window:setDock(where: "center" | "top")
	self._dock = where
	self:_place()
	return self
end

--- Shows or hides the title bar (hidden = the headerless respawn-modal look).
function Window:setHeaderVisible(bool: boolean)
	self.headerVisible = bool
	self.header.Visible = bool
	self.divider.Visible = bool
	self.body.Size = UDim2.new(1, 0, 1, if bool then -Skin.HeaderHeight else 0)
	return self
end

--- Makes the panel modal: a dimmed backdrop covers everything behind it while
--- open; with `dismissable` (default true) clicking the backdrop closes it.
function Window:setModal(bool: boolean, dismissable: boolean?)
	self.isModal = bool
	if dismissable ~= nil then
		self.dismissable = dismissable
	end
	return self
end

--- Reparents an existing GuiObject into the body, remembering where it came
--- from; restored on [[Window:release]] / close / destroy.
function Window:adopt(guiObject: GuiObject)
	if self._adopted[guiObject] then
		return self
	end
	self._adopted[guiObject] = {
		parent = guiObject.Parent,
		size = guiObject.Size,
		position = guiObject.Position,
		anchor = guiObject.AnchorPoint,
	}
	guiObject.Size = UDim2.fromScale(1, 1)
	guiObject.Position = UDim2.fromScale(0, 0)
	guiObject.AnchorPoint = Vector2.zero
	guiObject.Parent = self.body
	return self
end

--- Restores every adopted GuiObject to where it came from.
function Window:release()
	for guiObject, saved in self._adopted do
		if guiObject and guiObject.Parent == self.body then
			guiObject.Size = saved.size
			guiObject.Position = saved.position
			guiObject.AnchorPoint = saved.anchor
			guiObject.Parent = saved.parent
		end
	end
	table.clear(self._adopted)
	return self
end

--- Returns the body frame — parent your own content here when not adopting.
function Window:getBody(): Frame
	return self.body
end

function Window:_setBackdrop(visible: boolean)
	local _, back = getLayer()
	if visible then
		back.ZIndex = 0
		back.Visible = true
		TweenService:Create(back, OPEN_TWEEN, { BackgroundTransparency = 0.5 }):Play()
		self._backdropConn = self.janitor:add(back.InputBegan:Connect(function(input)
			if self.dismissable and (input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch) then
				if self.ownerIcon then
					self.ownerIcon:deselect("WindowBackdrop", self.ownerIcon)
				else
					self:close()
				end
			end
		end))
	else
		local tween = TweenService:Create(back, OPEN_TWEEN, { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Once(function()
			if back.BackgroundTransparency >= 1 then
				back.Visible = false
			end
		end)
	end
end

--- Opens the panel (usually driven by the icon being selected).
function Window:open()
	if self.isOpen then
		return self
	end
	self.isOpen = true
	self.root.Visible = true
	if self.isModal then
		self:_setBackdrop(true)
	end
	-- scale-fade in
	local w, h = self.root.Size.X, self.root.Size.Y
	self.root.Size = UDim2.new(w.Scale * 0.96, w.Offset * 0.96, h.Scale * 0.96, h.Offset * 0.96)
	local target = if self._dock == "top"
		then UDim2.new(1, -16, 0, self._size.Y)
		else UDim2.fromOffset(math.min(self._size.X, viewport().X - 24), math.min(self._size.Y, viewport().Y - 24))
	TweenService:Create(self.root, OPEN_TWEEN, { Size = target }):Play()
	self.opened:Fire()
	return self
end

--- Closes the panel (usually driven by the icon being deselected).
function Window:close()
	if not self.isOpen then
		return self
	end
	self.isOpen = false
	self:_setBackdrop(false)
	self.root.Visible = false
	self.closed:Fire()
	return self
end

--- Destroys the panel and its close icon; adopted content is released first.
function Window:destroy()
	if self.isDestroyed then
		return
	end
	self.isDestroyed = true
	self.janitor:clean()
end
Window.Destroy = Window.destroy

return (Window :: any) :: Types.StaticWindow
