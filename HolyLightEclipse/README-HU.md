# Holy Light × Eclipse 0.9.5

Telepíthető Azeroth Survivors addon, WoW 1.12.1 formátum: `## Interface: 11200`.
A saját arany/lila megjelenés, a bal oldalon rögzített játékoskeret és a mindig látható középső címer megmaradt.

**Ellenőrzés: fájlszerkezet, XML, textúrák, ismert újabb Lua-elemek kizárása és szimulált Lua 5.1 / WoW API regressziós tesztek. Ez nem élő Azeroth Survivors klienspróba és nem valódi Lua 5.0 interpreterteszt.**


## Aktuális kiadás: 0.9.5 — bossloot egér fölé vitelre

Vidd az egeret a felső idővonal egyik bossnevére vagy ikonjára. Saját arany/lila ablak jelenik meg az aktuális kaszthoz tartozó lehetséges felszerelésdropokkal, tárgyikonnal és megszerzési jelzéssel. Az ablakra átvihető az egér, a sorok is kezelhetők; távozás után rövid késleltetéssel bezárul. A játékoskeret, action bar, chat, mérő, boss HP és idővonal elrendezése nem változott.

### Katalógus és pontosság

A beépített, 2026-11-04-én letöltött nyilvános referenciában 65 boss, kilenc kaszt, 581 különböző felszerelésazonosító és 647 boss–kaszt–tárgy kapcsolat szerepel. Ez statikus referencia, nem a futó kliens teljes lootadatbázisának kiolvasása. Nincsenek százalékos dropígéretek: a patch, nehézség és gyűjtemény befolyásolhatja az esélyeket. Az ikonokhoz csak a referenciában megnevezett natív játéktextúrák neveit használjuk, külső képfájlt nem vettünk át. A források és a generált adatfájl ellenőrzőösszege a `BossLoot-reference.json` fájlban vannak.

Az aktuális kaszt a natív UnitClass angol tokenjéből, ennek hiányában az AZS_ZONE.class mezőből származik. Hiányzó kaszt vagy nem ismert boss/kaszthoz tartozó adat esetén informatív üres állapot jelenik meg. A bossnevek illesztése a referencia angol neveivel történik; eltérő lokalizált vagy később átnevezett bossra nincs találgatott névalias. A lista nem tartalmaz minden véletlen gyűrűt/trinketet, és nem állítja, hogy minden felsorolt tárgy garantáltan esik. Az a bővítés a bossokhoz rendelt permanens kasztfelszerelés referenciája.

### Megvan-e?

- **COLLECTED (SELF LOOT):** az addon felismert saját lootüzenetben látta ezt a katalógusbeli tárgyat.
- **COLLECTED (EQUIPPED):** a natív felszereléslink pontos tárgyazonosítójával igazoltuk a birtoklást. A páncél- és fegyverhelyeket fél másodpercenként olvassuk, aktív runban és ready állapotban.
- **COLLECTED (YOUR MARK):** te jelölted meg megszerzettként.
- **MISSING (YOUR MARK):** te jelölted hiányzónak.
- **UNKNOWN:** nincs igazolás vagy kézi jelölés. Nem jelenti azt, hogy nincs meg.

**Jobb klikk egy nem automatikusan igazolt tárgysoron:** megvan → hiányzik → automatikus/ismeretlen. A teljes régi Collection adatbázisra nincs ellenőrzött addon getter, ezért a korábban megszerzett tárgyak kezdetben ismeretlenek lehetnek; ezeket így tudod megjelölni. Automatikusan igazolt szerzést a kézi váltó nem ír felül hiányzóra.

A napló a `HLE_DB.bossLootOwned` SavedVariables mezőben, kaszt + karakter neve szerint tárolódik. Másik nevű karakterre nem örökítünk birtoklást. Ez megfigyelési napló, nem teljes élő Collection-szinkron: régebbi mentés importálását vagy azonos nevű eltérő mentés/profil használatát nem tudja bizonyosan felismerni. Előforduló azonos tárgynevekből nem következtetünk több különböző tárgy megszerzésére. Tárgylink esetén az azonosító az elsődleges; ismeretlen vagy más kaszthoz tartozó linket nem helyettesítünk név alapú találgatással. Csak a saját lootmintát fogadjuk el, más játékos lootját nem. A szerzésnapló a felugró lootértesítés kikapcsolása mellett is működik, ha maga az addon aktív. Az addon kikapcsolása nem rögzít szerzéseket, és elrejti a bosslootablakot. A megfigyelt szerzések runváltáskor megmaradnak.

