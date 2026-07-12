--!strict

-- GoodSignal Types (...but simpler!)

-- Connection

type Connection<Variant... = ...any> = {
	Disconnect: (self: Connection<Variant...>) -> (),
}

-- Signal

type Signal<Variant... = ...any> = {
	Connect: (self: Signal<Variant...>, func: (Variant...) -> ()) -> Connection<Variant...>,
    Once: (self: Signal<Variant...>, func: (Variant...) -> ()) -> Connection<Variant...>,
	Wait: (self: Signal<Variant...>) -> Variant...,
}

----------------------

export type IconState = "Deselected" | "Selected" | "Viewing"
export type Events = "selected" | "deselected" | "toggled" | "viewingStarted" | "viewingEnded" | "notified"
export type Alignment = "Left" | "Center" | "Right"
export type EventSource = "User" | "OneClick" | "AutoDeselect" | "HideParentFeature" | "Overflow"
export type Modification = { any }


---------------------- WINDOWS & OVERLAYS (Material additions) ----------------------

-- A draggable, resizable window emulating Roblox's in-game core UI.
export type Window = {
	-- fields
	UID: string,
	title: string,
	isOpen: boolean,
	isMinimized: boolean,
	isMaximized: boolean,
	isModal: boolean,
	root: Frame,
	body: Frame,
	-- events
	opened: Signal,
	closed: Signal,
	minimized: Signal,
	maximized: Signal,
	restored: Signal,
	focused: Signal,
	moved: Signal<number, number>,
	resized: Signal<number, number>,
	-- methods (chainable)
	setTitle: (self: Window, text: string) -> Window,
	setIcon: (self: Window, imageId: (number | string)?) -> Window,
	setSize: (self: Window, width: number, height: number) -> Window,
	setPosition: (self: Window, x: number, y: number) -> Window,
	center: (self: Window) -> Window,
	setDraggable: (self: Window, enabled: boolean) -> Window,
	setResizable: (self: Window, enabled: boolean) -> Window,
	setHeaderVisible: (self: Window, enabled: boolean) -> Window,
	setModal: (self: Window, enabled: boolean, dismissable: boolean?) -> Window,
	adopt: (self: Window, guiObject: GuiObject) -> Window,
	release: (self: Window) -> Window,
	getBody: (self: Window) -> Frame,
	open: (self: Window) -> Window,
	close: (self: Window) -> Window,
	toggle: (self: Window) -> Window,
	minimize: (self: Window) -> Window,
	maximize: (self: Window) -> Window,
	restore: (self: Window) -> Window,
	focus: (self: Window) -> Window,
	destroy: (self: Window) -> (),
}

export type StaticWindow = {
	new: typeof(
		--[[
			Constructs a hidden, centered 480x320 window. Call <code>:open()</code> to show it.
		]]
		function(): Window
			return (nil :: any) :: Window
		end
	),
}

-- Config accepted by icon:setWindow(); every field optional.
export type WindowConfig = {
	title: string?,
	icon: (number | string)?,
	width: number?,
	height: number?,
	modal: boolean?,
	resizable: boolean?,
}

-- The singleton that owns the shared window layer, z-order, focus, and dock feed.
export type WindowController = {
	windows: { [string]: Window },
	activeWindow: Window?,
	baseDisplayOrder: number,
	windowRegistered: Signal<Window>,
	windowUnregistered: Signal<Window>,
	windowMinimized: Signal<Window>,
	windowRestored: Signal<Window>,
	activeChanged: Signal,
	getLayer: () -> ScreenGui,
	getBackdrop: () -> Frame,
	register: (window: Window) -> (),
	unregister: (window: Window) -> (),
	notifyMinimized: (window: Window) -> (),
	notifyRestored: (window: Window) -> (),
	focus: (window: Window) -> (),
	getWindows: () -> { [string]: Window },
	closeAll: () -> (),
}

-- An optional taskbar of minimized windows.
export type Dock = {
	enabled: boolean,
	setEnabled: (enabled: boolean) -> Dock,
	getInstance: () -> Frame,
}

export type ToastOptions = {
	duration: number?,          -- seconds before auto-dismiss (default 3)
	icon: (number | string)?,   -- optional leading icon (asset id or string)
	action: string?,            -- optional action button label
	onAction: (() -> ())?,      -- action button callback
	color: Color3?,             -- action button colour (default Roblox blue)
}
export type Toast = {
	show: (text: string, options: ToastOptions?) -> () -> (),
}

