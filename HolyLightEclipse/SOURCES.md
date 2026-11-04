# Források és ellenőrzési alap

Ellenőrzés dátuma: 2026-11-03. A hivatkozott források nem garantálják a kiadott addon futását; élő klienspróba nem történt.

- https://azerothsurvivorsgame.com/addons/ — a felhasználó által megadott **nem hivatalos** útmutató; telepítés, interface és az AZS-specifikus API nyomai. A felsorolt addonokat maga az oldal is teszteletlennek jelzi az általa tárgyalt aktuális verzión.
- https://wow.aethus.pl/ — a játék oldala; a webes lekérés nem adott közvetlenül olvasható teljes API-forrást. Nem állítjuk, hogy a futó kliens implementációját auditáltuk.
- https://github.com/HejAsh/azeroth-survivors-addon-skill/tree/aa05d9f600a8e622fe91e0a4c8b2553ffc33e3b8 — letöltött közösségi API-referencia. Olvasott fájlok: `azeroth-survivors-addon/references/api.md`, `references/client-api.md`. Mezők, fázisok, cooldown, meter visszatérési sorrend, guardian-korlátok, Lua 5.0 szintaxis és widgetfelület ellenőrzése. E tárolót dokumentációként használtuk, nem telepített agent skillként.
- https://github.com/nfmous/nfui_AZSRV/tree/061a696c1ed62aa4263df49d4baa9643b4364f5b — megvizsgált AZS-addonminta: `nfUI/nfUI.lua` unit frame és `UnitMana` használat, `nfUI/Combat/CombatText.lua` spellbook-index alapú textúrakeresés. Nem tévesztjük össze a spell ID-t a spellbook indexével.
- https://github.com/migwynkriid13/SurvivorsDragonUi/tree/1ca877cb9eb27763d0a98ad71b8c7ace598d911a — README: natív HUD-részek, bossok, guardians, böngészős/asztali telepítés; a letöltött forrásban spell API használatot is kerestünk. Más addon belső globális változóira nem építünk.

A Lua-kód és a geometrikus TGA-textúrák ehhez a csomaghoz készültek. A közösségi addonok kódját vagy grafikai fájljait nem csomagoltuk át. A `Tests/mock.lua` tesztsegéd, nem része a játék által betöltött fájllistának.

0.2.0 kiegészítés: a helyben letöltött SurvivorsDragonUi `modules/bars/bars.lua` mintájában a hét natív akcióslot, `GetActionCooldown(slot)` → `start, duration, enabled`, valamint `GetTime()` alapú maradékidő-számítás vizsgálata történt. Az nfUI `HUD/NativeHUD.lua` fájlja szolgált összehasonlításul a `AZS_IsHudShown`/`AZS_SetHudShown` állapot megőrzésére és visszaállítására. A megoldás saját implementáció, nem importálja e kódokat. A felhasználó 2026-11-03-i képernyőképe a 0.1.1 run-adatainak működését mutatja; nem bizonyítja a 0.2.0 új funkcióinak működését.


0.3.0: a felhasználó új képernyőképe `ready` fázisban mutatta a hiányzó saját actionbart. A javítás a natív ikonolvasást a fáziskapu elé helyezi; stale run-spell táblát továbbra sem használ. A második csatolt kép vizuális referencia: arany/lila díszkeretek, kétoldali portrék, középső címer és képességsáv. A csomag öt új textúrája saját geometrikus grafika; a referencia kép pixeleit és játékbeli illusztrációit nem másolja. A 0.3.0 változtatásai szimulált tesztben ellenőrzöttek, élő kliensben még nem.


0.5.0: a korábban letöltött, fent rögzített SurvivorsDragonUi commit `modules/bars/bars.lua` eleje explicit natív kiosztást használ: `1, 2, 3, 4, 5, 6, 12`. A hetedik megjelenített gomb a natív 12-es slot. A `docs/AzerothSurvivors-Addon-API.md` a racial képességet az `AZS_SPELLS` lista végén dokumentálja. Az addon saját implementációval egy friss listára szűkíti a megjelenítést és mozgatja/állítja vissza a natív gombkereteket. A felhasználó 2026-11-03-i képernyőképe megmutatta a korábbi megoldás futamok közötti ikonmaradványait; a 0.5.0 új logikáját szimulációban ellenőriztük, nem élő kliensben.


