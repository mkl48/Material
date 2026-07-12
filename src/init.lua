--!nonstrict
--- The Icon class — Material's entire public surface, drop-in identical to
--- TopbarPlus. Construct with [[Icon.new]], then chain: every method returns
--- the icon. Most `set*` methods accept an optional trailing `iconState`
--- ("Deselected" | "Selected" | "Viewing") that scopes the change to one
--- state; omit it to apply to all three.
---
--- Icons expose their events as signal fields — `selected`, `deselected`,
--- `toggled`, `viewingStarted`, `viewingEnded`, `stateChanged`, `notified`
--- and more — plus class-level signals like `Icon.iconAdded`.
---
--- ```lua a complete icon
--- local Icon = require(game.ReplicatedStorage.Material)
---
--- Icon.new()
---     :setImage(14723463500)
---     :setLabel("Shop")
---     :setCaption("Open the shop")
---     :bindToggleKey(Enum.KeyCode.E)
---     :align("Left")
---     :bindEvent("selected", function(icon)
---         shopGui.Visible = true
---     end)
--- ```
--- @class Icon
--- @section Overview
--- @client

--[[
	
	The majority of this code is an interface designed to make it easy for you to
	work with TopbarPlus (most methods for instance reference :modifyTheme()).
	The processing overhead mainly consists of applying themes and calculating 
	appearance (such as size and width of labels) which is handled in about
	200 lines of code here and the Widget UI module. This has been achieved
	in v3 by outsourcing a majority of previous calculations to inbuilt Roblox
	features like UIListLayouts.


	v3 provides inbuilt support for controllers (simply press DPadUp),
	touch devices (phones, tablets , etc), localization (automatic resizing
	of widgets, autolocalize for relevant labels), backwards compatability
	with the old topbar, and more.


	My primary goals for the v3 re-write have been to:
		
	1. Improve code readability and organisation (reduced lines of code within
	   Icon+IconController from 3200 to ~950, separated UI elements, etc)
		
	2. Improve ease-of-use (themes now actually make sense and can account
	   for any modifications you want, converted to a package for
	   quick installation and easy-comparisons of new updates, etc)
	
	3. Provide support for all key features of the new Roblox topbar
	   while improving performance of the module (deferring and collecting
	   changes then calling as a singular, utilizing inbuilt Roblox features
	   such as UILIstLayouts, etc)

--]]



-- SERVICES
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Types = require(script.Types)



-- TYPES
export type Icon = Types.Icon



-- REFERENCE HANDLER
-- Multiple Icons packages may exist at runtime (for instance if the developer additionally uses HD Admin)
-- therefore this ensures that the first required package becomes the dominant and only functioning module
local iconModule = script
local Reference = require(iconModule.Reference)
local referenceObject = Reference.getObject()
local leadPackage = referenceObject and referenceObject.Value
if leadPackage and leadPackage ~= iconModule then
	return require(leadPackage) :: Types.StaticIcon
end
if not referenceObject then
	Reference.addToReplicatedStorage()
end



-- MODULES
local Signal = require(iconModule.Packages.GoodSignal)
local Janitor = require(iconModule.Packages.Janitor)
local Utility = require(iconModule.Utility)
local Themes = require(iconModule.Features.Themes)
local Gamepad = require(iconModule.Features.Gamepad)
local Overflow = require(iconModule.Features.Overflow)
local Icon = {}
Icon.__index = Icon



-- LOCAL
local localPlayer = Players.LocalPlayer
local themes = iconModule.Features.Themes
local iconsDict = {}
local anyIconSelected = Signal.new()
local elements = iconModule.Elements
local totalCreatedIcons = 0
local preferredInput = {
	mobile = Enum.PreferredInput.Touch,
	desktop = Enum.PreferredInput.KeyboardAndMouse,
	console = Enum.PreferredInput.Gamepad
}



-- PUBLIC VARIABLES
Icon.baseDisplayOrderChanged = Signal.new()
Icon.baseDisplayOrder = 10
Icon.baseTheme = require(themes.Default)
Icon.isOldTopbar = false -- Logic has been moved to Container
Icon.iconsDictionary = iconsDict
Icon.insetHeightChanged = Signal.new()
Icon.container = require(elements.Container)(Icon)
Icon.topbarEnabled = true
Icon.iconAdded = Signal.new()
Icon.iconRemoved = Signal.new()
Icon.iconChanged = Signal.new()



-- PUBLIC FUNCTIONS
--- Returns the dictionary of every existing icon, keyed by UID.
function Icon.getIcons()
	return Icon.iconsDictionary
end

--- Returns the icon with the given UID, or nil.
function Icon.getIconByUID(UID)
	local match = Icon.iconsDictionary[UID]
	if match then
		return match
	end
	return nil
end

--- Finds an icon by the name given via [[Icon:setName]] (or by UID), or nil.
--- @param nameOrUID an icon name, or a UID from `icon.UID`
function Icon.getIcon(nameOrUID)
	local match = Icon.getIconByUID(nameOrUID)
	if match then
		return match
	end
	for _, icon in pairs(iconsDict) do
		if icon.name == nameOrUID then
			return icon
		end
	end
	return nil
end

--- Shows or hides every Material ScreenGui at once (only your icons — the
--- native Roblox topbar is untouched). Call with no argument to re-apply the
--- last stored setting.
--- @param bool false hides all icons; true shows them
--- @param isInternal internal flag — omit this when calling yourself
function Icon.setTopbarEnabled(bool, isInternal)
	if typeof(bool) ~= "boolean" then
		bool = Icon.topbarEnabled
	end
	if not isInternal then
		Icon.topbarEnabled = bool
	end
	for _, screenGui in pairs(Icon.container) do
		screenGui.Enabled = bool
	end
end

--- Merges theme modifications into the base theme and re-themes every
--- current (and future) icon — the way to restyle the whole topbar at once.
--- @param modifications one modification or an array of them — see [[Icon:modifyTheme]] for the format
function Icon.modifyBaseTheme(modifications)
	modifications = Themes.getModifications(modifications)
	for _, modification in pairs(modifications) do
		for _, detail in pairs(Icon.baseTheme) do
			Themes.merge(detail, modification)
		end
	end
	for _, icon in pairs(iconsDict) do
		icon:setTheme(Icon.baseTheme)
	end
