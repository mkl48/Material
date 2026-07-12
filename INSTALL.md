# Installation

Material installs exactly like TopbarPlus, and your existing TopbarPlus code
runs against it unchanged — only the module name differs.

## Command bar (no toolchain)

Paste this snippet into the Studio command bar. It fetches the full installer
over HTTP (enable *Game Settings → Security → Allow HTTP Requests*) and
recreates the whole tree under `ReplicatedStorage.Material`:

```lua
local h = game:GetService("HttpService")
loadstring(h:GetAsync("https://raw.githubusercontent.com/mkl48/Material/master/dist/install.luau"))()
```

Offline, paste the whole `dist/install.luau` from the repo instead. Both
replace any existing `ReplicatedStorage.Material` (with a warning).

## Rojo

Clone the repo and sync `default.project.json`; `src/` maps to a single
`Material` ModuleScript.

## First icon

```lua from a LocalScript
local Icon = require(game.ReplicatedStorage.Material)

Icon.new()
	:setImage(14723463500)
	:setLabel("Shop")
	:setCaption("Open the shop")
```

Migrating from TopbarPlus is a one-line change: point your `require` at
`ReplicatedStorage.Material` instead of the TopbarPlus module. Everything on
[[Icon]] behaves identically.