### Telepítés és ellenőrzés

Kilépett játéknál a ZIP `HolyLightEclipse` mappájával cseréld le az azonos nevű régi mappát. A beállításokat és SavedVariables-t nem kell törölni. A katalógus helyben van, a futó addon nem kapcsolódik weboldalhoz, nem küld adatot és nem választ lootot helyetted.

A fájl/TOC/XML/ZIP/textúra és Lua 5.1 mock regressziók sikeresek. Új tesztek: 65 boss és kilenc kaszt kapcsolatai; kasztszűrés; ismeretlen/adat nélküli állapot; hover és bezárás; kézi jelölés ciklusa; saját/idegen loot szétválasztása; kikapcsolt értesítés mellett naplózás; pontos felszerelésazonosító; más nevű karakter elkülönítése; runváltás és kikapcsolás. **0.9.5 élő klienspróba nem történt, és valódi Lua 5.0 interpreterrel nem teszteltük.** A teljes gyűjtemény automatikus importja nincs megvalósítva.

## Előző kiadás: 0.9.4


Három célzott javítás, a 0.9.3 többi funkciójának megtartásával:

- **Run előtti bossidők:** ready állapotban a megfigyelt bossnevek és kardikonok megmaradnak, az idő helyén `--:--` látszik. A kliens előzetes/default ütemezését és régi mentett időit nem tüntetjük fel az új run hiteles idejeként. Ready adatokkal nem írjuk felül a korábban aktív runban megfigyelt tervet. Induláskor a friss schedule megérkezésétől a megszokott dinamikus visszaszámlálás működik. Pontos előzetes időt a jelenlegi kliensadatok alapján nem igazoltunk; ez a javítás elrejti a bizonytalan időt, nem talál ki helyette másikat.
- **Chat:** a fő ChatFrame1 (ennek hiányában DEFAULT_CHAT_FRAME) legfeljebb 360 natív UI-egység széles; ha a playerkeret bal széle és a chat között ennél kevesebb a hely, ehhez igazítjuk. A magasság, pozíció, betűméret és üzenetek nem változnak. Off és világ elhagyása visszaállítja az eredeti szélességet, amennyiben még az addon által beállított érték van használatban. Nincs chatszöveg-szűrés.
- **Fejléc:** KILLS közvetlenül a középső runóra bal oldalán, jobbra igazítva, azonos sorban a jobb oldali GOLD/CACHE adatokkal. A pályanév a bal felső fejlécsorban külön helyet kap.

A célzott szimulált tesztek ellenőrzik a ready-idők elrejtését, a mentett terv megőrzését, a friss aktív run visszaszámlálását, a chat helyigényét és visszaállítását, valamint a számlálók közös sorát. A fájl/ZIP, XML, textúra és a korábbi regressziós ellenőrzések is sikeresek. **0.9.4 élő klienspróba nem történt.** Telepítés: kilépett játéknál a ZIP HolyLightEclipse mappájával cseréld le az azonos nevű korábbi mappát; SavedVariables törlése nem szükséges.

## Előző kiadás: 0.9.3


Az alábbi leírás az aktuális működés. A későbbi verziószakaszok változástörténetet őriznek, az eltérő régi elrendezési leírásokat ez felülírja.

