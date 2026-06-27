# Később bekötendő modulok és task generálási példák

## UAHUN ügyek

Példa taskok:
- Új case létrejött.
- Hiányzó dokumentum.
- Határidő közeleg.
- Jóváhagyás szükséges.
- AI summary elkészült.

Javasolt source:
- `module_key = 'uahun'`
- `source_schema = 'uahun' vagy 'public'`
- `source_table = 'workflow_cases'`
- `source_pk = workflow_case_id`

## P01 Planned Personnel

Példa taskok:
- P01 → P02 átemelés ellenőrzése.
- Hiányzó partner / FEOR / belépési adat.
- Tesztalany promotion queue.

## P02 Actual Started

Példa taskok:
- Dolgozó tényleges kezdés frissítés.
- Jogviszony kezdete/vége eltérés.
- Hosszabbítás ellenőrzése.

## Szállás modul

Példa taskok:
- Ár nélküli cím.
- Partner/cím hiányzó adat.
- Költözés ellenőrzése.
- Hozzátartozóval kapcsolt figyelmeztetés.
- Legacy provider/address állapot ellenőrzés.

## Dokumentumok / OIF / EH

Példa taskok:
- Dokumentum hiányzik.
- Beküldésre vár.
- Válasz érkezett.
- Határidős ügy.

## Állomány / kontroll dashboard

Példa taskok:
- Eltérés kontroll view-ban.
- Hiányzó státusz.
- Lejárt vagy közelgő dátum.

## AI agent

Példa taskok:
- AI javaslat készült.
- AI ellenőrzőlista generálva.
- Agent hiba történt.
- Agent eredmény jóváhagyásra vár.