0.6.0: a helyben rögzített nfUI `HUD/Plates.lua` nameplate-felismerése szolgált API-ellenőrzésre: a WorldFrame natív gyermekei, `Nameplate-Border` textúra, natív StatusBar és FontString. Az új skin saját implementáció, nem importálja az nfUI szín-/névlistáit vagy pozicionáló kódját. A rögzített SurvivorsDragonUi `docs/EQUIPPED-JEWELRY.md` dokumentálja az öt normál inventory slotot, a natív `GetInventoryItemTexture` és `SetInventoryItem` olvasást, valamint a normál felszerelés és run-jewelry különbségét. A natív tooltip teljes leírását használjuk, az ott leírt formattert és grafikát nem importáljuk. Az nfUI `Core/StatModel.lua` ellenőrzési minta a dokumentált `dmg - 1`, `crit`, `arm` százalékformázására; ezt összesített run-statként, nem tárgyanként jelenítjük meg.


0.7.0 / 2026-11-04: megvizsgált KeijinUI commit `6cad51c3aeff5ba16b4bef0dc507345e74f209aa`, https://github.com/KeijinDE/KeijinUI_modern-as-ui/tree/6cad51c3aeff5ba16b4bef0dc507345e74f209aa . Olvasott működési minták: `KeijinUI/BossTimes.lua` (runkezdet, friss unit-táblák), `Core.lua` (közölt óra, visszakorrekció tolerálása), `modules/KeijinBuildBar.lua` (nem héthez kötött képességlista, spellbook), `Loot.lua` (saját loot-chat, item-referencia és natív metaadat), `Collection.lua` (megfigyelt tárgyak naplója). A szerző `screenshots/overview.jpg` képét helyben megtekintettük. A bevezetett kód és a HUD grafikája saját maradt.

Az opcionális `AZS_GetMeterContext` / `AZS_GetMeterLoadout` hívási aritása, a context fázisa/órája, a complete loadout, a source icon és a passzív képességek mezői a korábban rögzített SurvivorsDragonUi `docs/AzerothSurvivors-Addon-API.md` és `docs/DAMAGE-METER-AND-INSTANCE-PLAYER-POSITION-API.md` referenciájából ellenőrzöttek. A loader hiányzó API esetén a régi `AZS_SPELLS` útvonalat használja. A `GetItemInfo` kilencedik ikon-visszatérési helyét a `docs/LOOT-NOTIFICATIONS.md` natív szerződése és a Keijin natív olvasása is alátámasztja. A szerzők élő tesztállításai nem helyettesítik a saját klienspróbát.


## 0.8.0 forrásvizsgálat és saját megvalósítás

