# Holy Light × Eclipse — 0.9.10-preview

Ez az Azeroth Survivors (WoW 1.12.1, Interface 11200) **tesztverziója**, nem stabil kiadás. A korábbi arany–lila fő HUD-dizájnt megtartja. A stabil main változatlan.

## Elkészült funkciók

1. **HC és affixek a felső pályasávban.** Valódi `AZS_ZONE.heroic` és `AZS_ZONE.affixes` mezőkből. Például „AQ / HC 3”, alatta „EXPLOSIVE / SANGUINE” (csak akkor, ha valóban aktívak).
2. **Rövidebb boss HP-sávok:** 560 helyett 410 px, név, pillanatnyi/max HP, %, az `enraged` állapotra piros kiemelés.
3. **Kattintható bosssáv:** a rendelkezésre álló `TargetByName` kliensfunkcióval próbál név alapján célpontot választani. A játék nem biztosít az addon számára direkt, egyedi spawn-ID szerinti targetelést, így azonos nevű példányoknál a kiválasztás nem garantálható. A kliens hiányzó vagy sikertelen célzási API-ját jelzi.
4. **Egymástól független, összecsukható panelek:** DPS, Equipment, Loot, Buffs/Timers, Navigation, Jewelry, Party. A **–** gomb csuk, a helyben megmaradó **+** fejléc nyit. A panel mentett pozícióját, eredeti méretét, a többi panel helyét nem módosítja; nincs automatikus átrendezés. Mentés és visszatöltés a profilokkal.
5. **Co-op down alatt élő run kijelzés:** a helyi játékos elesése nem jelenti automatikusan a közös run végét. Amíg `AZS_GetRevive().down` igazolja az újraéleszthető állapotot, a timer, boss-HP és boss-timeline tovább olvassa a játék aktuális adatait. A runból származó, ellenőrzött időadatokat használjuk; a kliensadatok leállásakor nem találunk ki hátralévő időt.
6. **DBM-szerű, igazolt veszélyjelzés (új):** a korábbi bossriasztás helyén, egyetlen, piros ideiglenes panelben. Riaszt, ha a karakter HP-ja 30% alá esik (korábban 45% fölött volt), vagy ha egy friss mérésben legalább a maximális HP 35%-ának megfelelő sebzést kapott. A nagy találat üzenete kifejezetten **utólagos** („HEAVY HIT RECEIVED”), nem jövőbeli varázslatnak álcázott találgatás. Azonos helyzetre nincs folyamatos spam, legalább 8 másodperces korláttal. Halál, pause/choosing, futamváltás, max. HP-változás és kikapcsolás külön kezelt; a veszélyjelzés elsőbbséget élvez az általános bossérkezésnél.
7. **A 0.9.8 funkciói továbbra is megmaradnak:** bal oldali piros co-op down lista, iránynyíl, fehér normál/sárga crit, SELF/PARTY és RUN/BOSS/HEAL meter, arany–lila Bag, boss figyelmeztetés, futam végi összesítő.

## Veszélyjelzés korlátai

A jelenleg dokumentált addon API **nem ad megbízható, célpont- és időspecifikus előrejelzést minden boss varázslatára vagy affixre**. Emiatt a modul nem ír ki fiktív „MOVE!” vagy „EXPLOSIVE INCOMING!” riasztást pusztán azért, mert egy boss vagy affix aktív. A HP-alapú figyelmeztetés valódi, már bekövetkezett HP-változáson alapul. A HC-szint, az affixek és a boss Enrage állapota információként látható, nem önmagukban hangos riasztási okok.

A **Marks egyenleg** megjelenítésének igényét megőriztük az Equipment panel következő lépcsőjére. A vizsgált addon API-ban nincs dokumentált Marks-egyenleg-lekérdezés. Nem mutatunk kitalált egyenleget, és nem próbáljuk abból, hogy hány tárgy van a táskában, megbecsülni.

## Beállítások

- `/hle settings`: beállítópanel. „Verified danger cues” kapcsoló.
- `/hle threats`: a veszélyjelző ki-/bekapcsolása.
- `/hle bossalerts`: az általános bossérkezés riasztása.
- `/hle banners`: a játék natív középső bannerüzeneteinek visszakapcsolása/elnémítása.
- `/hle status`: API- és hibastátusz.

## Biztonságos telepítés és játékbeli ellenőrzés

1. Zárd be a játékot, készíts másolatot a korábbi `Interface/AddOns/HolyLightEclipse` mappáról, majd cseréld le az új ZIP-ben található `HolyLightEclipse` mappára. A `WTF` és a karaktermentések nem törlendők.
2. HC III / V körben ellenőrizd a pályanév melletti szintet és az affixeket.
3. Több boss esetén ellenőrizd a rövid HP-sávokat és a célzásra kattintást, valamint az Enrage jelzést.
4. Csukj össze és nyiss ki egy DPS, Equipment és Party panelt. Ellenőrizd, hogy **semelyik panel nem mozdul el**, és profilmentés után is megmarad-e az állapot.
5. Co-opban egy játékos elesése után figyeld meg, hogy a timer, boss HP és timeline a felélesztésig frissül-e. A teljes run végén ne maradjon elavult encounter.
6. Valós játékhelyzetben fokozatos HP-vesztésnél ellenőrizd a 30%-os figyelmeztetést; fontos, hogy a 35% feletti hirtelen találat utólagos „HEAVY HIT RECEIVED” feliratot kapjon. Érdemes kipróbálni a `/hle threats` kapcsolót.
7. Ha az addon hibázik: `/hle status`, és jegyezd fel a hibaszöveget.

A GitHub CI Lua 5.1-es szintaxisvizsgálatot és külön mesterséges adatokat használó regressziós teszteket futtat. A valódi Azeroth Survivors/vanilla kliensben és valódi co-op runban végzett próba **még szükséges**.