end

--- Sets the DisplayOrder of Material's ScreenGuis (default 10) — raise or
--- lower it to layer the icons against your other interfaces.
function Icon.setDisplayOrder(int)
	Icon.baseDisplayOrder = int
	Icon.baseDisplayOrderChanged:Fire(int)
end



-- SETUP
task.defer(Gamepad.start, Icon)
task.defer(Overflow.start, Icon)
task.defer(function()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	for _, screenGui in pairs(Icon.container) do
		screenGui.Parent = playerGui
	end
	require(iconModule.Attribute)
end)



-- CONSTRUCTOR
--- Creates, registers, and returns a new icon: deselected, base-themed,
--- aligned left, with click, touch, hover, and toggle-key input already
--- wired. Icons created from a ScreenGui with `ResetOnSpawn` enabled are
--- destroyed automatically when the player respawns.
function Icon.new()
	local self = {}
	setmetatable(self, Icon)

	-- Janitors (for cleanup)
	local janitor = Janitor.new()
	self.janitor = janitor
	self.themesJanitor = janitor:add(Janitor.new())
	self.singleClickJanitor = janitor:add(Janitor.new())
	self.captionJanitor = janitor:add(Janitor.new())
	self.joinJanitor = janitor:add(Janitor.new())
	self.menuJanitor = janitor:add(Janitor.new())
	self.dropdownJanitor = janitor:add(Janitor.new())

	-- Register
	local iconUID = Utility.generateUID()
	iconsDict[iconUID] = self
	janitor:add(function()
		iconsDict[iconUID] = nil
	end)

	-- Signals (events)
	self.selected = janitor:add(Signal.new())
	self.deselected = janitor:add(Signal.new())
	self.toggled = janitor:add(Signal.new())
	self.viewingStarted = janitor:add(Signal.new())
	self.viewingEnded = janitor:add(Signal.new())
	self.stateChanged = janitor:add(Signal.new())
	self.notified = janitor:add(Signal.new())
	self.noticeStarted = janitor:add(Signal.new())
	self.noticeChanged = janitor:add(Signal.new())
	self.endNotices = janitor:add(Signal.new())
	self.toggleKeyAdded = janitor:add(Signal.new())
	self.fakeToggleKeyChanged = janitor:add(Signal.new())
	self.alignmentChanged = janitor:add(Signal.new())
	self.updateSize = janitor:add(Signal.new())
	self.resizingComplete = janitor:add(Signal.new())
	self.joinedParent = janitor:add(Signal.new())
	self.menuSet = janitor:add(Signal.new())
	self.dropdownSet = janitor:add(Signal.new())
	self.updateMenu = janitor:add(Signal.new())
	self.startMenuUpdate = janitor:add(Signal.new())
	self.childThemeModified = janitor:add(Signal.new())
	self.indicatorSet = janitor:add(Signal.new())
	self.dropdownChildAdded = janitor:add(Signal.new())
	self.menuChildAdded = janitor:add(Signal.new())

	-- Properties
	self.iconModule = iconModule
	self.UID = iconUID
	self.isEnabled = true
	self.enabled = self.isEnabled -- Backwards compatability
	self.isSelected = false
	self.isViewing = false
	self.joinedFrame = false
	self.parentIconUID = false
	self.deselectWhenOtherIconSelected = true
	self.totalNotices = 0
	self.activeState = "Deselected"
	self.alignment = ""
	self.originalAlignment = ""
	self.appliedTheme = {}
	self.appearance = {}
	self.cachedInstances = {}
	self.cachedNamesToInstances = {}
	self.cachedCollectives = {}
	self.bindedToggleKeys = {}
	self.customBehaviours = {}
	self.toggleItems = {}
	self.bindedEvents = {}
	self.notices = {}
	self.menuIcons = {}
	self.dropdownIcons = {}
	self.childIconsDict = {}
	self.creationTime = os.clock()

	-- Widget is the new name for an icon
	local widget = janitor:add(require(elements.Widget)(self, Icon))
	self.widget = widget
	self:setAlignment()
	
	-- It's important we set an order otherwise icons will not align
	-- correctly within menus
	totalCreatedIcons += 1
	local ourOrder = 1+(totalCreatedIcons*0.01)
	self:setOrder(ourOrder, "deselected")
	self:setOrder(ourOrder, "selected")

	-- This applies the default them
	self:setTheme(Icon.baseTheme)

	-- Button Clicked (for states "Selected" and "Deselected")
	local clickRegion = self:getInstance("ClickRegion")
	local hasUsedMouseButton1Click = false
	local lastToggleTime = 0
	local DEBOUNCE_TIME = 0.1 -- 100ms debounce to prevent rapid toggles

	local function handleToggle()
		if self.locked then
			return
		end

		-- Debounce logic to prevent rapid toggling
		local currentTime = tick()
		if currentTime - lastToggleTime < DEBOUNCE_TIME then
			return
		end
		lastToggleTime = currentTime

		if self.isSelected then
			self:deselect("User", self)
		else
			self:select("User", self)
		end
	end

	clickRegion.MouseButton1Click:Connect(function()
		hasUsedMouseButton1Click = true
		handleToggle()
	end)

	clickRegion.TouchTap:Connect(function()
		-- This resolves the bug report by @28Pixels:
		-- https://devforum.roblox.com/t/topbarplus/1017485/1104
		-- Only use TouchTap if MouseButton1Click has never fired
		-- This handles edge cases where ONLY TouchTap works
		-- Also prevents double-toggle bug with multi-touch on mobile
		-- Credit to @sayer80 for this fix
		if not hasUsedMouseButton1Click then
			handleToggle()
		end
	end)

	-- Keys can be bound to toggle between Selected and Deselected
	janitor:add(UserInputService.InputBegan:Connect(function(input, touchingAnObject)
		if self.locked then
			return
		end
		if self.bindedToggleKeys[input.KeyCode] and not touchingAnObject then
			handleToggle()
		end
	end))

	-- Button Hovering (for state "Viewing")
	-- Hovering is a state only for devices with keyboards
	-- and controllers (not touchpads)
	local function viewingStarted(dontSetState)
		if self.locked then
			return
		end
		self.isViewing = true
		self.viewingStarted:Fire(true)
		if not dontSetState then
			self:setState("Viewing", "User", self)
		end
	end
	local function viewingEnded()
		if self.locked then
			return
		end
		self.isViewing = false
		self.viewingEnded:Fire(true)
		self:setState(nil, "User", self)
	end
	self.joinedParent:Connect(function()
		if self.isViewing then
			viewingEnded()
		end
	end)
	clickRegion.MouseEnter:Connect(function()
		local dontSetState = UserInputService.PreferredInput ~= preferredInput.desktop
		viewingStarted(dontSetState)
	end)
	local touchCount = 0
	janitor:add(UserInputService.TouchEnded:Connect(viewingEnded))
	clickRegion.MouseLeave:Connect(viewingEnded)
	clickRegion.SelectionGained:Connect(viewingStarted)
	clickRegion.SelectionLost:Connect(viewingEnded)
	clickRegion.MouseButton1Down:Connect(function()
		if not self.locked and UserInputService.PreferredInput == preferredInput.mobile then
			touchCount += 1
			local myTouchCount = touchCount
			task.delay(0.2, function()
				if myTouchCount == touchCount then
					viewingStarted()
				end
			end)
		end
	end)
	clickRegion.MouseButton1Up:Connect(function()
		touchCount += 1
	end)

	-- Handle overlay on viewing
	local iconOverlay = self:getInstance("IconOverlay")
	self.viewingStarted:Connect(function()
		iconOverlay.Visible = not self.overlayDisabled
	end)
	self.viewingEnded:Connect(function()
		iconOverlay.Visible = false
	end)

	-- Deselect when another icon is selected
	janitor:add(anyIconSelected:Connect(function(incomingIcon)
		if incomingIcon ~= self and self.deselectWhenOtherIconSelected and incomingIcon.deselectWhenOtherIconSelected then
			self:deselect("AutoDeselect", incomingIcon)
		end
	end))

	-- This checks if the script calling this module is a descendant of a ScreenGui
	-- with 'ResetOnSpawn' set to true. If it is, then we destroy the icon the
	-- client respawns. This solves one of the most asked about questions on the post
	-- The only caveat this may not work if the player doesn't uniquely name their ScreenGui and the frames
	-- the LocalScript rests within
	local source =  debug.info(2, "s")
	local sourcePath = string.split(source, ".")
	local origin = game
	local originsScreenGui
	for i, sourceName in pairs(sourcePath) do
		origin = origin:FindFirstChild(sourceName)
		if not origin then
			break
		end
		if origin:IsA("ScreenGui") then
			originsScreenGui = origin
		end
	end
	if origin and originsScreenGui and originsScreenGui.ResetOnSpawn == true then
		self.originsScreenGui = originsScreenGui
		Utility.localPlayerRespawned(function()
			self:destroy()
		end)
	end

	-- Additional children behaviour when toggled (mostly notices)
	self.toggled:Connect(function(isSelected)
		self.noticeChanged:Fire(self.totalNotices)
		for childIconUID, _ in pairs(self.childIconsDict) do
			local childIcon = Icon.getIconByUID(childIconUID)
			childIcon.noticeChanged:Fire(childIcon.totalNotices)
			if not isSelected and childIcon.isSelected then
				-- If an icon within a menu or dropdown is also
				-- a dropdown or menu, then close it
				for _, _ in pairs(childIcon.childIconsDict) do
					childIcon:deselect("HideParentFeature", self)
				end
			end
		end
	end)
	
	-- This closes/reopens the chat or playerlist if the icon is a dropdown
	-- In the future I'd prefer to use the position+size of the chat
	-- to determine whether to close dropdown (instead of non-right-set)
	-- but for reasons mentioned here it's unreliable at the time of
	-- writing this: https://devforum.roblox.com/t/here/2794915
	-- I could also make this better by accounting for multiple
	-- dropdowns being open (not just this one) but this will work
	-- fine for almost every use case for now.
	self.selected:Connect(function()
		local isDropdown = #self.dropdownIcons > 0
		if isDropdown then
			if StarterGui:GetCore("ChatActive") and self.alignment ~= "Right" then
				self.chatWasPreviouslyActive = true
				StarterGui:SetCore("ChatActive", false)
			end
			if StarterGui:GetCoreGuiEnabled("PlayerList") and self.alignment ~= "Left" then
				self.playerlistWasPreviouslyActive = true
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end
		end
	end)
	self.deselected:Connect(function()
		if self.chatWasPreviouslyActive then
			self.chatWasPreviouslyActive = nil
			StarterGui:SetCore("ChatActive", true)
		end
		if self.playerlistWasPreviouslyActive then
			self.playerlistWasPreviouslyActive = nil
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end
	end)
	
	-- There's a rare occassion where the appearance is not
	-- fully set to deselected so this ensures the icons
	-- appearance is fully as it should be
	task.delay(0.1, function()
		if self.activeState == "Deselected" then
			self.stateChanged:Fire("Deselected")
			self:refresh()
		end
	end)
	
	-- Call icon added
	Icon.iconAdded:Fire(self)

	return self