- **DPS/HPS mérő:** alapból 280 széles, nyolc sorral. Alján `+`/`−` növeli/csökkenti a látható sorokat 4–16 között. A `<`/`>` lapoz, ha több képesség van: nem csak az első négy spell olvasható. `/hle meter rows 10` és `/hle meter width 340` menti a külön mérőméretet (szélesség 230–480). A mérő továbbra is húzható. A RUN/BOSS/HEAL fülek megmaradtak.
- **Felső panel:** pályanév és KILLS balra, középen új, külön óradísz és nagy, kétjegyű `00:37` runóra; jobbra GOLD és CACHE egy sorban. A rövidített nagy összegek teljes értéke egérrel a statmező fölött olvasható. A boss-idővonal ezen a közös panelen belül marad. A panel magasságát az adott menetrend sorai adják, harc és aurák nem növelik.
- **Boss HP:** a felső panel alatt külön, legfeljebb három 560×20-as HP-sáv, fix 72 egység magas területen. Elit HP sosem kerül ide. További aktív bossok számát a fejléc jelzi. Itt nincsenek aurák; célpontként a targetkeret aurái továbbra is működnek.
- **Elitek:** a bal oldali táborlista helyén az élő elit HP-ja látszik, ha a friss guardian-adat pontos `id` szerint hozzákapcsolható a táborhoz. Harc alatt is itt marad. Név alapján nem kapcsolunk össze azonos nevű ellenfeleket. Ha nincs biztos HP-adat, az állapotfelirat megmarad. Üres táborban respawnidő látszik; a koponya csak ebben a runban már élőként megfigyelt tábor kiürülése után jelenik meg. Az API `empty` állapota első megfigyeléskor nem bizonyít korábbi ölést. Buff/debuff itt nincs.
- **Aggrószínek, korlátozottan:** a régi nameplate nem ad dokumentált stabil ellenfél-azonosítót vagy teljes threat-táblát. Csak egyetlen, egyértelműen kiemelt target plate-nél és érvényes `targettarget`/`UnitIsUnit` adat mellett színezünk. Piros: téged céloz; sárga: egy party-tagot céloz; zöld: igazoltan mást céloz. Ez utóbbi kettő célpontviszony, nem threat-százalék vagy előrejelzett aggróváltás. Ismeretlen vagy többértelmű adat semleges lila. A teljes mező összes mobjára kért megbízható zöld/sárga/piros threat-jelzés a jelenleg ellenőrzött API-ból nem állítható elő. Nem váltunk célpontot adatgyűjtéshez.
- **Sebzésfelirat:** külön `CombatText.lua`, alapból bekapcsolva, ARIALN betűvel (ha a kliens elutasítja, FRIZQT tartalékkal). Csak a dokumentált world-anchored combat-text API teljes elérhetősége és sikeres natív szám-elrejtés esetén veszi át a kimenő sebzésszámokat. A natív esemény saját anchorja a `WorldFrame` alatt, kamera utáni callbackben mozog; nem találgatunk ellenfélnevek alapján. Legfeljebb 128 egyidejű, 1,1 másodperces szám; késői vagy helyadat nélküli eseményt nem rajzol. Hiányzó API/híváshiba esetén a natív számok maradnak vagy visszaállnak. Kikapcsolás, halál, világ elhagyása és streamhiba visszaállítja az átvett CombatDamage beállítást. `/hle damage` ki/be kapcsolja. Más combat-text addonnal egyszerre ne legyen két aktív kimenő renderer.
- **Kapott gyógyítás:** zöld `+… HEAL` felirat a karakter közelében, az `AZS_GetHealing()` összesített tényleges gyógyításának pozitív különbségéből. Nem HP-különbséget számol, nem nevez meg nem ismert gyógyítóspellt, és nem mutat overhealt vagy előre jelzett beérkező castot. Ez a publikációk közötti összeg, nem külön eseményenkénti gyógyítás. Új run, halál, menü, total-visszaesés és szüneteltetett választás nem generál hamis feliratot. `/hle healing` ki/be kapcsolja. A játék saját incoming/self szövegbeállításait nem írja át.

**Telepítés:** kilépett játéknál a ZIP-ben levő teljes `HolyLightEclipse` mappával cseréld le az azonos nevű addont. Ne legyen két példány vagy egymásba ágyazott addonmappa. A beállításokat nem kell törölni. Az Action bar logikája és natív skinmodulja változatlan.

**Ellenőrzés:** fájlszerkezet, XML, textúrák és Lua 5.1 mock regressziók, az új méretezés/lapozás, pontos elitazonosító, bossaurák hiánya, korlátozott aggró, combat-text stream/hiba/visszaállítás, gyógyítás és szünet tesztjeivel. A 0.9.3 nincs élő játékban vagy valódi Lua 5.0 interpreterrel ellenőrizve. Az új betű és órakeret tényleges kliensbeli rajzolása még ellenőrizendő.

## Változástörténet

## Aktuális javítás: 0.9.2

A felső HUD most egyetlen, 744 egység széles, közös lila hátterű és aranykeretes panel. A pályanév balra, az óra középen, a kills/gold/cache statok jobbra vannak. A bossikonok, nevek és visszaszámlálások ugyanennek az ablaknak a belsejében futnak, nincs második, külön bekeretezett idővonal-doboz. Az eredeti szárnyas clockfejléc helyét egységes panel és a megtartott középső óracímer vette át. A panel magassága a menetrenddel és aktív boss-életerősávokkal együtt változik.

A külön jobb oldali következő-boss név/timer megszűnt. Az eltárolt szintek és ritka encounter-túlcsordulás rövid jelzése a bal oldali fejlécmezőbe kerülhet, de nem ismétli a boss-idővonal visszaszámlálását.

