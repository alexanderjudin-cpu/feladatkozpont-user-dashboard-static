-- =========================================================
-- Feladatközpont / User Dashboard — Supabase schema v2 draft
-- Static HTML + Retool bridge + Supabase Realtime ready
-- No service_role key in frontend. Use anon + RLS or Retool backend.
-- =========================================================

create extension if not exists pgcrypto;

create schema if not exists task_center;

-- ---------------------------------------------------------
-- User display profiles. Can be populated from auth.users or app user table.
-- ---------------------------------------------------------
create table if not exists task_center.user_profiles (
  user_id uuid primary key,
  email text unique,
  display_name text not null,
  initials text not null,
  avatar_color text not null default '#193b69',
  avatar_url text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- Boards. First board can be 'main_user_dashboard'.
-- ---------------------------------------------------------
create table if not exists task_center.boards (
  board_id uuid primary key default gen_random_uuid(),
  board_key text unique not null,
  board_title text not null,
  board_description text,
  is_active boolean not null default true,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- Board members / permissions / top-right monogram stack.
-- ---------------------------------------------------------
create table if not exists task_center.board_members (
  board_member_id uuid primary key default gen_random_uuid(),
  board_id uuid not null references task_center.boards(board_id) on delete cascade,
  user_id uuid not null references task_center.user_profiles(user_id) on delete cascade,
  role_key text not null default 'member',
  can_view boolean not null default true,
  can_create boolean not null default true,
  can_edit_all boolean not null default false,
  can_manage_board boolean not null default false,
  is_active boolean not null default true,
  sort_order numeric not null default 1000,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(board_id, user_id)
);

create index if not exists ix_board_members_board on task_center.board_members(board_id, is_active, sort_order);
create index if not exists ix_board_members_user on task_center.board_members(user_id, is_active);

-- ---------------------------------------------------------
-- Status columns for kanban.
-- ---------------------------------------------------------
create table if not exists task_center.task_columns (
  column_id uuid primary key default gen_random_uuid(),
  board_id uuid not null references task_center.boards(board_id) on delete cascade,
  status_key text not null,
  status_label text not null,
  icon text,
  color text,
  sort_order numeric not null default 1000,
  is_done_column boolean not null default false,
  is_active boolean not null default true,
  unique(board_id, status_key)
);

-- ---------------------------------------------------------
-- Main cards.
-- ---------------------------------------------------------
create table if not exists task_center.task_cards (
  task_id uuid primary key default gen_random_uuid(),
  board_id uuid not null references task_center.boards(board_id) on delete cascade,

  title text not null,
  description text,

  status_key text not null default 'new',
  priority_key text not null default 'normal',

  module_key text not null default 'general',
  module_label text not null default 'Általános',

  source_type text,
  source_schema text,
  source_table text,
  source_pk text,
  source_url text,
  source_payload jsonb not null default '{}'::jsonb,

  assignee_user_id uuid references task_center.user_profiles(user_id),
  created_by_user_id uuid references task_center.user_profiles(user_id),

  due_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  archived_at timestamptz,

  progress_percent int not null default 0 check (progress_percent between 0 and 100),
  sort_order numeric not null default 1000,

  tags jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,

  ai_state text not null default 'none',
  ai_summary text,
  ai_suggestion jsonb not null default '{}'::jsonb,

  notification_state text not null default 'none',
  last_notified_at timestamptz,

  is_private boolean not null default false,
  is_deleted boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint task_cards_status_chk check (status_key in ('new','in_progress','waiting','approval_wait','ai_preparing','done','cancelled')),
  constraint task_cards_priority_chk check (priority_key in ('critical','high','normal','low')),
  constraint task_cards_ai_state_chk check (ai_state in ('none','suggested','queued','running','ready','failed','applied'))
);

create index if not exists ix_task_cards_board_status on task_center.task_cards(board_id, status_key, sort_order);
create index if not exists ix_task_cards_assignee on task_center.task_cards(assignee_user_id);
create index if not exists ix_task_cards_due on task_center.task_cards(due_at);
create index if not exists ix_task_cards_module on task_center.task_cards(module_key);
create index if not exists ix_task_cards_source on task_center.task_cards(module_key, source_schema, source_table, source_pk);
create index if not exists ix_task_cards_tags on task_center.task_cards using gin(tags);
create index if not exists ix_task_cards_metadata on task_center.task_cards using gin(metadata);

-- ---------------------------------------------------------
-- Watchers / extra visibility.
-- ---------------------------------------------------------
create table if not exists task_center.task_watchers (
  task_watcher_id uuid primary key default gen_random_uuid(),
  task_id uuid not null references task_center.task_cards(task_id) on delete cascade,
  user_id uuid not null references task_center.user_profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(task_id, user_id)
);

-- ---------------------------------------------------------
-- Checklist.
-- ---------------------------------------------------------
create table if not exists task_center.task_checklist_items (
  checklist_item_id uuid primary key default gen_random_uuid(),
  task_id uuid not null references task_center.task_cards(task_id) on delete cascade,
  item_text text not null,
  is_done boolean not null default false,
  done_by_user_id uuid references task_center.user_profiles(user_id),
  done_at timestamptz,
  sort_order numeric not null default 1000,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- Card comments only. This is not a messaging/chat module.
-- ---------------------------------------------------------
create table if not exists task_center.task_comments (
  comment_id uuid primary key default gen_random_uuid(),
  task_id uuid not null references task_center.task_cards(task_id) on delete cascade,
  author_user_id uuid references task_center.user_profiles(user_id),
  body text not null,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- Audit/activity.
-- ---------------------------------------------------------
create table if not exists task_center.task_events (
  event_id uuid primary key default gen_random_uuid(),
  task_id uuid references task_center.task_cards(task_id) on delete cascade,
  board_id uuid references task_center.boards(board_id) on delete cascade,
  event_type text not null,
  event_title text,
  event_body text,
  actor_user_id uuid references task_center.user_profiles(user_id),
  old_value jsonb,
  new_value jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- Task notifications, not messages.
-- ---------------------------------------------------------
create table if not exists task_center.task_notifications (
  notification_id uuid primary key default gen_random_uuid(),
  task_id uuid references task_center.task_cards(task_id) on delete cascade,
  board_id uuid references task_center.boards(board_id) on delete cascade,
  recipient_user_id uuid references task_center.user_profiles(user_id),
  channel text not null default 'in_app',
  title text not null,
  body text,
  status text not null default 'queued',
  scheduled_at timestamptz not null default now(),
  sent_at timestamptz,
  read_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  error_text text,
  created_at timestamptz not null default now(),
  constraint task_notifications_channel_chk check (channel in ('in_app','email','slack','teams','webhook','retool')),
  constraint task_notifications_status_chk check (status in ('queued','sent','failed','cancelled'))
);

-- ---------------------------------------------------------
-- AI / agent queue.
-- ---------------------------------------------------------
create table if not exists task_center.agent_jobs (
  agent_job_id uuid primary key default gen_random_uuid(),
  task_id uuid references task_center.task_cards(task_id) on delete cascade,
  board_id uuid references task_center.boards(board_id) on delete cascade,
  agent_key text not null,
  job_type text not null,
  status text not null default 'queued',
  input_payload jsonb not null default '{}'::jsonb,
  output_payload jsonb not null default '{}'::jsonb,
  requested_by_user_id uuid references task_center.user_profiles(user_id),
  error_text text,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint agent_jobs_status_chk check (status in ('queued','running','ready','failed','cancelled','applied'))
);

-- ---------------------------------------------------------
-- Automations placeholders.
-- ---------------------------------------------------------
create table if not exists task_center.automations (
  automation_id uuid primary key default gen_random_uuid(),
  board_id uuid not null references task_center.boards(board_id) on delete cascade,
  automation_key text not null,
  title text not null,
  description text,
  trigger_type text not null,
  action_type text not null,
  config jsonb not null default '{}'::jsonb,
  is_enabled boolean not null default false,
  created_by_user_id uuid references task_center.user_profiles(user_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(board_id, automation_key)
);

-- ---------------------------------------------------------
-- updated_at helper.
-- ---------------------------------------------------------
create or replace function task_center.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- apply triggers safely
create or replace function task_center.ensure_updated_at_trigger(p_table regclass)
returns void language plpgsql as $$
begin
  execute format('drop trigger if exists trg_set_updated_at on %s', p_table);
  execute format('create trigger trg_set_updated_at before update on %s for each row execute function task_center.set_updated_at()', p_table);
end;
$$;

select task_center.ensure_updated_at_trigger('task_center.user_profiles');
select task_center.ensure_updated_at_trigger('task_center.boards');
select task_center.ensure_updated_at_trigger('task_center.board_members');
select task_center.ensure_updated_at_trigger('task_center.task_cards');
select task_center.ensure_updated_at_trigger('task_center.task_checklist_items');
select task_center.ensure_updated_at_trigger('task_center.task_comments');
select task_center.ensure_updated_at_trigger('task_center.agent_jobs');
select task_center.ensure_updated_at_trigger('task_center.automations');

-- ---------------------------------------------------------
-- Views for frontend.
-- ---------------------------------------------------------
create or replace view task_center.v_board_members as
select
  bm.board_member_id,
  b.board_id,
  b.board_key,
  up.user_id,
  up.email,
  up.display_name as name,
  up.initials,
  up.avatar_color as color,
  up.avatar_url,
  bm.role_key as role,
  bm.can_view,
  bm.can_create,
  bm.can_edit_all,
  bm.can_manage_board,
  bm.is_active,
  bm.sort_order
from task_center.board_members bm
join task_center.boards b on b.board_id = bm.board_id
join task_center.user_profiles up on up.user_id = bm.user_id
where bm.is_active = true and up.is_active = true and b.is_active = true;

create or replace view task_center.v_task_cards_frontend as
select
  tc.task_id,
  tc.board_id,
  b.board_key,
  tc.title,
  tc.description,
  tc.status_key,
  tc.priority_key,
  tc.module_key,
  tc.module_label,
  tc.source_type,
  tc.source_schema,
  tc.source_table,
  tc.source_pk,
  tc.source_url,
  tc.source_payload,
  tc.assignee_user_id,
  au.display_name as assignee_name,
  au.initials as assignee_initials,
  au.avatar_color as assignee_color,
  tc.created_by_user_id,
  cu.display_name as created_by_name,
  tc.due_at,
  tc.started_at,
  tc.completed_at,
  tc.progress_percent,
  tc.sort_order,
  tc.tags,
  tc.metadata,
  tc.ai_state,
  tc.ai_summary,
  tc.ai_suggestion,
  tc.notification_state,
  tc.created_at,
  tc.updated_at,
  coalesce(ch.total_count,0) as checklist_total,
  coalesce(ch.done_count,0) as checklist_done,
  coalesce(cm.comment_count,0) as comment_count
from task_center.task_cards tc
join task_center.boards b on b.board_id = tc.board_id
left join task_center.user_profiles au on au.user_id = tc.assignee_user_id
left join task_center.user_profiles cu on cu.user_id = tc.created_by_user_id
left join (
  select task_id, count(*) as total_count, count(*) filter (where is_done) as done_count
  from task_center.task_checklist_items
  group by task_id
) ch on ch.task_id = tc.task_id
left join (
  select task_id, count(*) filter (where not is_deleted) as comment_count
  from task_center.task_comments
  group by task_id
) cm on cm.task_id = tc.task_id
where tc.is_deleted = false and tc.archived_at is null;

-- ---------------------------------------------------------
-- RPC functions.
-- ---------------------------------------------------------
create or replace function task_center.add_event(
  p_task_id uuid,
  p_event_type text,
  p_event_title text default null,
  p_event_body text default null,
  p_actor_user_id uuid default null,
  p_old_value jsonb default null,
  p_new_value jsonb default null,
  p_metadata jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path = task_center, public as $$
declare v_event_id uuid; v_board_id uuid;
begin
  select board_id into v_board_id from task_center.task_cards where task_id = p_task_id;
  insert into task_center.task_events(task_id, board_id, event_type, event_title, event_body, actor_user_id, old_value, new_value, metadata)
  values(p_task_id, v_board_id, p_event_type, p_event_title, p_event_body, p_actor_user_id, p_old_value, p_new_value, p_metadata)
  returning event_id into v_event_id;
  return v_event_id;
end;
$$;

create or replace function task_center.move_task_card(
  p_task_id uuid,
  p_status_key text,
  p_sort_order numeric default null,
  p_actor_user_id uuid default null
) returns task_center.task_cards language plpgsql security definer set search_path = task_center, public as $$
declare v_old task_center.task_cards; v_new task_center.task_cards;
begin
  select * into v_old from task_center.task_cards where task_id = p_task_id;
  if not found then raise exception 'task_not_found'; end if;

  update task_center.task_cards
  set status_key = p_status_key,
      sort_order = coalesce(p_sort_order, sort_order),
      started_at = case when p_status_key = 'in_progress' and started_at is null then now() else started_at end,
      completed_at = case when p_status_key = 'done' then now() else completed_at end
  where task_id = p_task_id
  returning * into v_new;

  perform task_center.add_event(p_task_id, 'status_change', 'Státusz módosítva', null, p_actor_user_id, to_jsonb(v_old), to_jsonb(v_new));
  return v_new;
end;
$$;

create or replace function task_center.queue_agent_job(
  p_task_id uuid,
  p_agent_key text,
  p_job_type text,
  p_input_payload jsonb default '{}'::jsonb,
  p_requested_by_user_id uuid default null
) returns uuid language plpgsql security definer set search_path = task_center, public as $$
declare v_job_id uuid; v_board_id uuid;
begin
  select board_id into v_board_id from task_center.task_cards where task_id = p_task_id;

  insert into task_center.agent_jobs(task_id, board_id, agent_key, job_type, input_payload, requested_by_user_id)
  values(p_task_id, v_board_id, p_agent_key, p_job_type, p_input_payload, p_requested_by_user_id)
  returning agent_job_id into v_job_id;

  update task_center.task_cards set ai_state = 'queued', status_key = 'ai_preparing' where task_id = p_task_id;
  perform task_center.add_event(p_task_id, 'agent_queued', 'AI agent sorba állítva', null, p_requested_by_user_id, null, jsonb_build_object('agent_job_id', v_job_id));

  return v_job_id;
end;
$$;