end



-- METHODS
--- Names the icon (and its widget instance) so [[Icon.getIcon]] can find it.
function Icon:setName(name)
	self.widget.Name = name
	self.name = name
	return self
end

function Icon:setState(incomingStateName, fromSource, sourceIcon)
	-- This is responsible for acknowleding a change in stage (such as from "Deselected" to "Viewing" when
	-- a users mouse enters the widget), then informing other systems of this state change to then act upon
	-- (such as the theme handler applying the theme which corresponds to that state).
	if not incomingStateName then
		incomingStateName = (self.isSelected and "Selected") or "Deselected"
	end
	local stateName = Utility.formatStateName(incomingStateName)
	local previousStateName = self.activeState
	if previousStateName == stateName then
		return
	end
	local currentIsSelected = self.isSelected
	self.activeState = stateName
	if stateName == "Deselected" then
		self.isSelected = false
		if currentIsSelected then
			self.toggled:Fire(false, fromSource, sourceIcon)
			self.deselected:Fire(fromSource, sourceIcon)
		end
		self:_setToggleItemsVisible(false, fromSource, sourceIcon)
	elseif stateName == "Selected" then
		self.isSelected = true
		if not currentIsSelected then
			self.toggled:Fire(true, fromSource, sourceIcon)
			self.selected:Fire(fromSource, sourceIcon)
			anyIconSelected:Fire(self, fromSource, sourceIcon)
		end
		self:_setToggleItemsVisible(true, fromSource, sourceIcon)
	end
	self.stateChanged:Fire(stateName, fromSource, sourceIcon)
