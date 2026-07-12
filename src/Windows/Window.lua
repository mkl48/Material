--- A draggable, resizable window emulating Roblox's in-experience core UI (the
--- store / quick-access panel). Create one, give it a title and size, and drop
--- content in — either build inside [[Window:getBody]] or [[Window:adopt]] an
--- existing GuiObject straight off your own ScreenGui.
---
--- Windows manage themselves through the [[WindowController]]: opening
--- registers and focuses, clicking raises to the front, and closing restores
--- any adopted content to where it came from. Bind one to a topbar icon with
--- [[Icon:bindWindow]] for the full shop-button experience.
---
--- ```lua a shop window opened from the topbar
--- local shop = Material.Window.new()
---     :setTitle("Shop")
---     :setIcon(14723463500)
---     :setSize(560, 400)
---     :adopt(playerGui.ShopGui.Root)   -- reparent your existing UI in
---
--- Material.new()
---     :setImage(14723463500)
---     :setCaption("Shop")
---     :bindWindow(shop)                -- topbar icon toggles it
--- ```
--- @section Windows
--- @client

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local root = script.Parent.Parent
local Types = require(root.Types)
local Signal = require(root.Packages.GoodSignal)
local Janitor = require(root.Packages.Janitor)
local Utility = require(root.Utility)
local UI = require(root.UI)
local Skin = require(root.Skin)
local WindowController = require(script.Parent.WindowController)

export type Window = Types.Window

local MIN_WIDTH = 220
local MIN_HEIGHT = 140
local OPEN_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Window = {}
Window.__index = Window

local function viewport(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(1280, 720)
end

-- the eight resize grips: name -> {dirX, dirY} where -1/0/1 pick which edge
local HANDLES = {
	N = { 0, -1 }, S = { 0, 1 }, E = { 1, 0 }, W = { -1, 0 },
	NE = { 1, -1 }, NW = { -1, -1 }, SE = { 1, 1 }, SW = { -1, 1 },
}

--- Creates a window (hidden until [[Window:open]]): centered, default size
--- 480×320, draggable, resizable, with a title bar carrying minimize,
--- maximize, and close controls.
function Window.new()
	local self = setmetatable({}, Window)
	local janitor = Janitor.new()
	self.janitor = janitor
	self.UID = Utility.generateUID()
	self.title = "Window"
	self.isOpen = false
	self.isMinimized = false
	self.isMaximized = false
	self.isModal = false
	self.dismissable = true
	self.draggable = true
	self.resizable = true
	self._z = 0
	self._adopted = {}          -- [instance] = { parent, position, size }
	self._restoreRect = nil     -- pre-maximize {position, size}

	-- signals
	self.opened = janitor:add(Signal.new())
	self.closed = janitor:add(Signal.new())
	self.minimized = janitor:add(Signal.new())
	self.maximized = janitor:add(Signal.new())
	self.restored = janitor:add(Signal.new())
	self.focused = janitor:add(Signal.new())
	self.moved = janitor:add(Signal.new())
	self.resized = janitor:add(Signal.new())

	self:_build()
	janitor:add(function()
		self:release()
		WindowController.unregister(self)
	end)
	return self
end

function Window:_build()
	local size = Vector2.new(480, 320)
	local vp = viewport()
	local pos = (vp - size) / 2

	-- root is a transparent geometry frame (moves/resizes). The shadow sits
	-- behind an inner Panel that does the clipping, so the shadow isn't clipped.
	local rootFrame = UI.new("Frame", {
		Name = "Window",
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromOffset(pos.X, pos.Y),
		BackgroundTransparency = 1,
		Visible = false,
	})
	self.root = rootFrame

	-- soft drop shadow behind the window
	UI.new("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 48, 1, 48),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Skin.Shadow,
		ImageTransparency = 0.4,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = 0,
		Parent = rootFrame,
	})

	-- the visible, clipped panel
	local panel = UI.new("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Skin.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = rootFrame,
	}, {
		UI.corner(Skin.CornerRadius),
		UI.stroke(Skin.Stroke, 1, 0.2),
	})
	self.panel = panel

	-- header / title bar
	local header = UI.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, Skin.HeaderHeight),
		BackgroundColor3 = Skin.Header,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, { UI.corner(Skin.CornerRadius) })
	-- square off the header's bottom corners against the body
	UI.new("Frame", {
		Name = "HeaderFill",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, Skin.CornerRadius.Offset),
		BackgroundColor3 = Skin.Header,
		BorderSizePixel = 0,
		Parent = header,
	})
	header.Parent = panel
	self.header = header

	local titleIcon = UI.new("ImageLabel", {
		Name = "TitleIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = header,
	})
	self.titleIcon = titleIcon

	local titleLabel = UI.new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.new(1, -160, 1, 0),
		BackgroundTransparency = 1,
		Font = Skin.Font,
		Text = self.title,
		TextColor3 = Skin.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = header,
	})
	self.titleLabel = titleLabel

	-- window controls (minimize / maximize / close)
	local controls = UI.new("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(112, 28),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, { UI.list(Enum.FillDirection.Horizontal, 6) })
	controls.Parent = header

	local function controlButton(name, glyph, color, order, callback)
		local button = UI.new("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Skin.SurfaceRaised,
			AutoButtonColor = true,
			Text = glyph,
			Font = Enum.Font.GothamBold,
			TextColor3 = color,
			TextSize = 15,
			LayoutOrder = order,
			ZIndex = 3,
			Parent = controls,
		}, { UI.corner(UDim.new(0, 6)) })
		self.janitor:add(button.Activated:Connect(callback))
		return button
	end

	controlButton("Minimize", "\u{2013}", Skin.TextMuted, 1, function()
		self:minimize()
	end)
	self.maximizeButton = controlButton("Maximize", "\u{25A1}", Skin.TextMuted, 2, function()
		if self.isMaximized then self:restore() else self:maximize() end
	end)
	controlButton("Close", "\u{2715}", Skin.Danger, 3, function()
		self:close()
	end)

	-- body (where content / adopted UI lives)
	local body = UI.new("Frame", {
		Name = "Body",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 1, -Skin.HeaderHeight),
		BackgroundColor3 = Skin.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	}, { UI.padding(0) })
	body.Parent = panel
	self.body = body

	self:_wireDrag()
	self:_wireResize()

	-- click anywhere to focus
	self.janitor:add(panel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self:focus()
		end
	end))
