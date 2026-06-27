# Backend / Supabase integráció

## Fő elv

A frontend ne tudjon semmit konkrét UAHUN, szállás, HR, pénzügy táblákról.
A frontend csak task cardokat lát.
A task card mögött lehet bármilyen forrásrekord.

## Forrásrekord modellezés

Minden tasknál legyen:

- source_module
- source_type
- source_id
- source_url optional
- source_payload jsonb optional

Példa:

```json
{
  "source_module": "uahun",
  "source_type": "workflow_case",
  "source_id": "uuid",
  "source_payload": {
    "person_name": "...",
    "partner": "..."
  }
}
```

## Live frissítés

Javasolt irány:

1. Supabase table: task_center.task_cards
2. View: task_center.v_user_visible_cards
3. RPC: task_center.move_task
4. RPC: task_center.create_task
5. RPC: task_center.update_task
6. Realtime channel: task_cards changes
7. Frontend optimistic update, majd backend confirm

## Frontend bridge

A jelenlegi standalone HTML már támogatja a parent-postMessage logikát:

- task_center_set_tasks
- task_center_set_users

És eseményeket küld vissza:

- task_center_ready
- task_center_select
- task_center_status_change
- task_center_update_field
- task_center_create_task
- task_center_update_task
- task_center_comment
- task_center_notify
- task_center_open_source
- task_center_queue_agent
- task_center_bulk_status_change
- task_center_user_filter
- task_center_view_change

## Supabase direct mód később

A frontend később közvetlenül is beszélhet Supabase-szel, de csak akkor, ha:

- RLS kész
- anon key biztonságosan használható
- user session kezelés tiszta
- role alapú láthatóság megoldott

Addig Retool bridge / API layer biztonságosabb.

