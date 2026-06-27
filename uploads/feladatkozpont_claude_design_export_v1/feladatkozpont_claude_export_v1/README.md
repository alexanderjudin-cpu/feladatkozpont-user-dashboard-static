# Feladatközpont User Dashboard — Claude Design Export

Ez a csomag a különálló Feladatközpont / User Dashboard teljes design + Supabase + integration handoff exportja.

A cél: Claude Design / Claude Code / más frontend designer ebből önállóan értse, hogy mit kell továbbtervezni és milyen backend-contract szerint kell működnie.

## Aktuális live helyek

- GitHub repo: https://github.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static
- GitHub Pages dashboard: https://alexanderjudin-cpu.github.io/feladatkozpont-user-dashboard-static/
- Aktuális live HTML: https://github.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static/blob/main/index.html
- Raw HTML: https://raw.githubusercontent.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static/main/index.html

## Fontos architektúra

Ez NEM a meglévő Retool fő app része.
Ez különálló dashboard / külön app / külön link.
A fő Retool appból később sima linkkel vagy iframe/postMessage bridge-dzsel lehet megnyitni.

## Mit tartalmaz a csomag

- frontend/index.local_snapshot.html — lokális HTML snapshot a dashboardból
- supabase/task_center_schema.sql — javasolt Supabase schema
- supabase/task_center_seed.sql — demo seed adatok
- contracts/task_card_contract.json — task card adatmodell
- contracts/user_contract.json — user / board member modell
- contracts/postmessage_events.json — frontend/Retool/Supabase bridge események
- docs/PROJECT_BRIEF.md — projekt rövid összefoglaló
- docs/UI_UX_REQUIREMENTS.md — design és UX követelmények
- docs/BACKEND_INTEGRATION.md — backend bekötés logika
- docs/SECURITY_AND_PERMISSIONS.md — jogosultsági logika
- prompts/CLAUDE_DESIGN_PROMPT.md — Claude-nak bemásolható teljes prompt

## Jelenlegi frontend funkciók

- Trello-szerű kanban board
- kártya kattintás
- drag & drop oszlopok között
- jobb oldali részletező panel
- új feladat modal
- kártya szerkesztés
- checklist
- komment / activity log mintaszinten
- szűrők
- naptár nézet
- automatizmusok placeholder
- beállítások placeholder
- user monogram / board members / online állapot placeholder
- AI / agent bekötési pontok
- postMessage bridge előkészítés

## Amit Claude-nak kell továbbgondolnia

A UI legyen luxi, profi, gyors, Trello/Monday/Jira minőségű, de light enterprise Retool-szerű narancs-fehér stílussal.
Ne legyen IT-specifikus. Ez az alap user nézet minden modul fölött.
