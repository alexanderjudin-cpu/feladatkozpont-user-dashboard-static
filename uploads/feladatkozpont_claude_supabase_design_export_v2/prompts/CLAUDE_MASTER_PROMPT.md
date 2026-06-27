# Claude prompt — Feladatközpont Supabase-connected HTML design

You are designing a premium, fast, standalone HTML/CSS/JS user dashboard called **Feladatközpont / User Dashboard**.

The dashboard will be hosted as a static HTML app on GitHub Pages and later connected to Supabase live data. It is a separate app, not embedded into the existing Retool app for now.

Current live dashboard:
https://alexanderjudin-cpu.github.io/feladatkozpont-user-dashboard-static/

Current GitHub repo:
https://github.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static

Raw latest HTML:
https://raw.githubusercontent.com/alexanderjudin-cpu/feladatkozpont-user-dashboard-static/main/index.html

## Product goal

Build a Trello/Monday/Jira-quality internal command center where each user sees the tasks/cases/actions they are allowed to see. Cards are generated from multiple business modules and later from AI agents / automations.

This is **not IT-specific**. Do not use IT wording. Use generic placeholders only.

## Required UX

- Light enterprise UI, white/light gray surfaces, HDD-style orange accent.
- Trello-like kanban board with smooth drag & drop.
- Board/list/calendar/automation/settings views.
- Every visible element should be clickable if it looks clickable.
- The top navigation tabs must actually change views.
- Top-right user monogram stack should show board members / authorized users, like Trello.
- Remove any chat/messages icon or messaging area for now.
- Keep notification bell for task alerts only.
- Cards must open a detail panel.
- Cards must have quick menu, status, priority, assignee, due date, source link, checklist progress, tags, AI state.
- Detail panel must include editable fields, checklist, activity, comments as card comments only, and AI/agent actions.
- The design must be very fast: avoid heavy dependencies. Vanilla JS is preferred; Supabase client can be loaded later via CDN if needed.

## Backend contract

Use the provided files:

- `docs/UI_FIELD_MAP_FOR_HTML.md`
- `supabase/task_center_schema_v2.sql`
- `contracts/task_card_contract.json`
- `contracts/user_contract.json`
- `contracts/postmessage_events.json`
- `examples/sample_tasks.json`
- `examples/sample_users.json`

## Output required from Claude

Return a full replaceable frontend proposal. Ideally:

1. `index.html` complete single file, or cleanly separated `index.html`, `styles.css`, `app.js`.
2. Every field in the UI must correspond to the Supabase mapping in `UI_FIELD_MAP_FOR_HTML.md`.
3. Include a `CONFIG` section where `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `BOARD_KEY` can later be inserted.
4. Include graceful fallback to sample data if Supabase is not configured.
5. Include functions for all CRUD actions, but allow them to run in placeholder/local mode until Supabase is enabled.
6. Do not include real secrets. No service role key in frontend.
7. Preserve Hungarian UI labels.

## Important integration rule

Static GitHub Pages frontend can only use Supabase anon key + RLS or communicate with Retool/edge functions. Never put service_role key into HTML.