end

local function isPointerDown(input): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isPointerMove(input): boolean
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

function Window:_wireDrag()
	local dragging, dragStart, startPos = false, Vector3.zero, Vector2.zero
	self.janitor:add(self.header.InputBegan:Connect(function(input)
		if not self.draggable or self.isMaximized or not isPointerDown(input) then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = Vector2.new(self.root.Position.X.Offset, self.root.Position.Y.Offset)
	end))
	self.janitor:add(UserInputService.InputChanged:Connect(function(input)
		if not dragging or not isPointerMove(input) then
			return
		end
		local delta = input.Position - dragStart
		self:_place(startPos + Vector2.new(delta.X, delta.Y), nil)
	end))
	self.janitor:add(UserInputService.InputEnded:Connect(function(input)
		if isPointerDown(input) then
			dragging = false
		end
	end))

	-- double-click header to toggle maximize
	self.janitor:add(self.header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local now = os.clock()
		if self._lastHeaderClick and now - self._lastHeaderClick < 0.3 then
			if self.isMaximized then self:restore() else self:maximize() end
		end
		self._lastHeaderClick = now
	end))
end

function Window:_wireResize()
	for name, dir in HANDLES do
		local dirX, dirY = dir[1], dir[2]
		local thickness = 8
		local grip = UI.new("Frame", {
			Name = "Resize" .. name,
			BackgroundTransparency = 1,
			ZIndex = 5,
			AnchorPoint = Vector2.new((dirX + 1) / 2, (dirY + 1) / 2),
			Position = UDim2.fromScale((dirX + 1) / 2, (dirY + 1) / 2),
			Size = UDim2.new(
				if dirX == 0 then 1 else 0, if dirX == 0 then -thickness * 2 else thickness,
				if dirY == 0 then 1 else 0, if dirY == 0 then -thickness * 2 else thickness
			),
			Parent = self.root,
		})
		local resizing, startPointer, startPos, startSize = false, Vector3.zero, Vector2.zero, Vector2.zero
		self.janitor:add(grip.InputBegan:Connect(function(input)
			if not self.resizable or self.isMaximized or not isPointerDown(input) then
				return
			end
			resizing = true
			startPointer = input.Position
			startPos = Vector2.new(self.root.Position.X.Offset, self.root.Position.Y.Offset)
			startSize = Vector2.new(self.root.Size.X.Offset, self.root.Size.Y.Offset)
			self:focus()
		end))
		self.janitor:add(UserInputService.InputChanged:Connect(function(input)
			if not resizing or not isPointerMove(input) then
				return
			end
			local delta = input.Position - startPointer
			local newW = math.max(MIN_WIDTH, startSize.X + dirX * delta.X)
			local newH = math.max(MIN_HEIGHT, startSize.Y + dirY * delta.Y)
			local newX = if dirX == -1 then startPos.X + (startSize.X - newW) else startPos.X
			local newY = if dirY == -1 then startPos.Y + (startSize.Y - newH) else startPos.Y
			self:_place(Vector2.new(newX, newY), Vector2.new(newW, newH))
			self.resized:Fire(newW, newH)
		end))
		self.janitor:add(UserInputService.InputEnded:Connect(function(input)
			if isPointerDown(input) then
				resizing = false
			end
		end))
	end