A minimap zónaneve a térkép felső részén, kétsoros, rendelkezésre álló szélességhez igazított mezőben látszik. A kisebb +/−/x gombok a térkép szélein belül, egymástól elkülönítve vannak; nem lógnak a képernyő jobb szélére. A térkép nézete, óraadata, jelölői, zoom- és visszaállítási logikája megmaradt. A hosszú zónanevek szükség esetén két sorba törhetnek.

A 0.9.2 célzott szimulált ellenőrzése sikeres: egybeépített háttér, dinamikus panelmagasság, eltávolított ismételt timer, beljebb rendezett minimapkontrollok. Élő kliensben még ellenőrizendő. A saját karakterkeret, tükrözött target, party és Action bar e kiadásban változatlan.

## Aktuális javítás: 0.9.1

- A partykártyák nagy fekete/sötét háttérkitöltése átlátszó lett. A helyük, méretük, HP/power sávjaik és kezelőszerveik maradtak.
- A targetkeret valóban tükrözött elrendezést kapott: portré és dísz jobbra, név/HP/power balra. A háttérgrafika is tükrözött, a saját karakterkeret változatlan. A célpont mana/rage/focus/energy sávja csak érvényes natív power és pozitív maximum esetén látszik; resource nélküli célpontnál nem talál ki értéket.
- A targetaurák a playeraurákhoz igazodva 30×30-asak, hét oszlopban, felfelé törve. Legfeljebb 24 target aura jelenik meg, 16 natív buff/debuff hely vizsgálatával mindkét típusnál. A klasszikus unit-aura API hiányzó időtartamát nem pótoljuk kitalált timerrel.
- A régi BuffFrame a minimap mellett rejtett, amíg az effects modul aktív és a native buff API elérhető. Off, effects kikapcsolás és világ elhagyása visszaállítja. A régi buffframe alpha is nullázva van, így a natív OnShow frissítés nem hozza láthatóan vissza.
- A minimap régi pereme, nap/hold kerete, zoom- és zónanév-kerete helyett saját keret, zónanév és arany/lila +/−/x vezérlők vannak. Az eredeti térképet, méretét, jelölőit nem cseréljük. A zoom eredeti Click kezelőt használ, ha elérhető, egyébként a natív zoom API-t. A saját óra AZS_GetLocalTime adata, és csak elérhető saját óraadat esetén vesszük át a natív localClock HUD-részt. A régi díszek visszaállíthatók, a minimap saját szülőjét nem rejtjük el véletlenül.
- A boss-idővonal a felső ablakhoz kapcsolódó, kibővített aranykeretes, lila hátterű panelen van; az élő boss-életerősávok alatta maradnak. A keresztbe tett kard/koponya állapotjelzés megmaradt.
- A jövőbeli bossok számai most folyamatos, a run-óra szerint csökkenő visszaszámlálások. Pause/choosing alatt a játék saját órájával együtt állnak meg. Az ACTIVE és DEFEATED állapot szövegként látszik; a korábbi statikus spawnóra helyett a hátralévő idő kerül a név alá. Lejárt óra önmagában nem tesz legyőzötté egy bosst.
- Induláskor a már betöltött schedule-adatot elfogadja, ha a publikációs bélyeg az aktuális zóna bélyegével azonos vagy újabb. Nem kell új boss-eseményt kivárni pusztán azért, mert a schedule az addon előtt érkezett meg.
- Ha a játék még nem ad aktuális schedule-t, a korábban megfigyelt azonos pálya-/hossz-/lokalizált név szerinti menetrend PLAN jelöléssel használható. Csak neveket, sorszámot és spawnidőket mentünk, legyőzési állapotot nem. Ready állapotban minden bejegyzés tervként jelenik meg. A terv szerinti elmúlt időnél STATE ? látszik, nem kitalált halál. Ha a pályáról nincs friss adat és korábban mentett terv sem, a teljes névlista nem állítható elő: a panel az adat megérkezéséig rejtett marad. A terv egy korábbi megfigyelés, játékfrissítés után eltérhet az aktuális schedule-tól, amit a friss adat lecserél.

A 0.9.1 fájlszerkezeti és szimulált Lua/API ellenőrzése sikeres, de élő kliensben még nincs igazolva. A saját karakterframe és Action bar nem lett újratervezve. A következő szakaszok történeti verzióleírások; eltérés esetén ez a 0.9.1 szakasz irányadó.

## Aktuális kiadás: 0.9.0

Négy célzott változás, az Action bar megjelenésének és működésének megtartásával:

### Kompakt co-op partykeretek

