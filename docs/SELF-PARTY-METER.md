# Holy Light × Eclipse – SELF / PARTY meter (0.9.6-preview)

This preview extends the **existing** gold/violet meter; it does not redesign the main HUD or replace the stable 0.9.5 release.

## Controls

- The meter now has **SELF / PARTY** above the existing **RUN / BOSS / HEAL** tabs.
- Click either row to switch views. The saved scope and mode persist with the addon settings and layout profiles.
- Chat commands: `/hle meter self`, `/hle meter party`, `/hle meter run`, `/hle meter boss`, `/hle meter heal`.
- `/hle meter rows 10` and `/hle meter width 340` still control the meter layout. Existing drag behavior remains.
- The footer grows slightly to fit the additional switch, without moving or recoloring the other HUD components.

## Data truthfulness

On clients offering the official version-one meter snapshot API (`AZS_GetMeterCapabilities`, `AZS_GetMeterContext`, `AZS_GetMeterSnapshot`):

| Scope | RUN | BOSS | HEAL |
|---|---|---|---|
| SELF | Damage by source | Boss damage by source (current/last encounter) | Healing **performed** by source |
| PARTY | Damage by hero | Boss damage by hero | Healing **performed** by hero |

Snapshots are keyed to the current `runId` and require `complete=true` and a matching snapshot context. The view is refreshed at most every 0.25 seconds when the game clock is available.

On older clients, SELF uses existing `AZS_GetMeter`, `AZS_GetBossMeter`, `AZS_GetHealing` values; PARTY / RUN uses `AZS_GetPartyMeter`. PARTY / BOSS and PARTY / HEAL explicitly display unavailable rather than fabricating data.

The total is the game's meter total and is **not** obtained by summing already grouped rows. The meter uses the API's native actor and source names. If no real party data exists, it says so.

## Verification

The CI preview workflow validates all Lua files with Lua 5.1 syntax checking and runs `Tests/meter_scope.lua`, covering the six modern views, caching and legacy fallback. The actual Azeroth Survivors client uses its own Lua 5.0 subset and is **not** represented by this test runner.

**Still requires in-game checks:** switching scopes while a party is alive, boss encounter start/end, healing perspectives in co-op, saving and loading a layout profile, resizing/paging the meter, and correct display after a new run or reload.

## Scope

The bag/inventory window has not been modified. It remains a separate visual proposal requiring approval, as agreed. Boss alerts and the end-of-run summary remain future tasks.