end

--- Returns the instance with that name inside the icon's widget (every
--- significant instance is uniquely named, and results are cached). The
--- escape hatch for customization beyond what themes cover.
--- @param name e.g. "IconLabel", "IconImage", "ClickRegion", "Widget"
function Icon:getInstance(name)
	-- This enables us to easily retrieve instances located within the icon simply by passing its name.
	-- Every important/significant instance is named uniquely therefore this is no worry of overlap.
	-- We cache the result for more performant retrieval in the future.
	local instance = self.cachedNamesToInstances[name]
	if instance then
		return instance
	end
	local function cacheInstance(childName, child)
		local currentCache = self.cachedInstances[child]
		if not currentCache then
			local collectiveName = child:GetAttribute("Collective")
			local cachedCollective = collectiveName and self.cachedCollectives[collectiveName]
			if cachedCollective then
				table.insert(cachedCollective, child)
			end
			self.cachedNamesToInstances[childName] = child
			self.cachedInstances[child] = true
			child.Destroying:Once(function()
				self.cachedNamesToInstances[childName] = nil
				self.cachedInstances[child] = nil
			end)
		end
	end
	local widget = self.widget
	cacheInstance("Widget", widget)
	if name == "Widget" then
		return widget
	end

	local returnChild
	local function scanChildren(parentInstance)
		for _, child in pairs(parentInstance:GetChildren()) do
			local widgetUID = child:GetAttribute("WidgetUID")
			if widgetUID and widgetUID ~= self.UID then
				-- This prevents instances within other icons from being recorded
				-- (for instance when other icons are added to this icons menu)
				continue
			end
			-- If the child is a fake placeholder instance (such as dropdowns, notices, etc)
			-- then its important we scan the real original instance instead of this clone
			local realChild = Themes.getRealInstance(child)
			if realChild then
				child = realChild
			end
			-- Finally scan its children
			scanChildren(child)
			if child:IsA("GuiBase") or child:IsA("UIBase") or child:IsA("ValueBase") then
				local childName = child.Name
				cacheInstance(childName, child)
				if childName == name then
					returnChild = child
				end
			end
		end
	end
	scanChildren(widget)
	return returnChild
end

function Icon:getCollective(name)
	-- A collective is an array of instances within the Widget that have been
	-- grouped together based on a given name. This just makes it easy
	-- to act on multiple instances at once which share similar behaviours.
	-- For instance, if we want to change the icons corner size, all corner instances
	-- with the attribute "Collective" and value "WidgetCorner" could be updated
	-- instantly by doing Themes.apply(icon, "WidgetCorner", newSize)
	local collective = self.cachedCollectives[name]
	if collective then
		return collective
	end
	collective = {}
	for instance, _ in pairs(self.cachedInstances) do
		if instance:GetAttribute("Collective") == name then
			table.insert(collective, instance)
		end
	end
	self.cachedCollectives[name] = collective
	return collective
end

function Icon:getInstanceOrCollective(collectiveOrInstanceName)
	-- Similar to :getInstance but also accounts for 'Collectives', such as UICorners and returns
	-- an array of instances instead of a single instance
	local instances = {}
	local instance = self:getInstance(collectiveOrInstanceName)
	if instance then
		table.insert(instances, instance)
	end
	if #instances == 0 then
		instances = self:getCollective(collectiveOrInstanceName)
	end
	return instances
end

function Icon:getStateGroup(iconState)
	local chosenState = iconState or self.activeState
	local stateGroup = self.appearance[chosenState]
	if not stateGroup then
		stateGroup = {}
		self.appearance[chosenState] = stateGroup
	end
	return stateGroup
end

function Icon:refreshAppearance(instance, specificProperty)
	Themes.refresh(self, instance, specificProperty)
	return self
end

function Icon:refresh()
	self:refreshAppearance(self.widget)
	self.updateSize:Fire()
	return self
end

function Icon:updateParent()
	local parentIcon = Icon.getIconByUID(self.parentIconUID)
	if parentIcon then
		parentIcon.updateSize:Fire()
	end
end

--- Registers a callback that runs just before the theme system writes a
--- property, letting you intercept and transform the value — return the
--- value you want actually applied.
--- @param collectiveOrInstanceName the instance (or collective group) to intercept
--- @param property the property being written
--- @param callback receives the incoming value, returns the final one
--- @param refreshAppearance true to re-apply the property immediately
function Icon:setBehaviour(collectiveOrInstanceName, property, callback, refreshAppearance)
	-- You can specify your own custom callback to handle custom logic just before
	-- an instances property is changed by using :setBehaviour()
	local key = collectiveOrInstanceName.."-"..property
	self.customBehaviours[key] = callback
	if refreshAppearance then
		local instances = self:getInstanceOrCollective(collectiveOrInstanceName)
		for _, instance in pairs(instances) do
			self:refreshAppearance(instance, property)
		end
	end
end

--- Applies theme modifications to this icon. A modification is
--- `{instanceName, property, value, iconState?}` — pass one or an array of
--- them. Also returns a modification UID for [[Icon:removeModification]].
---
--- ```lua recolor one icon's background while selected
--- icon:modifyTheme({"IconButton", "BackgroundColor3", Color3.fromRGB(255, 89, 89), "Selected"})
--- ```
function Icon:modifyTheme(modifications, customModificationUID)
	local modificationUID = Themes.modify(self, modifications, customModificationUID)
	return self, modificationUID
end

--- Like [[Icon:modifyTheme]], but applied to the icon's child icons (those
--- in its menu or dropdown), both current and future ones.
function Icon:modifyChildTheme(modifications, modificationUID)
	-- Same as modifyTheme except for its children (i.e. icons
	-- within its dropdown or menu)
	self.childModifications = modifications
	self.childModificationsUID = modificationUID
	for childIconUID, _ in pairs(self.childIconsDict) do
		local childIcon = Icon.getIconByUID(childIconUID)
		childIcon:modifyTheme(modifications, modificationUID)
	end
	self.childThemeModified:Fire()
	return self