Alaphelyzetük a jobb alsó terület, az alsó HUD mellett: egy csapattárs egy 146×50-es kártya, több csapattárs két oszlopban, legfeljebb két sorban jelenik meg. A vanilla kliens GetNumPartyMembers és party1…party4 unitjait olvassuk, nem egy korábbi meter névsorát. Ez legfeljebb négy társ kezelését jelenti a natív party API-n; nem állítjuk, hogy minden játékverzió co-op maximuma pontosan ugyanennyi. A lobby maximumát nem hitelesítettük.

A kártya név/szint, natív portré, aktuális/max HP és power sáv adatot mutat. OFFLINE/DOWN és az elérhető AZS_GetRevive rshare értékéből REVIVE százalék jelenhet meg. Bal kattintás a natív TargetUnit hívással céloz; /hle unlock után a kártyákon húzva mozgatható. Ha nincs party vagy a futam nem aktív, a saját panel eltűnik. Csak a sikeresen HP-adatot adó, saját kártyával helyettesített PartyMemberFrame rejtődik el. Off, világ elhagyása, modul kikapcsolása, natív mód vagy hiba esetén az eredeti alpha/láthatóság visszaáll. Hiányzó API mellett a natív keretek maradnak.

### Olvasható pénz- és ládaár-kijelzés

A felső bal blokk külön sorba teszi a KILLS-t, alá a GOLD és CACHE értékeket. Ez megoldja az egysoros szöveg túlcsordulását. Ezres, milliós, milliárdos és billiós összegek k/M/B/T rövidítést kapnak; a teljes egész számok egér föléhúzásakor a tooltipben látszanak. A felső mezők eredeti arany/lila stílusa megmarad.

### Boss-idővonal

A felső HUD alá időrendben kerülnek az aktuális pálya AZS_SCHEDULE adatai: spawnidő, név, állapot. A név fölött saját készítésű keresztezett kard ikon látszik a még le nem győzött bossoknál; a state=dead állapotot koponya jelzi. Az ACTIVE és NEXT felirat megkülönbözteti a harcoló és következő bosst. A kijelzett óra a tervezett megjelenési idő, nem történelmi halálozási idő.

Kizárólag az API due/up/dead állapotából dolgozik, nem következtet a boss legyőzésére abból, hogy elmúlt a spawnideje vagy eltűnt a célpont. Új világ/run/pálya vagy jelentős run-óra visszaugrás törli a korábbi idővonalat; friss AZSBOSSES publikációig vagy friss schedule bélyegig a sor rejtett. Reload után kliens-replay nélkül ezért lehet üres. Hat boss fér egy sorba, legfeljebb 30 bejegyzés; a natív boss-életerősávok az idővonal alatt maradnak, nem fedik. A kard/koponya dekoráció nem kattint bossra és nem módosít harci állapotot.

### Minimap megjelenés

Saját arany/lila körkeret, átlátszó középpel. A kliens térképtextúráját, maszkját, méretét, pozícióját, zoomgombjait és jelölőit nem írjuk át; a natív peremdísz alpha értékét ideiglenesen nullázzuk. A saját keret nem fog el egérkattintást. Off, kikapcsolás és világ elhagyása visszaállítja a korábbi peremdísz állapotát. Ismeretlen minimap-API esetén a modul kimarad.

### Beállítások és tesztelés

A /hle ablakban Party frames, Boss timeline, Minimap skin kapcsolók kerültek a listába. Parancsok: /hle party, /hle timeline, /hle minimap. A party pozíciója, a három kapcsoló és a globális skála a profilokkal menthető. Az aurák és action bar változatlan helyen maradnak.

A fájlszerkezeti és célzott szimulált Lua 5.1 tesztek sikeresek. Nem valódi Lua 5.0 interpreter- vagy élő 0.9.0 klienspróba. Külön ellenőrizendő egy co-op futam, partyból ki-/belépés, nagy gold/cache érték, tényleges bossölés és következő pályára lépés, minimapgombok és a kész képernyő elrendezése. A nyilvános 0.8.3-as kiadást ezzel nem cseréltük le automatikusan. Az ajánlóoldalnak az új változat tényleges klienspróbája után érdemes aktuális, jelölés nélküli screenshotot készíteni.

Az alábbi régebbi verzióleírások történeti információk; eltérés esetén ez a 0.9.0 szakasz irányadó.

## Telepítés / frissítés

1. Lépj ki teljesen a játékból.
2. A `HolyLightEclipse-0.9.2.zip` belsejében lévő **HolyLightEclipse** mappát másold a kliens `Interface/AddOns/` mappájába. Ha az AddOns nem létezik, létrehozható.
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
