# Security és jogosultság

## Alapszabály

A dashboard csak azokat a taskokat mutathatja, amelyekhez a user jogosult.

## Javasolt jogosultsági modell

- `task_center.boards`: board definíciók.
- `task_center.user_profiles`: user display adatok.
- `task_center.board_members`: board tagság / role.
- `task_center.task_cards`: taskok.
- `task_center.task_watchers`: extra láthatóság.

## Láthatóság

Egy user láthat egy taskot, ha:

1. ő a felelős (`assignee_user_id = auth.uid()`), vagy
2. ő hozta létre (`created_by_user_id = auth.uid()`), vagy
3. aktív board member az adott boardon, és a task nem private, vagy
4. explicit watcher, vagy
5. admin/manager role-ja van a boardon.

## AI agent szabály

Az AI agent:

- olvashat source contextet,
- javasolhat checklistet,
- készíthet summary-t,
- előkészíthet emailt/actiont,
- de éles üzleti rekordot nem írhat jóváhagyás nélkül.

## Frontend secrets

- `SUPABASE_URL` publikus lehet.
- `SUPABASE_ANON_KEY` publikus lehet RLS mellett.
- `SERVICE_ROLE_KEY` soha nem kerülhet HTML-be.
