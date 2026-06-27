# Backend integration terv

## Két támogatott bekötési mód

### A) Retool bridge mód

A dashboard lehet külön link vagy iframe. Retool küldi be a taskokat és user listát `postMessage`-gel. A dashboard visszaküldi az eseményeket, Retool pedig Supabase query/RPC hívással elvégzi a műveletet.

Előny: Retool meglévő auth/jogosultság használható.

### B) Direkt Supabase mód

A dashboard GitHub Pages statikus appként közvetlenül csatlakozik Supabase-hez anon key + RLS-sel.

Előny: gyors, live realtime működés.

Fontos: service_role key soha nem kerülhet frontendbe.

## Live data flow

1. User megnyitja dashboardot.
2. Frontend betölti a board configot és a user profile-t.
3. Frontend lekéri `task_center.v_user_task_cards` view-t.
4. Frontend lekéri `task_center.v_board_members` view-t.
5. Realtime subscription figyeli:
   - `task_cards`
   - `task_checklist_items`
   - `task_events`
   - `task_notifications`
   - `agent_jobs`
6. User művelet RPC-n keresztül történik.
7. Minden művelet audit eventet generál.

## Source rekord nyitás

A task card `source_url` vagy `metadata.retool_route` alapján a dashboard képes visszanyitni a forrásrekordot Retoolban / más appban.

Példa `source_url`:

```text
retool://uahun/workflow_cases/<uuid>
https://retool.company.local/apps/uahun?case_id=<uuid>
```