end

--- Removes a modification previously applied with [[Icon:modifyTheme]],
--- using the UID it returned.
function Icon:removeModification(modificationUID)
	Themes.remove(self, modificationUID)
	return self
end

--- Removes every modification matching the given instance name, property,
--- and (optionally) state — when you don't have a UID to hand.
function Icon:removeModificationWith(instanceName, property, state)
	Themes.removeWith(self, instanceName, property, state)
	return self
end

--- Replaces the icon's entire theme (see `Features/Themes/Default.lua` for
--- the shape of a full theme table).
function Icon:setTheme(theme)
	Themes.set(self, theme)
	return self
end

--- Shows or hides the icon (widget visibility plus parent layout update).
function Icon:setEnabled(bool)
	self.isEnabled = bool
	self.enabled = self.isEnabled
	self.widget.Visible = bool
	self:updateParent()
	return self
end

--- Selects the icon programmatically — fires `selected` and `toggled`, shows
--- bound toggle items, and (by default) deselects other icons.
--- @param fromSource optional label describing what caused the selection
--- @param sourceIcon optional icon that caused it
function Icon:select(fromSource, sourceIcon)
	self:setState("Selected", fromSource, sourceIcon)
	return self
end

--- Deselects the icon programmatically — fires `deselected` and `toggled`
--- and hides bound toggle items.
--- @param fromSource optional label describing what caused the deselection
--- @param sourceIcon optional icon that caused it
function Icon:deselect(fromSource, sourceIcon)
	self:setState("Deselected", fromSource, sourceIcon)
	return self
end

--- Adds a notice — the counter badge in the icon's corner. Each call
--- increments the count; the notice clears when the given signal fires
--- (the icon's `deselected` by default).
--- @param customClearSignal a signal or RBXScriptSignal that clears this notice
--- @param noticeId optional id so the same notice isn't counted twice
function Icon:notify(customClearSignal, noticeId)
	-- Generates a notification which appears in the top right of the icon. Useful for example for prompting
	-- users of changes/updates within your UI such as a Catalog
	-- 'customClearSignal' is a signal object (e.g. icon.deselected) or
	-- Roblox event (e.g. Instance.new("BindableEvent").Event)
	local notice = self.notice
	if not notice then
		notice = require(elements.Notice)(self, Icon)
		self.notice = notice
	end
	self.noticeStarted:Fire(customClearSignal, noticeId)
	return self
end

--- Clears every active notice on the icon.
function Icon:clearNotices()
	self.endNotices:Fire()
	return self
end

--- Disables the highlight overlay shown while hovering the icon
--- (alias: `disableStateOverlay`).
function Icon:disableOverlay(bool)
	self.overlayDisabled = bool
	return self
end
Icon.disableStateOverlay = Icon.disableOverlay

--- Sets the icon's image and preloads the asset so it doesn't pop in late.
--- @param imageId an asset id number, or a full asset string
--- @param iconState optionally scope to "Deselected" | "Selected" | "Viewing"
function Icon:setImage(imageId, iconState)
	self:modifyTheme({"IconImage", "Image", imageId, iconState})
	
	-- This code ensures icon images are preloaded if they haven't been fetched yet
	task.spawn(function()
		local newIdContent = if tonumber(imageId) then `rbxassetid://{imageId}` else imageId
		local initialAssetFetchStatus = ContentProvider:GetAssetFetchStatus(newIdContent)
	
		if initialAssetFetchStatus ~= Enum.AssetFetchStatus.Success then
			pcall(ContentProvider.PreloadAsync, ContentProvider, { newIdContent })
		end
	end)
		
	return self
end

--- Sets the icon's text label; the widget resizes automatically to fit.
function Icon:setLabel(text, iconState)
	self:modifyTheme({"IconLabel", "Text", text, iconState})
	return self
end

--- Sets the icon's position among its neighbours (lower appears first).
--- Decimals work — internally scaled so `1.5` slots between `1` and `2`.
function Icon:setOrder(int, iconState)
	-- We multiply by 100 to allow for custom increments inbetween
	-- (.01, .02, etc) as LayoutOrders only support integers
	local newInt = int*100
	self:modifyTheme({"IconSpot", "LayoutOrder", newInt, iconState})
	self:modifyTheme({"Widget", "LayoutOrder", newInt, iconState})
	return self
end

--- Sets the corner radius of the icon's corner instances (fully round by
--- default).
function Icon:setCornerRadius(udim, iconState)
	self:modifyTheme({"IconCorners", "CornerRadius", udim, iconState})
	return self
end

--- Moves the icon to the left, center, or right group of the topbar
--- (alias: `setAlignment`). Accepts "left" | "center" | "right" (and "mid" /
--- "centre"); anything else falls back to left.
function Icon:align(leftCenterOrRight, isFromParentIcon)
	-- Determines the side of the screen the icon will be ordered
	local direction = tostring(leftCenterOrRight):lower()
	if direction == "mid" or direction == "centre" then
		direction = "center"
	end
	if direction ~= "left" and direction ~= "center" and direction ~= "right" then
		direction = "left"
	end
	local screenGui = (direction == "center" and Icon.container.TopbarCentered) or Icon.container.TopbarStandard
	local holders = screenGui.Holders
	local finalDirection = string.upper(string.sub(direction, 1, 1))..string.sub(direction, 2)
	if not isFromParentIcon then
		self.originalAlignment = finalDirection
	end
	local joinedFrame = self.joinedFrame
	local alignmentHolder = holders[finalDirection]
	self.screenGui = screenGui
	self.alignmentHolder = alignmentHolder
	if not self.isDestroyed then
		self.widget.Parent = joinedFrame or alignmentHolder
	end
	self.alignment = finalDirection
	self.alignmentChanged:Fire(finalDirection)
	Icon.iconChanged:Fire(self)
	return self
end
Icon.setAlignment = Icon.align

--- Shorthand for `align("Left")`.
function Icon:setLeft()
	self:setAlignment("Left")
	return self
end

--- Shorthand for `align("Center")`.
function Icon:setMid()
	self:setAlignment("Center")
	return self
end

