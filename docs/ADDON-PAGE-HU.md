# Holy Light × Eclipse

Arany–lila HUD Azeroth Survivorshez, áttekinthető harci információkkal és kompakt képességsávval.

**Készítő:** Rehard  
**Verzió:** 0.8.3 · **Kategória:** HUD & interface · **Beállítások:** `/hle`

## Bemutató

A Holy Light × Eclipse a játékos és célpont adatait, a képességek cooldownját, a futamstatisztikákat, lootértesítéseket és guardianokat közös megjelenésbe fogja össze. Paladin ihletésű arany kereteket és lila részleteket használ, a harctér közepét szabadon hagyva.

## Fő funkciók

- HP, power, XP, támogatott absorb, target HP és szint.
- Az aktuális futam képességei és cooldownjai; új futamnál a régi képességkijelzés törlődik.
- Buffok/debuffok a játékos és target kerete fölött, támogatott summon- és talentidőzítőkkel.
- Futamidő, következő boss, kills, arany és ládaár.
- Kicsi, mozgatható RUN/BOSS/HEAL mérőablak.
- Saját enemy nameplate-ek HP-százalékkal és elérhető szintadattal.
- Equipment panel natív tooltippekkel és külön jelölt, teljes futamra érvényes statokkal.
- Elit/guardian ablak az equipment fölött: pályánként kiolvasott nevek, állapot és a játék által jelentett respawnidő, nyilak nélkül.
- Aktuális run-ékszerek, legfeljebb 200 valóban megfigyelt tárgy naplója.
- Saját stílusú lootkártyák, beállításablak, méretezés és három elrendezési profil.

## Telepítés

A HolyLightEclipse-0.8.3.zip csomagból a HolyLightEclipse mappát másold a játék AddOns könyvtárába. A pontos helyet a játék Open AddOns Folder menüpontjával keresd meg, ha elérhető. Interface-alapú telepítésnél: `Interface/AddOns/HolyLightEclipse/HolyLightEclipse.toc`.

Frissítéskor kilépett játék mellett cseréld le az addonmappát, majd indítsd újra a klienst. Más teljes HUD-cserét ne futtass vele együtt. Beállítások: `/hle`, mozgatás: `/hle unlock`, lezárás: `/hle lock`.

## Ellenőrzés és korlátok

A 0.8.3-at a felhasználó kipróbálta, és 2026. november 4-én megfelelőnek találta a saját környezetében. Ez nem minden funkcióra, kasztra és platformra kiterjedő tanúsítás; a pontos játékbuild nincs rögzítve. A fájlszerkezeti és szimulált Lua/API tesztek sikeresek. A közelmúltbeli tesztelés Paladinra összpontosult; böngészős működés nincs igazolva.

Az opcionális kijelzések az API-tól függenek. A guardianlista nem az összes kóborló elitet listázza. Hiányzó respawnidőt vagy egyedi tárgystatot nem talál ki. A szintlépési választókártyák megjelenése változatlan. Független közösségi addon, nem hivatalos játék- vagy Blizzard-termék.
