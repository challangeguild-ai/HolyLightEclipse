# Holy Light × Eclipse 0.8.3

Telepíthető Azeroth Survivors addon, WoW 1.12.1 formátum: `## Interface: 11200`.
A saját arany/lila megjelenés, a bal oldalon rögzített játékoskeret és a mindig látható középső címer megmaradt.

**Ellenőrzés: fájlszerkezet, XML, textúrák, ismert újabb Lua-elemek kizárása és szimulált Lua 5.1 / WoW API regressziós tesztek. Ez nem élő Azeroth Survivors klienspróba és nem valódi Lua 5.0 interpreterteszt.**

## Telepítés / frissítés

1. Lépj ki teljesen a játékból.
2. A `HolyLightEclipse-0.8.3.zip` belsejében lévő **HolyLightEclipse** mappát másold a kliens `Interface/AddOns/` mappájába. Ha az AddOns nem létezik, létrehozható.
3. Frissítéskor a korábbi HolyLightEclipse addonmappát cseréld erre a teljes mappára. Ne legyen egyszerre két eltérő verzió, és ne maradjanak régi Lua-fájlok egy összefésült mappában. A játék mentett beállításait nem szükséges törölni.
4. Helyes útvonal: `Interface/AddOns/HolyLightEclipse/HolyLightEclipse.toc`. Nem a ZIP-et és nem az outputs mappát kell bemásolni.
5. Indítsd újra a klienst. Más teljes HUD-cserét (például KeijinUI, SurvivorUI vagy SurvivorsDragonUi) ne futtass vele egyidejűleg: ugyanazokat a natív elemeket vennék át.

## A 0.8.1 változásai

### Spellikonok és cooldownok

- A saját ikonrajzolás most akkor is látható marad, amikor egy eredeti ActionButton kerül az arany keretbe. Az eredeti gomb rejtett vagy hiányos ikonrétege így nem tünteti el a saját képet.
- A kép a natív gomb fölötti külön rétegen van; az eredeti gomb kattintási és eseménykezelő szkriptjeit nem írjuk át. Ez önmagában nem módosítja a karakter varázslatgrafikáját.
- Az API-hívások nem kapnak fölösleges nil paramétereket. A szigorúbb kliensfüggvények így pontos argumentumszámmal hívódnak.
- Teljes és puszta ikonnevekből is használható textúraútvonal készül; a kérdőjel nem számít megtalált képnek.
- Friss AZSSPELLS publikáció újraépíti a spellbook metaadatát akkor is, ha nem érkezett SPELLS_CHANGED.
- Hiányzó képadatnál 12 ellenőrzött paladin/racial kulcs saját megjelenítési tartalékot kap: Consecration, Exorcism, Hammer of Wrath, Holy Wrath, Holy Shield, Redemption, Perception, Holy Shock, Judgement, Hammer of Justice, Holy Light, Divine Shield. Ezek csak ikonútvonalak: nem adnak képességet, rangot vagy cooldownadatot.
- A képességtagság továbbra is a friss futamlistából vagy az aktuális runId-hoz tartozó teljes MeterLoadoutból származik. Egy régi gombon maradt ikon nem engedélyez régi képességet. Legfeljebb 32 képesség jelenik meg, hét oszlopos, több sorba törő elrendezésben.
- Cooldown: hiteles natív akcióadat, vagy az adott futam AZSSPELLS időzítése. Pause/choosing alatt nem fut önálló falióra. Ismeretlen időnél `?` látszik, nem kitalált visszaszámlálás. Passzív képesség nem kap hamis CD-t.
- Más kaszt egy ismeretlen képességéhez továbbra is szükséges natív/spellbook/aktuális loadout ikonadat. Nincs minden kasztra kiterjedő beépített ikonkatalógus.

### Felső sáv

A következő láda ára (`AZS_RUN.chest`) a gyűjtött arany mellé került: `KILLS … GOLD … CACHE …`. A DPS-mérőből kikerült. A boss-sávok halálkor azonnal törlődnek; újraéledés után friss encounter-adatra várnak. Target nélkül a teljes targetpanel eltűnik, a játékoskeret és címer helyben marad.

### Run / Boss / Healing mérő