--- Shorthand for `align("Right")`.
function Icon:setRight()
	self:setAlignment("Right")
	return self
end

--- Sets a minimum pixel width for the widget — useful when a label changes
--- frequently and you don't want the icon resizing every time.
function Icon:setWidth(offsetMinimum, iconState)
	-- This sets a minimum X offset size for the widget, useful
	-- for example if you're constantly changing the label
	-- but don't want the icon to resize every time
	self:modifyTheme({"Widget", "DesiredWidth", offsetMinimum, iconState})
	return self
end

--- Scales the image within its cell (default 0.5 deselected, 0.7 selected).
function Icon:setImageScale(number, iconState)
	self:modifyTheme({"IconImageScale", "Value", number, iconState})
	return self
end

--- Sets the image's aspect ratio (1 = square).
function Icon:setImageRatio(number, iconState)
	self:modifyTheme({"IconImageRatio", "AspectRatio", number, iconState})
	return self
end

--- Sets the label's text size.
function Icon:setTextSize(number, iconState)
	self:modifyTheme({"IconLabel", "TextSize", number, iconState})
	return self
end

--- Sets the label's font. Accepts a font family name, a font asset id, an
--- `Enum.Font`, or an asset path — weight and style are optional.
--- @param font name, id, Enum.Font, or asset path
--- @param fontWeight an Enum.FontWeight (default Regular)
--- @param fontStyle an Enum.FontStyle (default Normal)
--- @param iconState optionally scope to one state
function Icon:setTextFont(font, fontWeight, fontStyle, iconState)
	fontWeight = fontWeight or Enum.FontWeight.Regular
	fontStyle = fontStyle or Enum.FontStyle.Normal
	local fontFace
	local fontType = typeof(font)
	if fontType == "number" then
		fontFace = Font.fromId(font, fontWeight, fontStyle)
	elseif fontType == "EnumItem" then
		fontFace = Font.fromEnum(font)
	elseif fontType == "string" then
		if not font:match("rbxasset") then
			fontFace = Font.fromName(font, fontWeight, fontStyle)
		end
	end
	if not fontFace then
		fontFace = Font.new(font, fontWeight, fontStyle)
	end
	self:modifyTheme({"IconLabel", "FontFace", fontFace, iconState})
	return self
end

--- Sets the label's text color (falls back to white, with a warning, if
--- given a non-Color3).
function Icon:setTextColor(Color, iconState)
	if Color == nil or Color == "" or (type(Color) ~= "userdata" or typeof(Color) ~= "Color3") then
		if Color ~= nil and Color ~= "" then
			warn("setTextColor item must be a Color3 value! Changed the color to white.")
		end
		Color = Color3.fromRGB(255, 255, 255)
	end

	self:modifyTheme({"IconLabel", "TextColor3", Color, iconState})
	return self
end

--- Binds a GuiObject or LayerCollector to the icon's selected state: it is
--- shown on select and hidden on deselect — the one-liner for "this button
--- opens this menu".
function Icon:bindToggleItem(guiObjectOrLayerCollector)
	if not guiObjectOrLayerCollector:IsA("GuiObject") and not guiObjectOrLayerCollector:IsA("LayerCollector") then
		error("Toggle item must be a GuiObject or LayerCollector!")
	end
	self.toggleItems[guiObjectOrLayerCollector] = true
	self:_updateSelectionInstances()
	return self
end

--- Unbinds an item previously bound with [[Icon:bindToggleItem]].
function Icon:unbindToggleItem(guiObjectOrLayerCollector)
	self.toggleItems[guiObjectOrLayerCollector] = nil
	self:_updateSelectionInstances()
	return self
end

function Icon:_updateSelectionInstances()
	-- This is to assist with controller navigation and selection
	-- It converts the value true to an array
	for guiObjectOrLayerCollector, _ in pairs(self.toggleItems) do
		local buttonInstancesArray = {}
		for _, instance in pairs(guiObjectOrLayerCollector:GetDescendants()) do
			if (instance:IsA("TextButton") or instance:IsA("ImageButton")) and instance.Active then
				table.insert(buttonInstancesArray, instance)
			end
		end
		self.toggleItems[guiObjectOrLayerCollector] = buttonInstancesArray
	end
end

function Icon:_setToggleItemsVisible(bool, fromSource, sourceIcon)
	for toggleItem, _ in pairs(self.toggleItems) do
		if not sourceIcon or sourceIcon == self or sourceIcon.toggleItems[toggleItem] == nil then
			local property = "Visible"
			if toggleItem:IsA("LayerCollector") then
				property = "Enabled"
			end
			toggleItem[property] = bool
		end
	end
end

--- Connects a handler to one of the icon's signals by name (`"selected"`,
--- `"deselected"`, `"toggled"`, …). The handler receives the icon first,
--- then the signal's own arguments. One binding per event name — rebinding
--- replaces via [[Icon:unbindEvent]].
function Icon:bindEvent(iconEventName, eventFunction)
	local event = self[iconEventName]
	assert(event and typeof(event) == "table" and event.Connect, "argument[1] must be a valid topbarplus icon event name!")
	assert(typeof(eventFunction) == "function", "argument[2] must be a function!")
	self.bindedEvents[iconEventName] = event:Connect(function(...)
		eventFunction(self, ...)
	end)
	return self
end

--- Disconnects a handler bound with [[Icon:bindEvent]].
function Icon:unbindEvent(iconEventName)
	local eventConnection = self.bindedEvents[iconEventName]
	if eventConnection then
		eventConnection:Disconnect()
		self.bindedEvents[iconEventName] = nil
	end
	return self
end

--- Binds a keyboard key that toggles the icon, and surfaces it as a hotkey
--- chip in the caption.
--- @param keyCodeEnum e.g. Enum.KeyCode.E
function Icon:bindToggleKey(keyCodeEnum)
	assert(typeof(keyCodeEnum) == "EnumItem", "argument[1] must be a KeyCode EnumItem!")
	self.bindedToggleKeys[keyCodeEnum] = true
	self.toggleKeyAdded:Fire(keyCodeEnum)
	self:setCaption("_hotkey_")
	return self
end