end

-- clamp + apply position (and optionally size) within the viewport
function Window:_place(position: Vector2, size: Vector2?)
	local vp = viewport()
	local currentSize = size or Vector2.new(self.root.Size.X.Offset, self.root.Size.Y.Offset)
	local x = math.clamp(position.X, 0, math.max(0, vp.X - currentSize.X))
	local y = math.clamp(position.Y, 0, math.max(0, vp.Y - currentSize.Y))
	self.root.Position = UDim2.fromOffset(x, y)
	if size then
		self.root.Size = UDim2.fromOffset(size.X, size.Y)
	end
	self.moved:Fire(x, y)
end

--- Sets the window's title text.
function Window:setTitle(text: string)
	self.title = text
	self.titleLabel.Text = text
	return self
end

--- Sets the small icon shown left of the title (an asset id or asset string).
function Window:setIcon(imageId: (number | string)?)
	if imageId == nil then
		self.titleIcon.Visible = false
	else
		self.titleIcon.Image = if tonumber(imageId) then `rbxassetid://{imageId}` else imageId
		self.titleIcon.Visible = true
		self.titleLabel.Position = UDim2.new(0, 40, 0.5, 0)
	end
	return self
end

--- Sets the window's pixel size (clamped to the 220×140 minimum).
function Window:setSize(width: number, height: number)
	self:_place(
		Vector2.new(self.root.Position.X.Offset, self.root.Position.Y.Offset),
		Vector2.new(math.max(MIN_WIDTH, width), math.max(MIN_HEIGHT, height))
	)
	return self
end

--- Sets the window's top-left pixel position.
function Window:setPosition(x: number, y: number)
	self:_place(Vector2.new(x, y), nil)
	return self
end

--- Centers the window in the viewport.
function Window:center()
	local vp = viewport()
	local s = Vector2.new(self.root.Size.X.Offset, self.root.Size.Y.Offset)
	self:_place((vp - s) / 2, nil)
	return self
end

--- Enables or disables title-bar dragging (default true).
function Window:setDraggable(bool: boolean)
	self.draggable = bool
	return self
end

--- Enables or disables edge/corner resizing (default true).
function Window:setResizable(bool: boolean)
	self.resizable = bool
	return self
end

--- Makes the window modal: a dimmed backdrop covers everything behind it while
--- it is open. With `dismissable` (default true) clicking the backdrop closes it.
function Window:setModal(bool: boolean, dismissable: boolean?)
	self.isModal = bool
	if dismissable ~= nil then
		self.dismissable = dismissable
	end
	return self
end

--- Reparents an existing GuiObject into the window body, remembering where it
--- came from. Its original parent, size, and position are restored on
--- [[Window:release]], [[Window:close]], or destroy — Material only borrows it.
--- @param guiObject any GuiObject (a Frame off your own ScreenGui, etc.)
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

--- Restores every adopted GuiObject to its original parent and geometry.
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

