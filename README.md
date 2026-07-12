<div align="center">

# Material

**A Roblox in-game UI framework. TopbarPlus icons, plus windows, dialogs, and more.**

<img src="https://img.shields.io/badge/Material-v0.0.0-e6ab4c?style=for-the-badge" alt="version" />
<img src="https://img.shields.io/badge/Luau-Roblox-00A2FF?style=for-the-badge" alt="luau" />
<img src="https://img.shields.io/badge/License-MPL%202.0-c05b4d?style=for-the-badge" alt="license" />
<img src="https://img.shields.io/badge/Fork%20of-TopbarPlus%20v3.4.0-1abc9c?style=for-the-badge" alt="fork" />

**[Read the docs](https://mkl48.github.io/Material/)** · drop-in compatible with TopbarPlus

</div>

---

Material starts as a fork of [TopbarPlus](https://github.com/1ForeverHD/TopbarPlus)
by ForeverHD (vendored at v3.4.0, commit `f44992b`) — every existing TopbarPlus
icon runs unchanged — and grows outward into a small in-experience UI framework
that emulates Roblox's own core UI:

- **Icons** — the full TopbarPlus surface, with the timing-hack layout bugs and
  the update phone-home on the fix list.
- **Windows** — a titled panel that drops from an icon and opens when the icon is
  selected, exactly like a dropdown (`icon:setWindow{ title = "Shop" }`). Built
  as a TopbarPlus element and themed through the icon, so it matches the topbar.
  Fill it with `:addToWindow(gui)` or, like a dropdown/menu, with `:addIcon(icon)`.
- **Overlays** — `Toast` snackbars, modal `Dialog`s (buttons are real icons), and
  rich `Tooltip`s for any GuiObject.

Everything reuses TopbarPlus's theme (panel colour `18,18,21`, BuilderSans, the
shared shadow), so the panels read as part of the same topbar — not a separate UI.

> **Status: pre-release, Studio-verified only.** The Icon layer is the vendored
> upstream baseline; the window/overlay layer is new and needs real Studio
> testing. See [NOTES.md](NOTES.md) for the audit and plan.

## Installation

### Command bar (no toolchain)

Paste this one snippet into the Studio command bar; it fetches and runs the full
installer over HTTP (enable *Game Settings → Security → Allow HTTP Requests*)
and recreates the whole tree under `ReplicatedStorage.Material`:

```lua
local h = game:GetService("HttpService")
loadstring(h:GetAsync("https://raw.githubusercontent.com/mkl48/Material/master/dist/install.luau"))()
```

([`dist/bootstrap.luau`](dist/bootstrap.luau) is the same with error handling.)
Or, offline, paste the whole [`dist/install.luau`](dist/install.luau) directly.
Regenerate it from source any time with:

```sh
lune run scripts/build-installer
```

### Rojo

Clone the repo and sync `default.project.json`; the `src/` tree maps to one
`Material` ModuleScript.

### Usage

Identical to TopbarPlus — only the module name differs:

```lua
local Icon = require(game.ReplicatedStorage.Material)

Icon.new()
	:setImage(14723463500)
	:setLabel("Shop")
	:setCaption("Open the shop")
```

## Credit & license

TopbarPlus is by **ForeverHD** and contributors. Material keeps the upstream
[MPL 2.0 license and credit notice](LICENSE); if you use Material in an
experience, credit TopbarPlus per that notice (a line in your experience
description is enough).