A mozgatható, 230×156 egységes mérőablak alján három kattintható fül: RUN, BOSS, HEAL.

- RUN: `AZS_GetMeter`, az egész futam sebzése, futamátlag DPS.
- BOSS: `AZS_GetBossMeter`, a játék API-jának aktuális/legutóbbi bossfightja és annak DPS-e. Nem önálló fight-felismerés.
- HEAL: `AZS_GetHealing`, az egész futam tényleges gyógyítása és HPS-e; az API által kizárt overheal nem kerül vissza.

A négy legnagyobb forrás látszik. Hiányzó getter esetén az adott fül `API unavailable` üzenetet mutat, nem másik nézet adatait. A resetelt natív ablak és a teljes futam API-összeg eltérhet; az addon nem nullázza a játék mérőit. A fülek nézete mentődik, a harci számlálók nem.

### Aurák, buffok, summonok és talent/jewelry időzítők

- A megjelenített legfeljebb három boss/guardian alatt maximum 12 debuffikon jelenhet meg a spawn-id alapján hívott `AZS_GetDebuffs(id)` adataiból, stackkel és API által számolt hátralévő idővel. A következő encounter sora lejjebb kerül, hogy ne fedje a debuffokat. Hiányzó API csak az ikonokat rejti el.
- Target alatt legfeljebb négy natív buff és öt debuff kap külön sort. A vanilla UnitBuff/UnitDebuff adatokból nem találunk ki időtartamot; a tooltipet a natív unit-aura API adja, ha elérhető.
- A külön mozgatható BUFFS / SUMMONS panel legfeljebb 24 ikont mutat: natív helpful buffok, `AZS_GetTimers()` proc/next-summon órák, `AZS_GetSummons()` aktív idézések élettartama. Az állandó idézés nem kap lejárati időt. A next-summon óra nem ígér garantált idézést: a játék egyéb feltételei továbbra is számítanak.
- Az AZSPETS/AZSTIMERS friss publikáció vagy friss *_UPDATED bélyeg nyitja meg az adott futam feedjét. Új run, világváltás, halál és újraéledés törli ezt az engedélyt. Replay/frissítés nélküli kliensen ezek az extra ikonok hiányozhatnak; nem mutatunk helyettük előző futamból megmaradt állapotot.
- A buffok/summonok nem kerülnek a mentett beállításokba. A natív buffokat nem rejtjük el önállóan.

### Felszerelés és megfigyelt ékszerek

Az öthelyes felszereléskijelzés natív inventory textúrákat és tooltipet használ. Ha GetInventorySlotInfo nincs, az ismert vanilla slotazonosítók szolgálnak tartalékként (11,12,2,13,14). A RUN TOTAL statok az egész futam összegét jelentik, nem az öt tárgy egyedi hatását.

A `/hle journal` külön panelt nyit. RUN: az aktuális, ellenőrzött MeterLoadout runJewelry listája; régebbi kliensen az öt tényleges inventory hely. RUN/SEEN váltó: a ténylegesen látott ékszerek mentett naplója. Nyolc sor/oldal, lapozógombokkal. A napló legfeljebb 200 külön megfigyelést tárol, nem teljes dropkatalógus és nem garantálja az összes gyűjthető tárgy ismeretét.

A napló név/ikon/kategória és elérhető natív tárgyhivatkozás adatot ment, runId-t, itemInstanceKey-t, harci számlálókat nem. Natív tárgyhivatkozás esetén az eredeti tooltip adja a statokat. A MeterLoadout csak név/kategória/ikon metaadata esetén nincs kitalált tárgystat: a tooltip jelzi a hiányt. Csak aktív futamban frissül az aktuális tárgylista; a napló szándékosan megmarad.

### Láda és guardian irányjelzés

A külön mozgatható panel a legközelebbi láda és lair relatív irányát (`AHEAD`, `LEFT`, `RIGHT`, `BEHIND`), síkbeli yardtávolságát és az üres lair API által jelentett visszatérési idejét mutatja. A lair otthont jelöl, nem egy elhúzott guardian pillanatnyi pozícióját. A három yardon belüli cél `HERE`.

