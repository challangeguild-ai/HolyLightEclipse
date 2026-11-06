# Holy Light × Eclipse — 0.9.11-preview

This is a **test build** for **Azeroth Survivors / WoW 1.12.1**. It preserves the existing gold/violet HUD, the HC and co-op features from 0.9.10, and the user's saved panel positions. It does not replace the stable main branch.

## First-time setup — no setup required

1. Close the game. Back up the existing `Interface/AddOns/HolyLightEclipse` directory.
2. Extract the ZIP and replace the older addon directory with the enclosed `HolyLightEclipse` directory.
3. Start the game. Look for the small purple/gold **H** beside the minimap. **Left click** to open settings; click again to close.
4. Use the three tabs: **Appearance**, **Alerts**, **Profiles**.
5. Ignore **More settings** if you don't need fine-tuning. It is closed by default.

## Minimap H icon

- Left-click: open/close settings.
- Shift + left-drag: move the icon. Its location is remembered.
- The icon is independent of the custom minimap border; hiding that border does not remove the icon.
- Advanced Appearance can hide the launcher; type `/hle launcher` to bring it back. `/hle settings` works even if the icon is hidden.
- Disabling the main HUD does not remove access to the settings icon.

## Three-page settings

**Appearance:** Damage meter, Equipment, Party frames, Boss timeline, simple small/normal/large size presets, plus direct language selection. Advanced options include loot, effects/timers, navigation, jewelry diary, minimap skin, bag skin, nameplates and minimap launcher.

**Alerts:** Verified damage warning, boss arrival, downed teammate guidance, warning sound, and 20–40% low-HP threshold. Advanced controls include repeat interval (6–16 seconds), game banner muting, ready ability cues, run summary, white/yellow damage numbers and healing numbers.

**Profiles:** Three independent saved layouts, with Save/Load and an editable name (click Rename, type a name, press Enter). Includes Move/Lock and two-click confirmation for resetting panel positions. Saving and loading carries panel coordinates, collapse states and HUD preferences, not game character data.

The scale controls do not clear saved panel coordinates. No panel reflows into another panel's location. Collapsing and expanding are controlled on each relevant panel itself.

## Languages

- **English** is the default regardless of game client language.
- Optional **Magyar**, **Deutsch**, and **简体中文** (Simplified Chinese) are selected under Appearance.
- The new settings center, commonly used HUD captions, compact headers, and threat/boss-warning messages are translated. Existing game-provided names (zones, bosses, items, abilities) retain the original game's locale. Some older specialized tooltips and secondary screens still contain English strings pending a separate full localization pass.
- Chinese glyph rendering depends on the installed 1.12 client's CJK-compatible game font. The addon does **not** ship or redistribute font files; if the font is unavailable, the UI may fall back to English for affected labels.

## Combat safeguards from 0.9.10

The threat assistant never invents a boss cast or affix mechanic. It warns on **verified local HP events only**: crossing the chosen critical-HP threshold or a measured single large hit. The large-hit warning explicitly states that damage was already received, not incoming. Boss arrival events are prioritized behind urgent danger notices and shown afterwards. It can be muted separately, and each event is deduplicated.

The co-op downed-state run timer, boss timeline and boss-HP continuity, collapsible panel headers, compact boss bars, HC level/affixes and white/yellow combat text from previous previews remain in place.

## Advanced slash commands

- `/hle settings` — open settings even without the icon
- `/hle launcher` — toggle the minimap launcher
- `/hle lang en`, `/hle lang hu`, `/hle lang de`, `/hle lang zhCN` — change UI language
- `/hle unlock` / `/hle lock` — move/lock HUD panels
- `/hle scale 0.85` — resize without discarding positions
- `/hle threats`, `/hle threatsound`, `/hle bossalerts` — danger and boss warning controls
- `/hle profile save 1` / `/hle profile load 1` — profile management
- `/hle status` — diagnostic information

## Known limitations and testing status

The **Marks currency balance** is not shown because no documented read API has been confirmed. Boss targeting by clicking the short boss bar remains best-effort name targeting, not spawn-ID targeting. Accurate predictive boss/affix spell warnings remain unavailable from the documented API; the addon will not manufacture them.

CI runs Lua 5.1 syntax checks and tests for meter scopes, original UI panels, co-op rescue, HC death lifecycle, confirmed dangers, settings/language/profile state and minimap launcher. Real client testing, including Chinese-glyph support, mouse interaction and minimap/icon placement, is still needed before marking this version stable.
