# Rendszerarchitektúra – Áttekintés
> 🇬🇧 English version:
> [System Architecture Overview](README.md)

Ez a dokumentum a rendszer magas szintű architektúráját és alapelveit írja le. A cél egy **determininsztikus, auditálható és verziókövetett játékrendszer**, ahol az on-chain és off-chain komponensek ugyanazon, nyilvánosan ellenőrizhető szabályrendszerre támaszkodnak.

---

## Alaparchitektúra

A rendszer **öt, egymástól elkülönített fő komponensből** áll, amelyek mindegyike jól definiált felelősségi körrel rendelkezik.

### 1. Verziókövetett tartalom-adatbázis

Egy verziókövetett, nyilvános adatforrás, amely a rendszer **szabályait és tartalmát** definiálja.

* Biztosítja a játékszabályok és tartalom **validálható, auditálható bővítését**
* Minden módosítás verziózott és publikálás után változtathatatlan
* Egyetlen hiteles forrásként szolgál az egész rendszer számára

Ez a megközelítés lehetővé teszi a rendszer fejlődését anélkül, hogy a korábbi játékmenetek determinisztikussága sérülne.

---

### 2. On-chain állapotkezelés (okosszerződések)

Az okosszerződések felelősek **minden on-chain állapotváltozásért**, kizárólag az **aktuálisan érvényes content verzióra** támaszkodva.

* Nincs hardcode-olt játékmenet-logika
* A viselkedés a verziózott tartalomból kerül levezetésre
* Az on-chain eredmények visszavezethetők és reprodukálhatók

---

### 3. Verziókövetett szabályértelmező (off-chain)

Egy verziókövetett off-chain kódbázis, amely a játékmeneteket az **aktuális content verzió alapján** értelmezi és felügyeli.

* Determinisztikus szabályértelmezőként működik
* Felügyeli az off-chain játékmenet-folyamatokat
* Biztosítja, hogy a játékos-akciók összhangban legyenek az on-chain szabályokkal

Ez a komponens hidat képez a valós idejű játékmenet és az on-chain determinisztikus működés között.

---

### 4. Nyilvános játékmenet-adatbázis

Egy nyilvános, csak bővíthető (append-only) adatbázis, amely a **validált játékos-akciókat** tárolja.

* Minden akciót a szabályértelmező validál
* Szigorúan felügyelt hozzáférés és módosítás
* Lehetővé teszi bármely játék teljes visszajátszását és auditálását

Ez az adatbázis a játékmenetek **nyilvános történeti lenyomata**.

---

### 5. Autoritált tranzakciós végpont

Egy engedélyezett réteg, amely a **jutalmak átvételének jogosultságát** ellenőrzi.

* A nyilvános játékmenet-adatbázis alapján validálja a jutalomigénylést
* Felügyeli az autoritált on-chain tranzakciókat
* Külső feltételeket is ellenőriz:

  * avatárnevek
  * közösségi irányelveknek való megfelelés

Csak **bizonyíthatóan érvényes játékmenet** alapján lehet jutalmat igényelni.

---

## GameContent Contract (központi elem)

A **GameContent contract** a rendszer legfontosabb komponense.

Feladata, hogy a teljes játékrendszer **szabályait és tartalmát nyilvánosan verziókövetett, bővíthető adatszerkezetre** alapozza.

### Fő felelősségek

* Az aktuálisan érvényes content kivonatolt tárolása
* Hash-alapú verziókövetés biztosítása
* Alap biztosítása egy később bevezetésre kerülő audit kódbázis számára

Hatékonysági okokból a contract nem a teljes tartalmat, hanem csak az on-chain működéshez szükséges adatokat tárolja.

---

### Audit kódbázis (későbbi fázis)

Egy későbbi fázisban bevezetésre kerül egy **hash-alapon verziózott audit kódbázis**, amelyet a GameContent contract referenciál.

* Reducer-szerűen működik
* A játékos-akciókat az alábbiak alapján validálja:

  * aktuális content verzió
  * a játékban részt vevő, játékosok által birtokolt NFT-k
* Az érvényes akciókat a nyilvános játékmenet-adatbázisba rögzíti

---

## Jutalmazás és jogosultság

* A játékok győztesei **jogosultságot szereznek** a jutalmak átvételére
* A jutalmak autoritált on-chain tranzakcióval vehetők át
* A jogosultság kizárólag validált játékmenetekből származhat

Nincs diszkrecionális jutalomkiosztás.

---

## Eszközkeletkezési források

A rendszerben keletkező NFT-k és tokenek több forrásból származhatnak (nem csak ládákból):

### 1. Sikertelen fejlesztések

* Bizonyos sikertelen upgrade-ek speciális erőforrásokat eredményezhetnek
* A kudarc is szabályozott, értelmezett kimenetel

---

### 2. NPC-alapú kereskedelem (GameNPC contract)

* Véletlenszerűen váltakozó, limitált kínálattal rendelkező NPC-k
* On-chain felügyelt, játékon belüli kereskedelem
* Idő- és szabályfüggő elérhetőség

---

### 3. Játékos piactér (GameMarket contract)

* Játékosok közötti közvetlen kereskedelem
* Támogatott fizetőeszközök:

  * utility token
  * Flow token
* Külső, indexelt adatbázissal támogatott kereshetőség

A piactér **nem letétkezelő**, és szabályvezérelt.

---

## NFT modell

A rendszer **három NFT típust** definiál, amelyek közös interfészt valósítanak meg.

* A `category` és `type` mezők határozzák meg az NFT belső adatstruktúráját és viselkedését
* Az NFT-k viselkedése egy nyilvános, verziókövetett adatbázisban van definiálva

### NFT típusok

#### BaseNFT

* Fejlesztéshez és craftoláshoz szükséges erőforrások

#### MetaNFT

* Fejleszthető NFT-k különböző szerepekkel és funkciókkal
* A játékmenet alapvető elemei

#### PackNFT

* Tárolást, rendezést és egységként kezelést támogató NFT-k
* Inventórió- és kereskedelem-optimalizálási célokra

---

## Tervezési alapelvek

* Determinizmus a kényelem helyett
* Verifikálhatóság a bizalom helyett
* Verziózott evolúció a módosítható szabályok helyett
* Hatáskörök szigorú szétválasztása

Ez az architektúra biztosítja, hogy **minden lényeges játékeredmény függetlenül ellenőrizhető**, on-chain és off-chain egyaránt.
