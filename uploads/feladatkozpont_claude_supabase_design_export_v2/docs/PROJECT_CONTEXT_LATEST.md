# Legfrissebb projektkontextus

## Rendszer

A teljes projekt Retool Classic + Supabase/PostgreSQL alapú belső ERP/CRM rendszer. A user kéri, hogy kódos/SQL/Retool/JS/CSS/Git feladatoknál mindig teljes, egyben cserélhető kód legyen, ne patch-részlet.

## Aktuális döntés a Feladatközpontról

- Ez az alap user nézet / központi Feladatközpont.
- Nem IT dashboard.
- Nem a meglévő Retool fő appba kerül modulnak.
- Teljesen különálló dashboard legyen, külön linkkel / külön appként.
- Később beköthető legyen a fő appból, Retoolból, Supabase-ből, AI agentekből és notification outboxból.
- A Trello-s screenshotból csak a layout/logika fontos: board, kártyák, user avatar/monogram, gyors kezelés.
- Az üzenetek/chat rész nem kell egyelőre.
- A jobb felső monogramok később a jogosult user profile-okból jönnek.

## Kapcsolódó modulok, amelyekből később kártyák jönnek

- UAHUN ügyek / workflow cases.
- P01 Planned Personnel.
- P02 Actual Started Working.
- Fülöp pipeline / új belépők.
- Szállás modul, főleg legacy szállás provider/address/stay problémák.
- Állományi dashboard / kontroll dashboard.
- Dokumentumok / OIF / EH műveletek.
- Napi Drive / service cases.
- Lejáratfigyelők, hiányzó adat, jóváhagyás, partner follow-up.
- AI agent által előkészített vagy javasolt feladatok.

## Szállás modul releváns kontextus

A szállás modulban sok legacy adat és provider/address/stay logika van. Példák későbbi task generálásra:

- Szálláscím ár nélkül.
- Szállásadó / cím módosítás ellenőrzése.
- Soft delete után history megjelenítés.
- Hiányzó nettó ár / ártípus / férőhely.
- Munkavállaló költözés, kiköltözés, hozzátartozó figyelmeztetés.
- Legacy provider/address view problémák.

## UAHUN / HR adatmodell releváns kontextus

A core workflow logika:

- `planned.planned_personnel` = P01 planned source.
- `actual.started_working` / assignments = P02 actual source.
- `uahun.workflow_cases` / `public.workflow_cases` = ügykezelés.
- Új belépőnél P01 az erősebb forrás, hosszabbításnál / már dolgozóknál P02 az erősebb.
- AI agent csak javasolhat / előkészíthet, éles adatot ne írjon jóváhagyás nélkül.

## Dashboard jelenlegi live állapot

A live dashboard jelenleg GitHub Pages-en fut. Már van:

- kattintható top tabok;
- saját / csapat / minden jogosult nézet;
- board/list/calendar/automation/settings;
- kártya drag & drop;
- detail panel;
- checklist, comment, activity;
- user monogram stack;
- board members drawer;
- user szűrés;
- AI gyorsnézet / agent placeholder;
- postMessage bridge előkészítés.