--- Unbinds a key bound with [[Icon:bindToggleKey]].
function Icon:unbindToggleKey(keyCodeEnum)
	assert(typeof(keyCodeEnum) == "EnumItem", "argument[1] must be a KeyCode EnumItem!")
	self.bindedToggleKeys[keyCodeEnum] = nil
	return self
end

--- Spawns `callback(icon, ...)` — lets you run arbitrary logic without
--- breaking a method chain.
function Icon:call(callback, ...)
	local packedArgs = table.pack(...)
	task.spawn(function()
		callback(self, table.unpack(packedArgs))
	end)
	return self
end

--- Registers anything (connection, instance, function) with the icon's
--- janitor so it is cleaned up when the icon is destroyed.
function Icon:addToJanitor(callback, methodName, index)
	self.janitor:add(callback, methodName, index)
	return self
end

--- Blocks all user input on the icon (clicks, touches, toggle keys). Undo
--- with [[Icon:unlock]].
function Icon:lock()
	-- This disables all user inputs related to the icon (such as clicking buttons, pressing keys, etc)
	local clickRegion = self:getInstance("ClickRegion")
	clickRegion.Visible = false
	self.locked = true
	return self
end

--- Re-enables user input after [[Icon:lock]].
function Icon:unlock()
	local clickRegion = self:getInstance("ClickRegion")
	clickRegion.Visible = true
	self.locked = false
	return self
end

--- Locks the icon for the given duration, then unlocks. **Yields** for the
--- full duration.
function Icon:debounce(seconds)
	self:lock()
	task.wait(seconds)
	self:unlock()
	return self
end

--- Controls whether this icon deselects itself when another icon is
--- selected (default true). Pass false for independent icons.
function Icon:autoDeselect(bool)
	-- When set to true the icon will deselect itself automatically whenever
	-- another icon is selected
	if bool == nil then
		bool = true
	end
	self.deselectWhenOtherIconSelected = bool
	return self
end

--- Turns the icon into a momentary button: it deselects itself immediately
--- after every selection, so it fires `selected` but never stays lit.
function Icon:oneClick(bool)
	-- When set to true the icon will automatically deselect when selected, this creates
	-- the effect of a single click button
	local singleClickJanitor = self.singleClickJanitor
	singleClickJanitor:clean()
	if bool or bool == nil then
		singleClickJanitor:add(self.selected:Connect(function()
			self:deselect("OneClick", self)
		end))
	end
	self.oneClickEnabled = true
	return self
end

--- Sets the caption tooltip shown while hovering (or long-pressing) the
--- icon. Pass nothing or "" to remove it.
function Icon:setCaption(text)
	if text == "_hotkey_" and (self.captionText) then
		return self
	end
	local captionJanitor = self.captionJanitor
	self.captionJanitor:clean()
	if not text or text == "" then
		self.caption = nil
		self.captionText = nil
		return self
	end
	local caption = captionJanitor:add(require(elements.Caption)(self))
	caption:SetAttribute("CaptionText", text)
	self.caption = caption
	self.captionText = text
	return self
end

--- Shows a hotkey chip in the caption for a key handled by your own code —
--- like [[Icon:bindToggleKey]]'s chip, without Material binding the key.
function Icon:setCaptionHint(keyCodeEnum)
	assert(typeof(keyCodeEnum) == "EnumItem", "argument[1] must be a KeyCode EnumItem!")
	self.fakeToggleKey = keyCodeEnum
	self.fakeToggleKeyChanged:Fire(keyCodeEnum)
	self:setCaption("_hotkey_")
	return self
end

--- Removes the icon from the menu or dropdown it joined, returning it to
--- the topbar.
function Icon:leave()
	local joinJanitor = self.joinJanitor
	joinJanitor:clean()
	return self
end

--- Moves this icon into another icon's menu (the horizontal row that
--- expands when the parent is selected). Leave with [[Icon:leave]].
function Icon:joinMenu(parentIcon)
	Utility.joinFeature(self, parentIcon, parentIcon.menuIcons, parentIcon:getInstance("Menu"))
	parentIcon.menuChildAdded:Fire(self)
	return self
end

--- Gives this icon a menu containing the given icons — the array-of-icons
--- way to build what [[Icon:joinMenu]] does one icon at a time.
function Icon:setMenu(arrayOfIcons)
	self.menuSet:Fire(arrayOfIcons)
	return self
end

--- Sets a menu that is permanently open ([[Icon:freezeMenu]] + [[Icon:setMenu]];
--- alias: `setFrozenMenu`).
function Icon:setFixedMenu(arrayOfIcons)
	self:freezeMenu(arrayOfIcons)
	self:setMenu(arrayOfIcons)
end
Icon.setFrozenMenu = Icon.setFixedMenu

--- Locks the icon's menu permanently open: the icon is selected, re-selects
--- itself if deselected, and hides its toggle spot.
function Icon:freezeMenu()
	-- A frozen menu is a menu which is permanently locked in the
	-- the selected state (with its toggle hidden)
	self:select("FrozenMenu", self)
	self:bindEvent("deselected", function(icon)
		icon:select("FrozenMenu", self)
	end)
	self:modifyTheme({"IconSpot", "Visible", false})
end

--- Moves this icon into another icon's dropdown (the vertical list beneath
--- it). Leave with [[Icon:leave]].
function Icon:joinDropdown(parentIcon)
	parentIcon:getDropdown()
	Utility.joinFeature(self, parentIcon, parentIcon.dropdownIcons, parentIcon:getInstance("DropdownScroller"))
	parentIcon.dropdownChildAdded:Fire(self)
	return self
end

--- Returns the icon's dropdown, creating it on first call.
function Icon:getDropdown()
	local dropdown = self.dropdown
	if not dropdown then
		dropdown = require(elements.Dropdown)(self)
		self.dropdown = dropdown
		self:clipOutside(dropdown)
	end
	return dropdown
end

--- Gives this icon a dropdown containing the given icons — the array way to
--- build what [[Icon:joinDropdown]] does one icon at a time.
function Icon:setDropdown(arrayOfIcons)
	self:getDropdown()
	self.dropdownSet:Fire(arrayOfIcons)
	return self
end