- KeijinUI commit `6cad51c3aeff5ba16b4bef0dc507345e74f209aa`: [BuildBar](https://github.com/KeijinDE/KeijinUI_modern-as-ui/blob/6cad51c3aeff5ba16b4bef0dc507345e74f209aa/KeijinUI/modules/KeijinBuildBar.lua), [Icons adatforrás](https://github.com/KeijinDE/KeijinUI_modern-as-ui/blob/6cad51c3aeff5ba16b4bef0dc507345e74f209aa/KeijinUI/modules/Icons.lua). Tizenkét paladin/racial kulcs–natív textúranév párt tényszerű metaadatként ellenőriztünk; saját kisméretű tartalék táblába kerültek. A teljes katalógust, fordításokat, programkódot és grafikai fájlokat nem emeltük át.
- A helyi `work/dragon-reference/docs/AzerothSurvivors-Addon-API.md` dokumentált AZS_GetDebuffs, AZS_GetHealing, AZS_GetBossMeter, AZS_GetTimers, AZS_GetSummons, AZS_GetPlayerPosition, AZS_GetLairs és MeterLoadout runJewelry szerződése szolgált a saját modulok adatforrásául. [API elsődleges projektforrás](https://github.com/migwynkriid13/SurvivorsDragonUi/blob/1ca877cb9eb27763d0a98ad71b8c7ace598d911a/docs/AzerothSurvivors-Addon-API.md). Ez a projektben megőrzött API-leírás, nem élő kliensverifikáció.
- Saját modulok: Tracking.lua és Extras.lua. A HUD színei, keretei és alapelrendezése saját korábbi anyag maradt.
- Forrásböngészés nem egyenlő működési igazolással; a 0.8.0 ellenőrzési jelentése külön rögzíti a szimuláció korlátait.

## 0.9.0: party, schedule, minimap

A meglévő API-referencia AZS_SCHEDULE {index,at,name,final,state} szerződése és AZSBOSSES publikációja adja a boss-idővonalat. A party a natív GetNumPartyMembers és party1…party4 Unit* gettereket olvassa, a revive az AZS_GetRevive adata. A KeijinUI Party.lua forrása összehasonlításul szolgált az API-használat ellenőrzésére; kódot nem másoltunk át. A játék lobbyjának maximális létszámát a más forkokról szóló webes találatokból nem vettük át tényként.

GroupMap.lua és Timeline.lua saját modulok. A TimelineSwords.tga, TimelineSkull.tga és MinimapRim.tga saját geometrikus RGBA textúrák, nem más addonból átvett képek. A 0.9.0 nem élő kliensben ellenőrzött kiadás.

## 0.9.1 javítások

A felhasználó 0.9.0 kliensfotója alapján a party háttér, minimapmaradványok, későn látszó menetrend, targetaurák és tükrözött target elrendezés lett javítva. A helyi API-referencia localClock HUD-partja adja a minimap óraátvételét; a natív party/buff/minimap kontrollokat csak saját helyettesítő mellett, visszaállíthatóan rejtjük. A menetrend-cache csak korábban megfigyelt tényadat, nem a Keijin adatbázisa és nem hiteles aktuális győzelmi állapot. A tükrözött TargetPanel091 saját UnitPanel04 grafikánk vízszintes tükrözése. A 0.9.1 szimulált, nem élő kliensben ellenőrzött.

## 0.9.2: egységes felső panel

A felhasználó 0.9.1 képe alapján a különálló idővonal-doboz megszűnt. A közös háttér, peremek és saját PanelCorner092 geometrikus dísz közvetlenül a HLEEncounter keret részei. A header és timeline nem két egymás alá tett ablak. A minimap saját vezérlőinek elhelyezése a natív map határain belülre került. Új játékadatot és külső kódot ez a változás nem vezet be.


## 0.9.3: HP-panelek és combat text

A felhasználó 0.9.2 játékfotójára épülő saját átrendezés: az elitek HP-ja az AZS_LAIRS.id ↔ AZS_GetGuardians().id pontos kapcsolaton a táborlistában, a boss HP külön a felső panel alatt. A dokumentált empty állapot önmagában nem bizonyít korábbi ölést. A saját TimeBadge093.tga egyszerű geometrikus óralap.

A saját CombatText.lua a fent hivatkozott projekt API-dokumentációjának world-anchored combat-text v1 szerződését használja (AZS_GetCombatTextEvents, AZS_ProjectCombatTextAnchors, frame-handler), nem más addon rendererének átvétele. A natív CombatDamage opció a dokumentáció szerint független a kimenő események olvasásától. Az AZS_GetHealing összegéből saját, publikációnkénti kapott-gyógyítás jelzés készül. A teljes API-adatfolyam nem tartalmaz bejövő heal eseményt. A klasszikus UnitIsUnit/targettarget csak opcionális és korlátozott aggrószínezést ad; teljes threat-tábla vagy általános nameplate–unit kötés nincs igazolva. A build szimulált, nem élő klienspróba.


## 0.9.4: ready-menetrend és chat

A felhasználó 0.9.3 játékfotója és visszajelzése alapján ready fázisban nem jelennek meg előzetes/cached bossidők, és nem mentünk ready adatból új tervet. A nevek maradnak; a friss aktív schedule továbbra is a saját idővonal adatforrása. A chatszélesség kezelése saját, visszaállítható natív frame-méretezés, a fejlécváltozás csak elrendezés. Külső kód vagy új API-feltételezés nem került be.


## 0.9.5: saját bossloot tooltip és tényszerű referenciakatalógus

- A 2026-11-04-én letöltött [bosslista](https://azeroth-survivors.org/bosses/) 65 hivatkozott bossoldalának tényszerű boss–kaszt–tárgy kapcsolataiból saját struktúrájú `BossLootData.lua` készült. Példa: [Kirtonos](https://azeroth-survivors.org/bosses/10506/). Az összes oldal URL-je, darabszám és a generált Lua SHA256 értéke a `BossLoot-reference.json` fájlban szerepel. A forrás független játékútmutató, nem hivatalos, élő API-válasz. A játékfrissítések módosíthatják a droplistát; esélyeket nem tárolunk.
- Csak tárgyazonosító, név, kaszt, tárgyhely, tier, natív ikonnév és bosskapcsolat került át tényszerű referenciaként. Weboldal-programkód, leíró szöveg, grafika, Azerloot-adatbázis vagy más addon megvalósítása nem került a csomagba.
- A `BossLoot.lua` saját UI, bizonyíték/név szerint elkülönített szerzésnapló és kézi jelölés. Az automatikus pozitív állapot forrása a már meglévő saját lootparser vagy a natív GetInventoryItemLink pontos azonosítója. Nem állít teljes Collection API-t vagy automatikus hiányzó státuszt. A forrásadatokból ellenőrzött katalógus nem jelent élő klienspróbát.
