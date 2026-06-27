# HTML komponens követelmények

## Kötelező komponensek

1. `TopBar`
   - title
   - global search
   - filter button
   - new task button
   - notification bell
   - AI quick filter
   - board member monogram stack

2. `BoardTabs`
   - Saját nézet
   - Csapat
   - Minden jogosult
   - Naptár
   - Automatizmusok
   - Beállítások

3. `StatsBar`
   - Nyitott
   - Folyamatban
   - Kritikus
   - AI javaslat

4. `KanbanBoard`
   - 5 columns
   - virtualized / efficient rendering preferred
   - drag & drop
   - add card per column

5. `TaskCard`
   - title
   - status/priority/module chips
   - due date
   - checklist stats
   - assignee monogram
   - progress bar
   - quick menu

6. `TaskDetailPanel`
   - details
   - checklist
   - comments as card comments only
   - activity
   - AI/agent panel

7. `UserPresenceDrawer`
   - board members
   - role
   - online/offline
   - click to filter tasks by user

8. `FilterDrawer`
   - module
   - priority
   - user
   - AI only
   - hide done

9. `NotificationDrawer`
   - task notifications only
   - no chat/messages module

10. `TaskModal`
   - create/edit task

## UX elvárás

- Minden kattinthatónak látszó elem kattintható legyen.
- Hover, active, selected állapotok legyenek.
- Gyors render: max pár száz taskig simán menjen.
- Ha nincs Supabase config, sample data fallback legyen.
- Ha van Supabase config, live adatok menjenek.
