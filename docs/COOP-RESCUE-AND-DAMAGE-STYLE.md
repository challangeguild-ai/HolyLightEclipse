# Co-op mentési irányjelző és sebzésszínezés – fejlesztési ág

Ez a leírás a **Holy Light × Eclipse 0.9.5** kiadásából indított fejlesztési ágra vonatkozik. A 0.9.5-ös letölthető release **még nem tartalmazza** a funkciókat.

## Co-op mentési jelzés

- Alapból engedélyezve, a `/hle` beállítóablakban **Rescue guidance** kapcsolóval, vagy `/hle rescue` paranccsal ki-be kapcsolható.
- Újonnan elesett csapattársnál egy egyszeri szöveges és (ha a kliens kezeli) hangos riasztás történik.
- Amíg valaki elesett, egy kompakt panel mutatja a nevét. Egyszerre több halottnál az aktuálisan legközelebbi, érvényes pozíciójú társ felé irányít, a többi társ számát jelzi.
- Ha a játék szolgáltatja az `AZS_GetDownedPartyMembers()` és `AZS_GetPlayerPosition()` eredményét, az iránynyíl a játékos pillanatnyi **nézési irányához képest** nyolc irányba mutat. A távolság **yardban (yd)** van, egyenes vonalú – nem útvonalhossz.
- Az adatokat csak egyező `runId`, `spaceId` és `mapId` mellett használja; a nulla koordináták érvényesek. A játék natív újraélesztési pozícióját követi, nem a holttest képi helyét vagy korábban eltárolt koordinátát.
- Ha a pontos pozíció vagy a nézési irány nem áll rendelkezésre, a haláleseti figyelmeztetés megmarad, de a **nyíl rejtve marad**. Régi kliensben, ahol nincs `AZS_GetDownedPartyMembers()`, a natív `party1…party4` egységekből csak az elesés tényét figyeli.
- Újraélesztéskor, kilépéskor, új futam vagy pálya kezdetekor, illetve az addon letiltásakor törli a jelzést.
- A képernyőn jelen lévő nyíl **nem** mozgatja automatikusan a karaktert, nem készít navigálható útvonalat, és nem igazolja a falakon/akadályokon át való megközelíthetőséget.

## Sebzésszámok

- Normál sebzés: **fehér** `(1,1,1)`, 16-os méret.
- Kritikus sebzés: **sárga** `(1,0.88,0.16)`, 22-es méret és `!` jel.
- A kritikus jelző elfogadott értékei: Lua `true` vagy numerikus `1`; a numerikus `0` **nem** számít kritikusnak.
- Az eddigi kimenő combat text kapcsoló megmarad: `/hle damage`. Az egyedi számok csak a natív projekciós API megléte esetén működnek, a beépített szövegek biztonságos átvételével.

## Élő ellenőrzés a játékban

1. Co-op futam indítása 2+ játékossal; először mindenki él – mentési panel ne legyen.
2. Egy csapattárs elesik – egyszeri riasztás, név, irány és távolság.
3. A játékos elfordul, majd megindul a társ felé – az irány frissüljön, a távolság csökkenjen.
4. Újraélesztés – a panel tűnjön el; újabb halálnál újabb, de nem ismétlődő riasztás.
5. Két halott társ, pályaváltás, pause/choice, kilépés, régebbi API – nincs szellemnyíl és nincs hamis helymeghatározás.
6. Normál találat fehér, kritikus sárga; `/hle damage` ki-/bekapcsolása után is.

**Státusz:** forráskódban beépítve; a valós Azeroth Survivors kliensben és különösen a co-op esetekben még nincs ellenőrizve.
