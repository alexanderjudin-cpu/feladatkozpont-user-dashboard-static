# Feladatkozpont User Dashboard

Kulonallo, interaktiv user dashboard frontend.

Nem IT dashboard, nem UAHUN modul, nem szallas modul. Ez az alap user nezet, amelybe kesobb barmilyen rendszeresemeny, case, ertesites, jovahagyas, agent feladat vagy Supabase rekord bekotheto.

Funkciok:

- Kanban board
- Drag and drop kartya mozgatasa
- Kattinthato kartyak
- Jobb oldali detail panel
- Szerkeszto modal
- Checklist
- Kommentek
- Activity log
- Szurok
- Ertesitesi drawer
- Listanezet
- Bulk kijeloles es bulk statuszvaltas
- AI es agent bekotesi pont
- Retool / Supabase postMessage bridge elokeszites

GitHub Pages beallitas:

Settings / Pages / Deploy from branch / main / root

Varhato URL:
https://alexanderjudin-cpu.github.io/feladatkozpont-user-dashboard-static/

Kesobbi live bekoteshez az app fogad task listat a parent ablakbol task_center_set_tasks tipussal, es visszakuld esemenyeket, peldaul task_center_select, task_center_status_change, task_center_create_task, task_center_comment, task_center_notify, task_center_open_source es task_center_queue_agent.