export type DialogButton = {
	text: string,
	primary: boolean?,
	danger: boolean?,
	onClick: (() -> ())?,
}
export type DialogOptions = {
	title: string?,
	message: string,
	buttons: { DialogButton }?,
	dismissable: boolean?,
	width: number?,
}
export type Dialog = {
	show: (options: DialogOptions) -> Window,
	confirm: (message: string, onConfirm: () -> (), onCancel: (() -> ())?) -> Window,
}

export type Tooltip = {
	attach: (guiObject: GuiObject, text: string) -> () -> (),
}


type StaticFunctions = {
	getIcons: typeof(
		--[[
			Returns a dictionary of icons where the key is the icon's UID and value the icon.
		]]
		function(): { Icon }
			return (nil :: any) :: { Icon }
		end
	),
	getIcon: typeof(
		--[[
			Returns an icon of the given name or UID.
		]]
		function(nameOrUID: string): Icon?
			return nil :: any
		end
	),
	setTopbarEnabled: typeof(
		--[[
			When set to <code>false</code> all TopbarPlus ScreenGuis are hidden.
			This does not impact Roblox's Topbar.
		]]
		function(enabled: boolean)

		end
	),
	modifyBaseTheme: typeof(
		--[[
			Updates the appearance of all icons.
		]]
		function(modifications: { Modification })

		end
	),
	setDisplayOrder: typeof(
		--[[
			Sets the base DisplayOrder of all TopbarPlus ScreenGuis.
		]]
		function(order: number)

		end
	),
}

