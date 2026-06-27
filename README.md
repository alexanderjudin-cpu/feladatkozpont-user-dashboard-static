# Feladatközpont / User Dashboard — Claude Supabase Design Export v2

Dátum: 2026-06-27

Ez a csomag Claude Design / Claude Code számára készült. A cél, hogy a különálló Feladatközpont user dashboard HTML mezőit és működését úgy tudja továbbtervezni, hogy később Supabase live adatokra köthető legyen.

## Fontos döntés

Ez NEM IT dashboard és NEM a meglévő Retool fő app része. Ez egy különálló, linkkel elérhető, önálló dashboard / user command center.

A fő appból később egyszerű hivatkozással, vagy iframe + postMessage bridge-dzsel lehet megnyitni.

## Aktuális live helyek

- GitHub repo: https://github.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static
- Live dashboard: https://alexanderjudin-cpu.github.io/feladatkozpont-user-dashboard-static/
- Raw live index.html: https://raw.githubusercontent.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static/main/index.html

## Mit tartalmaz

- docs: projekt kontextus, UI mező map, backend integráció, jogosultságok
- supabase: task_center schema, RLS draft, seed
- contracts: task card, user, board config, postMessage event szerződések
- examples: sample task/user/board config JSON
- frontend: referencia HTML snapshot
- retool: bridge snippet
- prompts: Claude master prompt