--- Opens the window: parents it into the shared layer, registers with the
--- [[WindowController]], focuses it, shows the modal backdrop if set, and plays
--- the scale-fade open transition.
function Window:open()
	if self.isOpen then
		self:focus()
		return self
	end
	self.isOpen = true
	self.isMinimized = false
	self.root.Parent = WindowController.getLayer()
	self.root.Visible = true
	WindowController.register(self)
	if self.isModal then
		self:_setBackdrop(true)
	end

	-- scale-fade in (driven off the Size offsets, valid before first render)
	local finalPos = self.root.Position
	local w, h = self.root.Size.X.Offset, self.root.Size.Y.Offset
	local sw, sh = w * 0.94, h * 0.94
	self.root.Position = UDim2.fromOffset(finalPos.X.Offset + (w - sw) / 2, finalPos.Y.Offset + (h - sh) / 2)
	self.root.Size = UDim2.fromOffset(sw, sh)
	TweenService:Create(self.root, OPEN_TWEEN, {
		Size = UDim2.fromOffset(w, h),
		Position = finalPos,
	}):Play()

	self.opened:Fire()
	return self
end

--- Closes the window: restores adopted content, hides the backdrop,
--- unregisters, and plays the close transition. The window can be reopened.
function Window:close()
	if not self.isOpen then
		return self
	end
	self.isOpen = false
	self.isMinimized = false
	self.isMaximized = false
	self:_setBackdrop(false)
	local tween = TweenService:Create(self.root, OPEN_TWEEN, {
		Size = UDim2.fromOffset(self.root.Size.X.Offset * 0.94, self.root.Size.Y.Offset * 0.94),
	})
	tween:Play()
	tween.Completed:Once(function()
		self.root.Visible = false
	end)
	self:release()
	WindowController.unregister(self)
	self.closed:Fire()
	return self
end

--- Opens the window if closed, closes it if open.
function Window:toggle()
	if self.isOpen and not self.isMinimized then
		self:close()
	else
		self:open()
	end
	return self
end

--- Hides the window into the [[Dock]] without closing it (adopted content
--- stays put). Restore with [[Window:restore]] or the dock button.
function Window:minimize()
	if not self.isOpen or self.isMinimized then
		return self
	end
	self.isMinimized = true
	self.root.Visible = false
	self:_setBackdrop(false)
	WindowController.notifyMinimized(self)
	self.minimized:Fire()
	return self
end

--- Expands the window to fill the viewport (remembering the previous rect).
function Window:maximize()
	if self.isMaximized then
		return self
	end
	self._restoreRect = {
		position = self.root.Position,
		size = self.root.Size,
	}
	self.isMaximized = true
	local vp = viewport()
	TweenService:Create(self.root, OPEN_TWEEN, {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(vp.X - 16, vp.Y - 16),
	}):Play()
	self.maximizeButton.Text = "\u{2750}"
	self.maximized:Fire()
	return self
end

--- Un-minimizes or un-maximizes back to the window's previous size/position.
function Window:restore()
	if self.isMinimized then
		self.isMinimized = false
		self.root.Visible = true
		WindowController.focus(self)
		WindowController.notifyRestored(self)
		self.restored:Fire()
		return self
	end
	if self.isMaximized and self._restoreRect then
		self.isMaximized = false
		TweenService:Create(self.root, OPEN_TWEEN, {
			Position = self._restoreRect.position,
			Size = self._restoreRect.size,
		}):Play()
		self.maximizeButton.Text = "\u{25A1}"
		self.restored:Fire()
	end
	return self
end

--- Brings the window to the front and marks it the active window.
function Window:focus()
	if not self.isOpen then
		return self
	end
	WindowController.focus(self)
	self.focused:Fire()
	return self
end

function Window:_setBackdrop(visible: boolean)
	local backdrop = WindowController.getBackdrop()
	if visible then
		backdrop.ZIndex = math.max(1, self._z - 1)
		backdrop.Visible = true
		TweenService:Create(backdrop, OPEN_TWEEN, { BackgroundTransparency = 0.45 }):Play()
		self._backdropConn = self.janitor:add(backdrop.InputBegan:Connect(function(input)
			if self.dismissable and isPointerDown(input) then
				self:close()
			end
		end))
	else
		local tween = TweenService:Create(backdrop, OPEN_TWEEN, { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Once(function()
			-- only hide if no other modal re-showed it
			if backdrop.BackgroundTransparency >= 1 then
				backdrop.Visible = false
			end
		end)
	end
end

--- Destroys the window and everything it owns (adopted content is released
--- first). Alias: `Destroy`.
function Window:destroy()
	if self.isDestroyed then
		return
	end
	self.isDestroyed = true
	self.janitor:clean()
	if self.root then
		self.root:Destroy()
	end
end
Window.Destroy = Window.destroy

return (Window :: any) :: Types.StaticWindow
