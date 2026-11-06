# Holy Light × Eclipse 0.9.12-preview — bossveszélyek és natív szövegspam

Ez a WoW 1.12.1 / Azeroth Survivors **tesztverziója**. A stabil main ágat nem módosítja.

## Miért volt kevés a DBM?

A 0.9.11-preview ténylegesen csak HP-alapú riasztásokat adott: **HEAVY HIT RECEIVED** (már bekövetkezett találat) és kritikus HP. A játék dokumentált addon API-ja nem tesz közzé minden bossvarázslathoz célpontot, cast-kezdést vagy várható találati időt. Így az ilyen riasztások előrejelzése találgatás lenne.

A 0.9.12-preview két további, **bizonyítható** eseményt figyel:
- **BOSS ARRIVING SOON**: a játék `AZS_GetUpcomingBosses()` listájában a boss `index`, `at` és `left` mezői érvényesek, a megjelenésig legfeljebb 8 másodperc van hátra. Egy boss érkezésére legfeljebb egyszer jelez.
- **BOSS ENRAGED**: egy valóban élő boss `AZS_GetBosses()` adataiban az `enraged` jelzés igaz; egyszer jelzi az adott boss egyedi spawn-azonosítójához kötve.

A jelzések ugyanazt a már meglevő középső kijelzőt használják, nincs új állandó panel. A kritikus HP-figyelmeztetés magasabb prioritású, mint a bossérkezés/Enrage. Hangenként és azonos eseményenként korlátozott a riasztás. Az angol, magyar, német és egyszerűsített kínai fordítások is szerepelnek.

**A rendszer továbbra sem jelez kitalált Explosive, Sanguine, Bolstering vagy célzott bossvarázslatot.** A `HEAVY HIT RECEIVED` szöveg utólagos figyelmeztetés marad, nem állítjuk, hogy előre láttuk a támadást.

## A játék középső szövegspamjének javítása

A korábbi implementáció a natív középső feliratok némítását tévesen összekapcsolta a saját bossfigyelmeztetés (`bossAlerts`) bekapcsolt állapotával.

A `Quiet center notices` kapcsoló most már:
- a saját bossfigyelmeztetéstől függetlenül működik;
- a teljes natív HUD-csere kikapcsolása mellett is megpróbálja némítani a játék saját bannereit;
- elsődlegesen `AZS_SetHudShown("banners", false)` hívást használ, szükség esetén a dokumentált `hudBanners` CVar-t is;
- a játék saját `AZS_BANNER` / `AZS_BANNERS` listájában szereplő, legfeljebb 6 másodperces és szövegében pontosan egyező üzenetek másodlagos kirajzolását is szűri a középső natív üzenetkeretekben;
- nem némítja el az összes hibát vagy egyéb általános játékszöveget, és addon-kikapcsoláskor visszaállítja a játékos eredeti beállítását.

**Fontos korlát:** ha egy zavaró szöveg nem a játék dokumentált banner-csatornáján vagy a vele egyező középső natív keretben jelenik meg, az addon nem tudja bizonyíték nélkül biztonságosan kiszűrni. Ebben az esetben a szöveg pontos megjelenése (képernyőkép) és a `/hle status` eredménye szükséges a csatorna azonosításához.

## Telepítés és gyors teszt

1. Zárd be a játékot, készíts biztonsági másolatot a régi `Interface/AddOns/HolyLightEclipse` mappáról.
2. A teljes 0.9.12 ZIP-ben lévő `HolyLightEclipse` könyvtárat másold a régi helyére; a WTF mappát és karaktermentéseket ne töröld.
3. **Settings → Alerts → More settings**: a **Hide native center messages** legyen bekapcsolva. A saját bossérkezés-figyelmeztetés ettől függetlenül ki-/bekapcsolható.
4. Futás közben nézd meg, hogy megszűnnek-e a középső feliratismétlések.
5. Boss előtt 8 másodperccel és valódi Enrage állapotnál egyszeri jelzés várható, amennyiben az API aktuális adatot ad.
6. Ha még mindig spammel: `/hle status`, valamint egy képernyőkép a konkrét ismétlődő feliratról.

**Ellenőrzés:** GitHub CI Lua 5.1 szintaxisellenőrzés és összesített regressziós tesztek, köztük külön natív banner/CVar teszt és boss-előrejelző/Enrage teszt. Valódi kliensben még ellenőrizendő.
