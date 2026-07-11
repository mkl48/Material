# Material — design notes

**Pitch (decided 2026-07-11):** a **fork of TopbarPlus v3** — keep the proven
core, fix the bugs and weirdness, expand and upgrade the API. Better =
native-chrome fidelity + API ergonomics + performance + real theming, with the
native look as the default. Full MVP surface: icons/toggles, notices, captions,
menus + dropdowns (it's a fork; we inherit all of it).

## Audit of TopbarPlus v3 (2026-07-11, source + issue tracker)

**Shape:** ~5.5K lines. `init.lua` = the Icon class (1249 lines, ~55 public
methods), `Elements/` (Widget, Selection, Notice, Menu, Dropdown, Container,
Caption, Indicator), `Features/` (Overflow, Gamepad, Themes), vendored Janitor
+ GoodSignal. Last pushed 2025-09.

**License: MPL 2.0 + credit rider** (keep the Attribute, or credit TopbarPlus
in the experience description/devforum). Fork is fine, but modified files stay
MPL with source available — Material cannot be MIT while it contains TopbarPlus
code. Keep LICENSE, keep per-file notices, credit in README.

**Weirdness / bug classes found:**

1. **Timing-hack culture.** Magic numbers everywhere: `task.delay(0.2)`,
   `task.delay(i/100)`, `task.wait(0.05)`, `task.wait(1)` through Widget and
   init. This is the root of the visual-glitch bug family: long labels stick
   (#197), text jumps in from the corner on instantiation (#100), deletion
   animation jank (#101). Fix: state-driven layout (property changes settle in
   one pass; tween completion by signal, not stopwatch).
2. **Stringly theme system.** Themes are positional arrays
   `{instanceName, property, value, state?}`; unknown properties silently
   become attributes; "collectives" are attribute-tagged instance groups.
   Powerful but undiscoverable and typo-silent. Fix: keyed, typed theme tables
   (semantic groups like Karet), compat shim for old arrays.
3. **~55 imperative setters** on Icon (`setImage`, `setLabel`, `setWidth`,
   `setTextFont`, …), each `(value, iconState?)`. Fix: declarative
   `Material.Icon{ image=…, label=…, states={…} }` one-call construction with
   the old chain API kept as a compat layer.
4. **Signal/cleanup smells:** possible memory leak in the Signal class (#194),
   auto-deletion improvements needed (#188), double init inside Actors (#99).
5. **Open bug backlog worth inheriting-and-fixing:** console/ten-foot UI
   (#222, #220, #158, #171, #174 gamepad family), caption error via
   `Utility.clipOutside` (#203), captions not native enough (#193), dropdowns
   don't close on outside click (#169), overflow center-align bug (#113),
   health-bar overlap (#138), Reduce Motion not respected (#167), packages
   vendored instead of wally (#102).

## Decided

- Fork base: TopbarPlus **v3.4.0**, upstream commit `f44992b`, vendored into
  `src/` (MPL 2.0 kept, credit kept, README credits ForeverHD)
- **API: drop-in compatible.** The TopbarPlus surface (`Icon.new():setImage()…`)
  stays THE API; "upgrading the API" means additive methods and options, never
  breaking existing TopbarPlus code
- Repo: fresh `Material` repo with vendored source (not a GitHub fork)
- Milestone 1: bugfixes + additive API upgrades together
- Default look: native chrome; semantic themes opt-in
- Better-priorities: fidelity, ergonomics, performance, theming (all four)

One more find while vendoring: `VERSION.lua` phones home via
MarketplaceService:GetProductInfo in an **infinite retry loop** to compare
against the latest release. Remove in Material (weirdness #6).

## To decide (next design session)

- Surgery order for milestone 1: which bug family first (timing-hack layout
  fixes vs. cleanup/memory vs. gamepad/console vs. captions/dropdowns)?
- What the first *additive* API upgrades are (declarative config-table
  constructor sugar? typed Luau signatures? theme keying?)
- Testing story: TopbarPlus has no test suite — what's verifiable headless
  (theme resolution, state machine) vs. Studio-only (rendering, input)?
- When to publish the GitHub repo (name it public like the others?)
