# Feladatközpont / User Dashboard — Claude Supabase Design Export v2

Dátum: 2026-06-27

Ez a csomag Claude Design / Claude Code számára készült. A cél, hogy a **különálló Feladatközpont user dashboard** HTML mezőit és működését úgy tudja továbbtervezni, hogy később Supabase live adatokra köthető legyen.

## Legfontosabb döntés

Ez **NEM IT dashboard** és **NEM a meglévő Retool fő app része**. Ez egy különálló, linkkel elérhető, önálló dashboard / user command center.

A fő appból később egyszerű hivatkozással, vagy iframe + postMessage bridge-dzsel lehet megnyitni.

## Aktuális live helyek

- GitHub repo: https://github.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static
- Live dashboard: https://alexanderjudin-cpu.github.io/feladatkozpont-user-dashboard-static/
- Raw live `index.html`: https://raw.githubusercontent.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static/main/index.html
- Utolsó releváns commit: https://github.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static/commit/11d96d487a36e9c8d554084e8ca11b152fd5325d

## Fontos Claude-nak

1. A Trello képből csak a működési logikát kell átvenni: board, oszlopok, kártyák, user monogramok, gyors interakciók.
2. A korábbi képen szereplő szövegek nem relevánsak.
3. Ne legyen IT-specifikus szöveg.
4. Ne legyen külön üzenetek / chat rész egyelőre.
5. Értesítés ikon maradhat, mert feladatértesítések később kellenek.
6. A jobb felső user monogram stack a boardhoz tartozó jogosult felhasználókat mutassa, Trello-szerűen.
7. A UI legyen prémium, gyors, könnyű, light enterprise, narancs-fehér, Retool-kompatibilis hangulatú.
8. A HTML mezők legyenek tisztán köthetők Supabase oszlopokhoz.

## Csomag tartalma

- `prompts/CLAUDE_MASTER_PROMPT.md` — ezt add be Claude-nak elsőként.
- `docs/UI_FIELD_MAP_FOR_HTML.md` — minden HTML mező és Supabase mapping.
- `docs/PROJECT_CONTEXT_LATEST.md` — legfrissebb projektkontextus.
- `supabase/task_center_schema_v2.sql` — javasolt Supabase séma.
- `supabase/rls_policies_draft.sql` — RLS / jogosultsági draft.
- `contracts/*.json` — adatcontractok a frontendhez.
- `examples/*.json` — demo task/user/board payloadok.
- `frontend/LIVE_HTML_REFERENCE.md` — aktuális HTML linkek.
- `retool/retool_bridge_snippets.js` — bridge minta Retoolhoz.
- `docs/SECURITY_AND_PERMISSIONS.md` — auth/jogosultság logika.
