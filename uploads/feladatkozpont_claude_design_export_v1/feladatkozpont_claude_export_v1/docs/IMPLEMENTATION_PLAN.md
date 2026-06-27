# Implementációs terv

## Fázis 1 — Standalone design véglegesítés

- HTML/CSS/JS tisztítás
- Komponens-szerű struktúra
- User presence végleges UI
- Board/card/detail UX finomítás
- Naptár/Automatizmusok/Beállítások oldalak jobb placeholder UX
- Accessibility és keyboard shortcuts

## Fázis 2 — Supabase read-only bekötés

- task_center schema teszt adatbázisban
- v_task_cards_frontend view
- board_members view
- frontend kapjon tasks/users listát
- először csak read-only

## Fázis 3 — Supabase write bekötés

- move_task RPC
- upsert_task_from_source RPC
- update field RPC
- comments/checklist RPC
- optimistic UI
- audit events

## Fázis 4 — Realtime

- Supabase Realtime task_cards
- Realtime board_members presence
- live frissítés userenként

## Fázis 5 — Agent és notification

- queue_agent_job RPC
- task_notifications outbox
- agent output visszaírás task eventként
- AI javaslatok kontrollált jóváhagyása

## Fázis 6 — Jogosultság

- RLS
- board_members permission_level
- user-visible card RPC/view
- source_module alapú jog