Csak a friss `AZS_GetPlayerPosition()` és a vele runId/mapId/spaceId szerint egyező AZS_CHESTS / AZS_GetLairs adatok használhatók. Másik térkép/futam adatai nem adnak irányt. Getter nélkül a panel rejtett. Nincs becsült map-koordináta átszámítás, automatikus mozgás, útvonalkeresés vagy új minimapikon-rendszer. A kijelzett távolság nem kerülőutat és nem magasságkülönbséget mér. A panel opcionális: `/hle navigation`.

### Beállításablak és profilok

`/hle` vagy `/hle settings`: mozgatható, saját színű ablak. Kapcsolók a meter, equipment, loot, nameplates, effects, directions és jewelry/diary panelekhez. MOVE/LOCK, SCALE −/+, három SAVE/LOAD profilhely. A profilok csak elrendezést és kijelzési beállításokat mentenek, harci állapotot és ékszernaplót nem. Nincs külön profilnév-szerkesztő, keresőmező vagy rácsra igazítás ebben a kiadásban.

## További meglévő funkciók

- Health/power/XP/shield unit frame-ek, feature-detected natív fallbackkel.
- Saját nameplate-megjelenés a WorldFrame tényleges natív sávjain. A százalékot a natív értéktartományból olvassa. Nincs plate GUID: az azonos nevű célpontok kiemelése nem garantált egyedi azonosítás. `/hle plates` visszaállítja a régi megjelenést. A V billentyű a natív láthatóságot kezeli.
- Saját lootkártyák saját lootchatből. Csak megértett saját formátum után veszi át a natív lootértesítést; ismeretlen formátumnál visszaadja. Tárgynevet/count/utótagot megtart, nem következtet "új tárgy" státuszra. ItemInfo hiányánál szöveges kártya marad. A kétszer érkező két külön lootcsatornát szűri, valódi azonos csatornás két dropot nem von össze.
- A nagy natív `Move to begin` szöveget csak célzott szövegegyezéssel rejti, nem minden bannert. Az addon saját kis kezdőfelirata megmaradhat. Kizárólag motorban, Lua-kereten kívül rajzolt felirat elrejtése nem garantált.
- A natív HUD átvételekor rögzíti és off/world-leave esetén visszaállítja a korábbi állapotokat. Külön natív API/módszer hiányánál az adott átvétel kimaradhat.

## Parancsok

| Parancs | Művelet |
|---|---|
| `/hle` / `/hle settings` | Beállításablak |
| `/hle on`, `/hle off` | Saját HUD be/ki; off visszaállítja az átvett natív elemeket |
| `/hle native` | Natív HUD átvétele ki/be |
| `/hle meter` | Mérő ki/be |
| `/hle meter run`, `/hle meter boss`, `/hle meter heal` | Mérőfül |
| `/hle gear` | Inventory/stat panel |
| `/hle journal` | Run-ékszerek és megfigyelési napló |
| `/hle navigation` | Láda/lair irányjelzés |
| `/hle effects` | Buff/summon/talent időzítők |
| `/hle loot`, `/hle loot clear` | Lootpanel kapcsolása / kártyák törlése |
| `/hle plates`, `/hle plates 1.2` | Nameplate megjelenés / méret |
| `/hle unlock`, `/hle lock` | Panelek húzása; a meter lezárva is húzható |
| `/hle scale 0.85` | Globális méret 0.6–1.4; alaphelyzetekre állítja a paneleket |
| `/hle profile save 1`, `/hle profile load 1` | Profil (1, 2, 3) |
| `/hle reset` | Panelpozíciók és globális skála alaphelyzetbe; napló/profil nem törlődik |
| `/hle levels` | Eltárolt szintlépések megnyitása, ha a játék támogatja |
| `/hle status` | Verzió, API és hibadiagnosztika |

## Élő kliensben ellenőrizendő

A statikus/szimulált ellenőrzés nem bizonyítja a kliens renderelését vagy a telepítést. Külön ellenőrizendő: új run kezdőikonjai; újonnan tanult minden paladin spell; halál/újrapróba és boss-sáv törlése; target megszüntetése; cooldown pause közben; natív tooltip és kattintás; valódi bossloot; UI-skála; summon/buff feed replay; lair visszatérés; profilok megmaradása újraindítás után. Ismeretlen kasztikonhoz továbbra is szükséges a játék képadatforrása.

