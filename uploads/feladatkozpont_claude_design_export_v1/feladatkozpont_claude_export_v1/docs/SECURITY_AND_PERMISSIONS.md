# Biztonság és jogosultság

## Alapvető döntés

A kártyák láthatóságát nem a frontend dönti el.
A frontend csak azokat a kártyákat kapja meg, amiket az adott user jogosult látni.

## Jogosultsági szintek

- saját feladat
- csapat feladatai
- minden jogosult feladat
- modul alapú jogosultság
- source_module alapú jogosultság
- cég / partner / projekt alapú jogosultság
- vezetői / admin jog

## Javasolt Supabase megközelítés

- `task_center.board_members` tartalmazza, ki melyik boardhoz fér hozzá
- `task_center.task_assignments` tartalmazhat több felelőst / watchert
- `task_center.v_user_visible_cards` vagy RPC adja vissza a usernek látható taskokat
- RLS védi a task táblát
- admin / service role generálhat automatán taskot

## Audit

Minden fontos műveletből legyen event:

- create
- update
- status_change
- assign
- comment
- checklist_update
- open_source
- queue_agent
- notification_sent

