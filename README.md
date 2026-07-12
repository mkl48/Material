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

Material is a fork of [TopbarPlus](https://github.com/1ForeverHD/TopbarPlus) by
ForeverHD (vendored at v3.4.0, commit `f44992b`) — every existing TopbarPlus icon
runs unchanged — that adds small icon elements built the TopbarPlus way (each a
`function(icon)` element attached to the icon and driven by its theme): a click
**ripple**, attention **motion** (`pulse` / `bounce` / `wobble`), a **cooldown /
progress** indicator, a status **pip**, and a **shine** sweep.

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
