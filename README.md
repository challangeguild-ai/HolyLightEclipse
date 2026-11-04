# Holy Light × Eclipse — 0.8.3

A gold-and-violet HUD for Azeroth Survivors, built around clear combat information and a compact action bar.

**Maintainer:** Rehard  
**Category:** HUD & interface  
**Version:** 0.8.3  
**Settings:** `/hle`  
**Addon folder:** `HolyLightEclipse`  
**Interface declaration:** `11200`

## Download

[Download HolyLightEclipse-0.8.3.zip](https://github.com/challangeguild-ai/HolyLightEclipse/raw/refs/heads/main/downloads/HolyLightEclipse-0.8.3.zip)

[Magyar bemutató](docs/ADDON-PAGE-HU.md) · [SHA-256](downloads/SHA256SUMS.txt)

## What does it do?

Holy Light × Eclipse brings player and target frames, ability cooldowns, run statistics, loot notifications and guardian tracking into one consistent interface. Its paladin-inspired artwork uses gold borders and violet accents, while keeping the centre of the battlefield open.

The player frame stays in place when you acquire or clear a target. The target panel disappears when there is no target, and the small central emblem stays visible.

## Features

- Player health, power, XP and supported absorb information; target health and level.
- Compact ability icons and cooldown numbers, using the current run's published ability data. New runs clear the previous run's ability display.
- Player buffs/debuffs above the player frame and target auras above the target frame. Supported summon lifetimes and talent/item timers appear with player effects.
- Run clock, next-boss information, kills, collected gold and the next cache price.
- A small draggable meter with RUN, BOSS and HEAL views, using the game's reported damage and healing values.
- Custom enemy nameplates with health percentages and native level information where available.
- An equipment panel with native item tooltips and separately labelled run-wide statistics.
- An elite/guardian window above equipment. It reads names from the current map's lair data, lists their state and shows the game's reported respawn times. There are no navigation arrows or cache markers in this window.
- Current-run jewelry and a local diary of actually observed items, with up to 200 entries.
- Loot notification cards styled to match the HUD.
- A settings window, movable supported panels, scaling and three saved layout profiles.

## Installation

Download the packaged **HolyLightEclipse-0.8.3.zip** release.

For desktop play, use the game's **Open AddOns Folder** option if available to find the correct folder. Close the game, then extract the `HolyLightEclipse` folder there. In an Interface-based setup the path is:

`Interface/AddOns/HolyLightEclipse/HolyLightEclipse.toc`

The `.toc` must be directly inside `HolyLightEclipse`, without another nested addon folder. Replace the existing addon folder when updating and restart the client. Keep other full HUD replacements disabled while using this addon.

The game's browser ZIP installer is described in the community installation guide, but **this release has not been verified in the browser**. Desktop testing does not establish browser support.

## Getting started

Open `/hle` for settings. Use `/hle unlock` to move supported panels and `/hle lock` when finished. The meter remains draggable while locked. The elite/guardian window follows the equipment panel; aura rows follow their unit frames.

Useful commands:

- `/hle meter run`, `/hle meter boss`, `/hle meter heal`
- `/hle navigation` — toggle the elite/guardian list
- `/hle journal` — toggle the jewelry/observed-item panel
- `/hle reset` — reset panel positions and global scale
- `/hle off` — disable the custom HUD and restore owned native elements
- `/hle status` — show diagnostic information

## Compatibility and limits

The HUD was developed and iterated with player-supplied in-game screenshots. On 4 November 2026, the player reported that version 0.8.3 appeared to work correctly in their setup. Automated checks cover file structure, XML, texture properties and simulated Lua/API behaviour. This is a user-reported gameplay check, **not independent certification or a test of every feature, class or platform**. The exact game build was not recorded.

The design and recent gameplay feedback focus on Paladin. Other classes depend on the native spellbook/action/loadout icon data; the addon includes a small Paladin/racial icon fallback rather than a full all-class catalogue.

Optional displays depend on available APIs. Unknown timers are not invented. The elite list covers the game's published guardian/lair entries, not every roaming elite. Jewelry metadata without a native item link does not provide fabricated per-item stats. Classic target auras may have no duration data. The native level-up selection cards are not reskinned.

This is an independent community addon. It is not an official Blizzard or Azeroth Survivors product.

