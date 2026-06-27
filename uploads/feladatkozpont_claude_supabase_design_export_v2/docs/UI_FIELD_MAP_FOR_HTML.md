# HTML mezők és Supabase mapping

Ez a legfontosabb fájl Claude-nak. A cél, hogy a HTML UI mezői pontosan köthetők legyenek Supabase oszlopokra.

## 1. Topbar mezők

| UI elem | HTML ID/javasolt ID | Supabase / adatforrás | Leírás |
|---|---|---|---|
| Dashboard cím | `appTitle` | statikus config `board.title` | Feladatközpont / User Dashboard |
| Kereső | `searchInput` | kliensoldali filter a `v_user_task_cards` adaton | Cím, forrás, tag, assignee keresés |
| Szűrők gomb | `filterBtn` | kliens állapot + query param | Drawer nyitása |
| Új feladat | `newTaskBtn` | RPC `task_center.create_task_card` | Új task létrehozás |
| Értesítés bell | `notificationBtn` | `task_center.notifications` | Feladatértesítések, nem chat |
| AI gyorsgomb | `quickAiBtn` | `task_center.agent_jobs` / filter `ai_state` | AI státuszú kártyák |
| User monogram stack | `boardMembersStack` | `task_center.v_board_members` | Jogosult board tagok monogramjai |

## 2. User / board member mezők

| UI elem | Contract mező | Supabase oszlop |
|---|---|---|
| User ID | `id` | `task_center.board_members.user_id` / `auth.users.id` |
| Teljes név | `name` | `task_center.user_profiles.display_name` |
| Monogram | `initials` | `task_center.user_profiles.initials` |
| Szín | `color` | `task_center.user_profiles.avatar_color` |
| Role | `role` | `task_center.board_members.role_key` |
| Online | `online` | realtime presence / fallback false |
| Jogosult-e | `can_view_board` | RLS / board_members active row |

## 3. Fő tabok

| Tab | UI állapot | Query |
|---|---|---|
| Saját nézet | `view=mine` | `assignee_user_id = auth.uid()` |
| Csapat | `view=team` | user team/role alapján board_members |
| Minden jogosult | `view=all` | RLS szerint minden látható task |
| Naptár | `view=calendar` | `due_at` alapú csoportosítás |
| Automatizmusok | `view=automations` | `task_center.automations` |
| Beállítások | `view=settings` | board config / user preferences |

## 4. Kanban oszlopok

| UI oszlop | `status_key` | Supabase |
|---|---|---|
| Új | `new` | `task_center.task_cards.status_key` |
| Folyamatban | `in_progress` | ugyanaz |
| Jóváhagyásra vár | `waiting` vagy `approval_wait` | ugyanaz |
| AI előkészítés | `ai_preparing` | ugyanaz |
| Kész | `done` | ugyanaz |

Claude használjon egységes kulcsot: javasolt `waiting` a frontendben, de SQL-ben lehet `approval_wait`. A mapping legyen explicit.

## 5. Kártya mezők

| UI mező | Contract mező | Supabase oszlop | Szerkeszthető? |
|---|---|---|---|
| Kártya ID | `task_id` | `task_cards.task_id` | nem |
| Cím | `title` | `task_cards.title` | igen |
| Leírás | `description` | `task_cards.description` | igen |
| Státusz | `status_key` | `task_cards.status_key` | igen |
| Prioritás | `priority_key` | `task_cards.priority_key` | igen |
| Modul badge | `module_key`, `module_label` | `task_cards.module_key`, `module_label` | részben |
| Forrás típus | `source_type` | `task_cards.source_type` | nem / advanced |
| Forrás schema | `source_schema` | `task_cards.source_schema` | nem |
| Forrás tábla | `source_table` | `task_cards.source_table` | nem |
| Forrás PK | `source_pk` | `task_cards.source_pk` | nem |
| Forrás URL | `source_url` | `task_cards.source_url` | nem |
| Felelős | `assignee_user_id` | `task_cards.assignee_user_id` | igen |
| Felelős név | `assignee_name` | view join user_profiles | nem közvetlen |
| Határidő | `due_at` | `task_cards.due_at` | igen |
| Progress | `progress_percent` | `task_cards.progress_percent` | igen / számított |
| AI állapot | `ai_state` | `task_cards.ai_state` | agent írja |
| Notification állapot | `notification_state` | `task_cards.notification_state` | rendszer írja |
| Címkék | `tags` | `task_cards.tags` jsonb | igen |
| Meta | `metadata` | `task_cards.metadata` jsonb | advanced |
| Létrehozva | `created_at` | `task_cards.created_at` | nem |
| Módosítva | `updated_at` | `task_cards.updated_at` | nem |

## 6. Detail panel mezők

| Panel | Supabase |
|---|---|
| Részletek | `task_cards` |
| Checklist | `task_checklist_items` |
| Kommentek | `task_comments` — csak kártya komment, nem chat modul |
| Activity | `task_events` |
| AI / Agent | `agent_jobs` + `task_cards.ai_*` |

## 7. Filter drawer mezők

| Filter | Supabase filter |
|---|---|
| Forrás/modul | `module_key = ?` |
| Prioritás | `priority_key = ?` |
| Felhasználó | `assignee_user_id = ?` |
| Csak AI | `ai_state <> 'none' OR module_key = 'ai'` |
| Kész elrejtése | `status_key <> 'done'` |

## 8. Required frontend actions

| UI action | Supabase/RPC |
|---|---|
| Drag card status change | `task_center.move_task_card(...)` |
| Create task | `task_center.create_task_card(...)` |
| Update field | `task_center.update_task_field(...)` or direct update with RLS |
| Assign to user | `task_center.assign_task_card(...)` |
| Add checklist item | insert `task_checklist_items` |
| Toggle checklist | update `task_checklist_items.is_done` |
| Add card comment | insert `task_comments` |
| Queue AI | `task_center.queue_agent_job(...)` |
| Notify assignee | insert `task_notifications` |
| Open source | frontend route/link based on `source_url` |