A KeijinUI ötleteit saját megvalósítás követi, a kinézetünk megtartásával. Nem teljes Keijin-port: például party meter, futamösszehasonlítás, advisor, teljes gyűjteményadatbázis, német/egyéb lokalizációs katalógus és minimapcserék nincsenek benne. Források: SOURCES.md.


## 0.8.1 – elhelyezés és olvashatóság

A láda/guardian irányjelzés a felső-középső játéktérbe került, alatta jelennek meg a lootkártyák és ikonok. Ez szabadon mozgatható képernyőpozíció, nem egy konkrét ellenfelet követő világkoordinátás jelölő: a lootchat nem közöl ilyen pozíciót. Frissítéskor egyszer a két panel régi mentett pozíciója törlődik; minden más elrendezés megmarad. A korábban mentett profil kézi betöltése visszahozhatja annak régi pozícióit.

Nagyobbak az irányjelzés, felső statok, DPS-összeg, inventory statok és lootfeliratok. Az Action bar működése, mérete és elrendezése változatlan. Az ellenfelek névtáblájának bal oldalán a natív névtábla szintfeliratából kiolvasott Lv szám jelenik meg, újrahasznosított plate-en is frissítve. Ismeretlen natív szintnél ?? látszik, hiányzó szintadatnál nincs kitalált szám. A kijelölt ellenfél alsó kerete a valódi UnitLevel(target) szintet mutatja, ha elérhető.


## 0.8.2 – aurák a unit frame-ek fölött

A játékos helpful és harmful aurái, valamint a támogatott talent/summon időzítők a saját HP-keret fölött jelennek meg, hét ikon széles, felfelé bővülő sorokban. Az aurapanel a player frame gyermeke, együtt mozog és skálázódik vele; korábbi külön effects panelpozíciója nem érvényesül. A target buff/debuff ikonok a targetkeret fölé kerültek, és target nélkül együtt eltűnnek vele. Az Action bar változatlan.

A szintlépési választókártyák kinézete nem változott: a vizsgált API csak az addonkeretek kártyák fölötti megjelenítését szabályozza, nem dokumentálja a választókártyák elérését, újrarajzolását és biztonságos választáskezelését. Ezekre nem készítettünk nem ellenőrizhető helyettesítőt.


## 0.8.3 – pályánként dinamikus elit/guardian lista

Az irányjelző és láda-navigáció helyét arany/lila ablak vette át közvetlenül a Ring/Trinket equipment panel fölött. A panel az equipment pozícióját követi, annak áthelyezésekor együtt mozog vele; a régi navigation pozíciómentés nem hat rá. A ládaár a felső aranyszámláló mellett marad, a valódi lootértesítések külön kártyái változatlanok.

A neveket minden frissítés az aktuális pálya AZS_GetLairs() listájából olvassa, nincs kézzel beírt pálya-/névkatalógus. Csak az aktuális AZS_GetPlayerPosition runId/mapId/spaceId értékeivel egyező bejegyzéseket listázza, koordinátaszámítás vagy nyíl nélkül. Available: a guardian a helyén vár; Fighting: aktív harc; az empty helyen az API left mezője adja a Respawn időt. A neveket nem vonja össze: két azonos nevű lair két sor marad. Hat sor oldalanként, több bejegyzésnél lapozás. Az új pálya listája leváltja a korábbit; hiányzó API vagy aktuális adat esetén várakozási üzenet látszik.

A kijelzett idő a játék által publikált érték (várakozáskor a dokumentáció szerint másodpercenként frissül), nem saját feltételezett respawn-periódus. Öt másodpercnél régebbi ismert publikációs bélyegnél frissítésre várást jelez; nem folytat hamis számlálást. A halál önmagában nem indít saját órát, a játék lair-state frissítése szükséges. A panel halott játékos mellett is olvasható, amíg a run aktív.

Fontos API-korlát: ez a respawnhellyel rendelkező guardian/elit lista. A kliens nem ad ezzel egy általános felsorolást minden szabadon kóborló elit mobról, sem azok ismeretlen respawnidejéről. Ilyen adatot az addon nem talál ki. A kapcsoló továbbra is /hle navigation, a beállításokban Elite / guardian list néven szerepel. A buff/debuff és Action bar változatlan.