type Methods = {
	
	-- CLASS FUNCTIONS
	setName: typeof(
		--[[
			Sets the name of the Widget instance. This can be used in conjunction with <code>Icon.getIcon(name)</code>
		]]
		function(self: Icon, name: string): Icon
			return nil :: any
		end
	),
	getInstance: typeof(
		--[[
			Returns the first descendant found within the widget of name <code>instanceName</code>.
		]]
		function(self: Icon, instanceName: string): Instance?
			return (nil :: any) :: Instance?
		end
	),
	modifyTheme: typeof(
		--[[
			Updates the appearance of the icon.
		]]
		function(self: Icon, modifications: {Modification} | Modification): Icon
			return nil :: any
		end
	),
	modifyChildTheme: typeof(
		--[[
			Updates the appearance of all icons that are parented to this icon (for example when a menu or dropdown).
		]]
		function(self: Icon, modifications: { Modification }): Icon
			return nil :: any
		end
	),
	setEnabled: typeof(
		--[[
			When set to <code>false</code> the icon will be disabled and hidden.
		]]
		function(self: Icon, enabled: boolean): Icon
			return nil :: any
		end
	),
	select: typeof(
		--[[
			Selects the icon (as if it were clicked once).
		]]
		function(self: Icon): Icon
			return nil :: any
		end
	),
	deselect: typeof(
		--[[
			Deselects the icon (as if it were clicked, then clicked again).
		]]
		function(self: Icon): Icon
			return nil :: any
		end
	),
	notify: typeof(
		--[[
			Prompts a notice bubble which accumulates the further it is prompted.
			If the icon belongs to a dropdown or menu, then the notice will appear on the parent icon when the parent icon is deselected.
		]]
		function(self: Icon, clearNoticeEvent: Signal?): Icon
			return nil :: any
		end
	),
	clearNotices: typeof(
		--[[
			
		]]
		function(self: Icon): Icon
			return nil :: any
		end
	),
	disableOverlay: typeof(
		--[[
			When set to <code>true</code>, disables the shade effect which appears when the icon is pressed and released.
		]]
		function(self: Icon, disabled: boolean): Icon
			return nil :: any
		end
	),
	setImage: typeof(
		--[[
			Applies an image to the icon based on the given <code>imageId</code>. <code>imageId</code> can be an assetId or a complete asset string.
		]]
		function(self: Icon, imageId: string | number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setLabel: typeof(
		--[[
			
		]]
		function(self: Icon, text: string, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setOrder: typeof(
		--[[
			
		]]
		function(self: Icon, order: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setCornerRadius: typeof(
		--[[
			
		]]
		function(self: Icon, udim: UDim2, iconState: IconState?): Icon
			return nil :: any
		end
	),
	align: typeof(
		--[[
			This enables you to set the icon to the <code>"Left"</code> (default), <code>"Center"</code> or <code>"Right"</code> side of the screen.
		]]
		function(self: Icon, alignment: Alignment?): Icon
			return nil :: any
		end
	),
	setWidth: typeof(
		--[[
			This sets the minimum width the icon can be (it can be larger for instance when setting a long label). The default width is <code>44</code>.
		]]
		function(self: Icon, minimumSize: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setImageScale: typeof(
		--[[
			How large the image is relative to the icon. The default value is <code>0.5</code>.
		]]
		function(self: Icon, scale: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setImageRatio: typeof(
		--[[
			How stretched the image will appear. The default value is <code>1</code> (a perfect square).
		]]
		function(self: Icon, ratio: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setTextSize: typeof(
		--[[
			The size of the icon labels' text. The default value is <code>16</code>.
		]]
		function(self: Icon, textSize: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setTextColor: typeof(
		--[[
			The color of the icon labels' text
		]]
		function(self: Icon, color: Color3, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setTextFont: typeof(
		--[[
			Sets the labels FontFace.
			<code>font</code> can be a font family name (such as <code>"Creepster"</code>),
			a font enum (such as <code>Enum.Font.Bangers</code>),
			a font ID (such as <code>12187370928</code>),
			or font family link (such as <code>"rbxasset://fonts/families/Sarpanch.json"</code>).
		]]
		function(self: Icon, font: string | Enum.Font, fontWeight: Enum.FontWeight?, fontStyle: Enum.FontSize?, iconState: IconState?): Icon
			return nil :: any
		end
	),
	bindToggleItem: typeof(
		--[[
			Binds a GuiObject or LayerCollector to appear and disappeared when the icon is toggled.
		]]
		function(self: Icon, guiObjectOrLayerCollector: GuiObject | LayerCollector): Icon
			return nil :: any
		end
	),
	unbindToggleItem: typeof(
		--[[
			Unbinds the given GuiObject or LayerCollector from the toggle.
		]]
		function(self: Icon, guiObjectOrLayerCollector: GuiObject | LayerCollector): Icon
			return nil :: any
		end
	),
	bindEvent: typeof(
		--[[
			Connects to an icon event with <code>iconEventName</code>.
			It's important to remember all event names are in <code>camelCase</code>.
			<code>callback</code> is called with arguments <code>(self, ...)</code> when the event is triggered.
		]]
		function(self: Icon, event: Events, callback: (...any) -> ()): Icon
			return nil :: any
		end
	),
	unbindEvent: typeof(
		--[[
			Unbinds the connection of the associated <code>iconEventName</code>.
		]]
		function(self: Icon, event: Events): Icon
			return nil :: any
		end
	),
	bindToggleKey: typeof(
		--[[
			Binds a keycode which toggles the icon when pressed.
		]]
		function(self: Icon, keycode: Enum.KeyCode): Icon
			return nil :: any
		end
	),
	unbindToggleKey: typeof(
		--[[
			Unbinds the given keycode.
		]]
		function(self: Icon, keycode: Enum.KeyCode): Icon
			return nil :: any
		end
	),
	call: typeof(
		--[[
			Calls the function immediately via <code>task.spawn</code>.
			The first argument passed is the icon itself.
			This is useful when needing to extend the behaviour of an icon while remaining in the chain.
		]]
		function(self: Icon, func: (self: Icon) -> (...any), ...: any): Icon
			return nil :: any
		end
	),
	addToJanitor: typeof(
		--[[
			Passes the given userdata to the icons janitor to be destroyed/disconnected on the icons destruction.
			If a function is passed, it will be called when the icon is destroyed.
		]]
		function(self: Icon, userdata: unknown): Icon
			return nil :: any
		end
	),
	lock: typeof(
		--[[
			Prevents the icon being toggled by user-input (such as clicking), however, the icon can still be toggled via localscript using methods such as <code>icon:select()</code>.
		]]
		function(self: Icon): Icon
			return nil :: any
		end
	),
	unlock: typeof(
		--[[
			Re-enables user-input to toggle the icon again.
		]]
		function(self: Icon): Icon
			return nil :: any
		end
	),
	debounce: typeof(
		--[[
			Locks the icon, yields for the given time, then unlocks the icon, effectively shorthand for <code>icon:lock() task.wait(seconds) icon:unlock()</code>.
			This is useful for applying cooldowns (to prevent an icon from being pressed again) after an icon has been selected or deselected.
		]]
		function(self: Icon, seconds: number): Icon
			return nil :: any
		end
	),
	autoDeselect: typeof(
		--[[
			When set to <code>true</code> (the default) the icon is deselected when another icon (with autoDeselect enabled) is pressed.
			Set to <code>false</code> to prevent the icon being deselected when another icon is selected (a useful behaviour in dropdowns).
		]]
		function(self: Icon, enabled: boolean?): Icon
			return nil :: any
		end
	),
	oneClick: typeof(
		--[[
			When set to true the icon will automatically deselect when selected.
			This creates the effect of a single click button.
		]]
		function(self: Icon, enabled: boolean?): Icon
			return nil :: any
		end
	),
	setCaption: typeof(
		--[[
			Sets a caption. To remove, pass <code>nil</code> as <code>text</code>.
		]]
		function(self: Icon, text: string?): Icon
			return nil :: any
		end
	),
	setCaptionHint: typeof(
		--[[
			This customizes the appearance of the caption's hint without having to use <code>icon:bindToggleKey</code>.
		]]
		function(self: Icon, keyCode: Enum.KeyCode): Icon
			return nil :: any
		end
	),
	setDropdown: typeof(
		--[[
			Creates a vertical dropdown based upon the given table array of icons.
			Pass an empty table <code>{}</code> to remove the dropdown.
		]]
		function(self: Icon, icons: { Icon }): Icon
			return nil :: any
		end
	),
	joinDropdown: typeof(
		--[[
			Joins the dropdown of <code>parentIcon</code>.
			This is what <code>icon:setDropdown</code> calls internally on the icons within its array.
		]]
		function(self: Icon, parent: Icon): Icon
			return nil :: any
		end
	),
	setMenu: typeof(
		--[[
			Creates a horizontal menu based upon the given array of icons.
			Pass an empty table <code>{}</code> to remove the menu.
		]]
		function(self: Icon, icons: { Icon }): Icon
			return nil :: any
		end
	),
	setFixedMenu: typeof(
		--[[
			Creates a menu that is always selected and has it's close button hidden.
			Pass an empty table <code>{}</code> to remove the menu.
		]]
		function(self: Icon, icons: { Icon }): Icon
			return nil :: any
		end
	),
	joinMenu: typeof(
		--[[
			Joins the menu of <code>parentIcon</code>.
			This is what <code>icon:setMenu</code> calls internally on the icons within its array.
		]]
		function(self: Icon, parentIcon: Icon): Icon
			return nil :: any
		end
	),
	leave: typeof(
		--[[
			Unparents an icon from a parentIcon if it belongs to a dropdown or menu.
		]]
		function(self: Icon): Icon
			return nil :: any
		end
	),
	convertLabelToNumberSpinner: typeof(
		--[[
			Unparents an icon from a parentIcon if it belongs to a dropdown or menu.
		]]
		function(self: Icon, numberSpinner: any, func: (...any) -> (...any), ...: any): Icon
			return nil :: any
		end
	),
	setWindow: typeof(
		--[[
			Creates a Window, binds it to this icon (the shop-button pattern), and returns
			the Window so you can populate it. Pass a config table to set title/size/etc.
			Prefer this over Material.Window.new() when the window belongs to an icon.
		]]
		function(self: Icon, config: WindowConfig?): Window
			return (nil :: any) :: Window
		end
	),
	getWindow: typeof(
		--[[
			Returns the Window bound to this icon (via setWindow or bindWindow), or nil.
		]]
		function(self: Icon): Window?
			return (nil :: any) :: Window?
		end
	),
	bindWindow: typeof(
		--[[
			Binds an existing Window to this icon: selecting the icon opens the window,
			deselecting closes it, and closing the window deselects the icon.
		]]
		function(self: Icon, window: Window): Icon
			return nil :: any
		end
	),
	destroy: typeof(
		--[[
			Clears all connections and destroys all instances associated with the icon.
		]]
		function(self: Icon): Icon
			return nil :: any
		end
	),
} & StaticFunctions

type Fields = {
	-- CLASS PROPERTIES
	name: string,
	isSelected: boolean,
	isEnabled: boolean,
	totalNotices: number,
	locked: boolean,

	-- CLASS EVENTS
	selected: Signal<EventSource>,
	deselected: Signal<EventSource>,
	toggled: Signal<boolean, EventSource>,
	viewingStarted: Signal,
	viewingEnded: Signal,
	notified: Signal,
}

export type Icon = Methods & StaticFunctions --typeof(setmetatable({} :: Fields, MT))

export type StaticIcon = {
	new: typeof(
		--[[
			Constructs an empty <code>32x32</code> icon on the topbar.
		]]
		function(): Icon
			return (nil :: any) :: Icon
		end
	),
	-- Material's window + overlay subsystem (emulator layer)
	Window: StaticWindow,
	WindowController: WindowController,
	Dock: Dock,
	Toast: Toast,
	Dialog: Dialog,
	Tooltip: Tooltip,
} & StaticFunctions

return {}