--- Advanced: lets an instance escape the widget's clipping bounds (used
--- internally for notices and dropdowns) by tracking an invisible
--- placeholder. Returns the icon and the placeholder clone.
function Icon:clipOutside(instance)
	-- This is essential for items such as notices and dropdowns which will exceed the bounds of the widget. This is an issue
	-- because the widget must have ClipsDescendents enabled to hide items for instance when the menu is closing or opening.
	-- This creates an invisible frame which matches the size and position of the instance, then the instance is parented outside of
	-- the widget and tracks the clone to match its size and position. In order for themes, etc to work the applying system checks
	-- to see if an instance is a clone, then if it is, it applies it to the original instance instead of the clone.
	local instanceClone = Utility.clipOutside(self, instance)
	self:refreshAppearance(instance)
	return self, instanceClone
end

--- Shows a controller button prompt next to the icon for the given key.
--- Gamepad topbar navigation sets this automatically; call it yourself only
--- for custom prompts.
function Icon:setIndicator(keyCode)
	-- An indicator is a direction button prompt with an image of the given keycode. This is useful for instance
	-- with controllers to show the user what button to press to highlight the topbar. You don't need
	-- to set an indicator for controllers as this is handled internally within the Gamepad module
	local indicator = self.indicator
	if not indicator then
		indicator = self.janitor:add(require(elements.Indicator)(self, Icon))
		self.indicator = indicator
	end
	self.indicatorSet:Fire(keyCode)
end

--- Replaces the icon's label with a NumberSpinner object (boatbomber's
--- module) for animated rolling numbers — currency counters and the like.
--- The spinner inherits the label's font and colors and resizes with the icon.
function Icon:convertLabelToNumberSpinner(numberSpinner, callback)
	task.defer(function()
		
		local label = self:getInstance("IconLabel")
		label.Transparency = 1
		numberSpinner.Parent = label.Parent
		numberSpinner.Size = UDim2.fromScale(1, 1)
		numberSpinner.AnchorPoint = Vector2.new(0.5, 0.5)
		numberSpinner.Position = UDim2.new(0.5, 0, 0.5, 0)
		numberSpinner.TextXAlignment = Enum.TextXAlignment.Center
		numberSpinner.ClipsDescendants = false

		local propertiesToChangeLabel = {
			"FontFace",
			"BorderSizePixel",
			"BorderColor3",
			"Rotation",
			"TextStrokeTransparency",
			"TextStrokeColor3",
			"TextStrokeTransparency",
			"TextColor3",
		}
		for _, property in ipairs(propertiesToChangeLabel) do
			numberSpinner[property] = label[property]
			self:addToJanitor(label:GetPropertyChangedSignal(property):Connect(function()
				numberSpinner[property] = label[property]
			end))
		end

		local minDigits = 0
		local maxDigits = 8
		local function getSpinnerSizeAndDigitCount()
			local TotalSize = 0
			local numOfDigits = 0
			for i, child in numberSpinner.Frame:GetChildren() do
				local name = string.lower(child.Name)
				if name == "digit" then
					TotalSize += child.AbsoluteSize.X
					numOfDigits += 1
				elseif name == "prefix" or name == "suffix" or name == "comma" then
					if child.Text ~= "" then
						TotalSize += child.AbsoluteSize.X
						numOfDigits += 1
					end
				end
			end
			return TotalSize, numOfDigits
		end
		
		local function getLabelParentContainerXSize()
			local firstParent = label.Parent
			local nextParent = firstParent and firstParent.Parent
			if nextParent == nil then
				return 0
			end
			if nextParent.IconImage.Visible == true then
				return numberSpinner.Frame.AbsoluteSize.X + label.Parent.Parent.IconImage.AbsoluteSize.X
			else
				return nextParent.AbsoluteSize.X
			end
		end
		local function getNumberSpinnerXSize()
			return numberSpinner.Frame.AbsoluteSize.X
		end

		local function adjustSize()
			local totalDigitXSize, numOfDigits = getSpinnerSizeAndDigitCount()
			if numOfDigits < 18 then
				self:setLabel(numberSpinner.Value)
			end

			local NumberSpinnerXSize = getNumberSpinnerXSize()

			while totalDigitXSize < NumberSpinnerXSize and self.isDestroyed ~= true do
				task.wait(0.05)
				if numOfDigits > minDigits and numOfDigits < maxDigits then
					numberSpinner.TextSize = label.TextSize
					break
				else
					numberSpinner.TextSize += 1
				end

				NumberSpinnerXSize = getNumberSpinnerXSize()
				totalDigitXSize, numOfDigits = getSpinnerSizeAndDigitCount()
			end

			local labelParentContainerXSize = getLabelParentContainerXSize()
			while totalDigitXSize > labelParentContainerXSize and self.isDestroyed ~= true do
				task.wait(0.05)
				if numOfDigits < maxDigits and numOfDigits > minDigits then
					numberSpinner.TextSize = label.TextSize
					break
				else
					numberSpinner.TextSize -= 1
				end

				labelParentContainerXSize = getLabelParentContainerXSize()
				totalDigitXSize, numOfDigits = getSpinnerSizeAndDigitCount()
			end
		end

		self:addToJanitor(numberSpinner.Frame.ChildAdded:Connect(adjustSize))
		self:addToJanitor(numberSpinner.Frame.ChildRemoved:Connect(adjustSize))
		self:addToJanitor(self.iconAdded:Connect(function()
			task.wait(1)
			adjustSize()
		end))

		self:updateParent()

		-- This corrects text to the size of a normal label
		numberSpinner.Name = "LabelSpinner"
		numberSpinner.Prefix = "$"
		numberSpinner.Commas = true
		numberSpinner.Decimals = 0
		numberSpinner.Duration = 0.25
		numberSpinner.Value = 10
		task.wait(0.2)
		
		if typeof(callback) == "function" then
			callback()
		end
		
	end)
	return self
end



-- DESTROY/CLEANUP
--- Destroys the icon and everything it owns: notices cleared, menus and
--- dropdowns left, instances and connections cleaned via the janitor
--- (alias: `Destroy`).
function Icon:destroy()
	if self.isDestroyed then
		return
	end
	self:clearNotices()
	if self.parentIconUID then
		self:leave()
	end
	self.isDestroyed = true
	self.janitor:clean()
	Icon.iconRemoved:Fire(self)
end
Icon.Destroy = Icon.destroy

return Icon :: Types.StaticIcon
