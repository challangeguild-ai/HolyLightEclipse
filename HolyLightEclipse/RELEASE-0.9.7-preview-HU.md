# Holy Light × Eclipse – 0.9.7-preview (tesztkiadás)

Az addon továbbra is **általános Azeroth Survivors HUD**. A fő HUD, az arany–lila téma, a boss timeline, a co-op panelek, az ékszer-/loot modulok és a beállításprofilok megmaradnak. A fejlesztés nem írja felül a stabil 0.9.5 kiadást.

## Elkészült funkciók

1. **SELF / PARTY DPS meter**, mindkét nézetben RUN, BOSS, HEAL kapcsolóval. Új klienseken a `AZS_GetMeterSnapshot()` saját és party adatokat, boss-sebzést és teljesített gyógyítást kér le. Régi klienseken SELF RUN/BOSS/HEAL és PARTY RUN fallback van; a nem rendelkezésre álló party boss/heal nézet nem talál ki adatot.
2. **Co-op mentési nyíl** csak elesett társ esetén: név, egyszeri haláleseti riasztás, hiteles újraélesztési pozíció és a játékos nézési iránya alapján relatív irány, légvonalbeli yardtávolság. Pontos helyadat nélkül csak figyelmeztetés, iránynyíl nincs. Több elesett társ esetén a legközelebbi ismert helyet választja.
3. **Kimenő sebzésszámok**: normál találat fehér, kritikus találat sárga és nagyobb. A natív projekciós combat-text API szükséges.
4. **Bag / inventory skin**: a játék natív `ContainerFrame` táskaablakain sötétlila háttér, arany szegély, diszkrét felirat és a tárgyminőség szerinti keretek. A tárgyrendezést, kattintást, drag-and-dropot, tooltipeket és a táska pozícióját a natív játék kezeli; ezekhez nem nyúlunk. Az API/ablak nélkül a funkció ártalmatlanul inaktív.
5. **Bossjelzés**: a natív boss/finalboss banner eseményre egyszer jelenik meg rövid, 2,4 másodperces, arany–lila értesítés. Nem következtet a cached boss schedule-ból, és nem takarja el tartósan a felületet.
6. **Futam végi összesítő**: a `AZS_GetRunSummary()` által adott tényleges idő, szint, ölések, elitek, bossok, sebzés, átlag-DPS, kapott sebzés, arany és chest/magnet szám. Csak megbízható, terminális eredmény esetén nyílik. Bezárható és a futam végéig újranyitható.
7. **Skill READY kiemelés**: csak igazolt cooldown-átmenetnél, rövid ideig. Nem jelez állandóan olyan képességnél, ahol nincs cooldown információ.
8. **Adaptív megjelenés**: a meglévő co-op panel solo módban eltűnik; mentési nyíl, bossfigyelmeztetés és futamösszesítő csak releváns állapotban jelenik meg. A kasztokat az addon natív képesség- és felszerelésadatai alapján kezeli; nem ad Paladin-specifikus funkcionális előnyt.

## Vezérlés

| Parancs | Funkció |
|---|---|
| `/hle` | Beállítópanel; új kapcsolók is |
| `/hle meter self` / `/hle meter party` | Saját / csapat DPS |
| `/hle meter run` / `/hle meter boss` / `/hle meter heal` | A három statisztikai bontás |
| `/hle rescue` | Halott társ figyelmeztetése és iránya |
| `/hle bag` | Táskaskin ki/be |
| `/hle bossalerts` | Bossfigyelmeztetés ki/be |
| `/hle summary` | Futam végi összesítés megnyitása/bezárása, ha rendelkezésre áll |
| `/hle skills` | Képesség READY jelzés ki/be |
| `/hle damage` | Egyedi kimenő sebzésszámok |
| `/hle off` / `/hle on` | HUD kikapcsolás/bekapcsolás; natív felület visszaállítása |

A kapcsolók és a SELF/PARTY választás a profilokban is menthető.

## Telepítés

Zárd be az Azeroth Survivorst. A teszt ZIP egyetlen `HolyLightEclipse/` mappát tartalmaz; másold a játék AddOns mappájába az előző verzió mappája helyére (például `benilla-config/AddOns/HolyLightEclipse/`). A `SavedVariables` mentéseket ne töröld.

**Tesztelt:** Lua 5.1 syntax check, szimulált SELF/PARTY meter, Bag, bossbanner és végösszesítő tesztek, a ZIP belső integritása. **Nem tesztelt:** élő Azeroth Survivors co-op kliens, eltérő bag frame layout, valódi boss- és halálesemények, minden kaszt, teljes UI skálázás. A telepítő előnézet, nem végleges release.

## Ajánlott játékbeli próbasorrend

Solo futam → bag megnyitás és egy tárgy mozgatása → SELF RUN/BOSS/HEAL → boss érkezés és halál → saját skill READY → futam vége, összesítő bezárása/újranyitása → co-op PARTY RUN/BOSS/HEAL → halott csapattárs felé vezető nyíl és újraélesztés → kilépés, új futam, /reload.

Ha a táskakép nem egyezik a játék által felhasznált ContainerFrame típussal, a native inventory sértetlenül megmarad; a skin pontosításához egy képernyőkép segít.
