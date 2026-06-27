-- Feladatközpont / User Dashboard Supabase schema proposal
-- Safe to review before running. Intended as clean backend contract for the standalone dashboard.

create schema if not exists task_center;

create extension if not exists pgcrypto;

-- Generic updated_at helper
create or replace function task_center.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Boards allow multiple user dashboard boards later.
create table if not exists task_center.boards (
  board_id uuid primary key default gen_random_uuid(),
  board_code text unique not null,
  board_name text not null,
  board_type text not null default 'user_dashboard',
  is_active boolean not null default true,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Board users / visible monogram stack.
create table if not exists task_center.board_members (
  board_member_id uuid primary key default gen_random_uuid(),
  board_id uuid not null references task_center.boards(board_id) on delete cascade,
  user_id uuid null,
  external_user_key text null,
  display_name text not null,
  initials text not null,
  email text null,
  avatar_url text null,
  color text not null default '#193b69',
  role_label text not null default 'Board member',
  permission_level text not null default 'member', -- owner/admin/manager/member/viewer/agent
  is_online boolean not null default false,
  is_active boolean not null default true,
  last_seen_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(board_id, external_user_key)
);

-- Main task cards.
create table if not exists task_center.task_cards (
  task_id uuid primary key default gen_random_uuid(),
  board_id uuid not null references task_center.boards(board_id) on delete cascade,

  title text not null,
  description text null,

  status text not null default 'new',
  priority text not null default 'normal',
  module_key text not null default 'general',

  assigned_to_member_id uuid null references task_center.board_members(board_member_id) on delete set null,
  assigned_to_external_user_key text null,

  due_at timestamptz null,
  due_label text null,

  source_module text null,
  source_type text null,
  source_id text null,
  source_url text null,
  source_payload jsonb not null default '{}'::jsonb,

  tags text[] not null default '{}',
  progress integer not null default 0 check (progress between 0 and 100),

  ai_state text not null default 'none', -- none/suggested/queued/running/done/error
  ai_payload jsonb not null default '{}'::jsonb,

  sort_order numeric not null default 1000,
  is_archived boolean not null default false,
  is_deleted boolean not null default false,

  created_by_member_id uuid null references task_center.board_members(board_member_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_task_cards_board_status on task_center.task_cards(board_id, status, sort_order);
create index if not exists idx_task_cards_assignee on task_center.task_cards(assigned_to_member_id);
create index if not exists idx_task_cards_source on task_center.task_cards(source_module, source_type, source_id);
create index if not exists idx_task_cards_due on task_center.task_cards(due_at);
create index if not exists idx_task_cards_ai_state on task_center.task_cards(ai_state);

-- Checklist items per card.
create table if not exists task_center.task_checklist_items (
  checklist_item_id uuid primary key default gen_random_uuid(),
  task_id uuid not null references task_center.task_cards(task_id) on delete cascade,
  item_text text not null,
  is_done boolean not null default false,
  sort_order numeric not null default 1000,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Comments / notes. Message/chat module is not active, but task comments are still allowed inside cards.
create table if not exists task_center.task_comments (
  comment_id uuid primary key default gen_random_uuid(),
  task_id uuid not null references task_center.task_cards(task_id) on delete cascade,
  author_member_id uuid null references task_center.board_members(board_member_id) on delete set null,
  comment_text text not null,
  comment_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Audit/event stream for every interaction.
create table if not exists task_center.task_events (
  event_id uuid primary key default gen_random_uuid(),
  task_id uuid null references task_center.task_cards(task_id) on delete set null,
  board_id uuid null references task_center.boards(board_id) on delete set null,
  actor_member_id uuid null references task_center.board_members(board_member_id) on delete set null,
  event_type text not null,
  old_value jsonb null,
  new_value jsonb null,
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Notification outbox. Later email/slack/retool notifications can use this.
create table if not exists task_center.task_notifications (
  notification_id uuid primary key default gen_random_uuid(),
  task_id uuid null references task_center.task_cards(task_id) on delete cascade,
  board_id uuid null references task_center.boards(board_id) on delete cascade,
  recipient_member_id uuid null references task_center.board_members(board_member_id) on delete set null,
  channel text not null default 'in_app',
  title text not null,
  body text null,
  status text not null default 'pending', -- pending/sent/error/read
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  sent_at timestamptz null,
  read_at timestamptz null
);

-- Agent queue. AI agent jobs should be auditable, not direct uncontrolled writes.
create table if not exists task_center.agent_jobs (
  agent_job_id uuid primary key default gen_random_uuid(),
  task_id uuid null references task_center.task_cards(task_id) on delete set null,
  board_id uuid null references task_center.boards(board_id) on delete set null,
  requested_by_member_id uuid null references task_center.board_members(board_member_id) on delete set null,
  agent_code text not null default 'task_assistant',
  job_type text not null,
  status text not null default 'queued', -- queued/running/done/error/cancelled
  input_payload jsonb not null default '{}'::jsonb,
  output_payload jsonb not null default '{}'::jsonb,
  error_message text null,
  created_at timestamptz not null default now(),
  started_at timestamptz null,
  finished_at timestamptz null
);

-- Triggers
create trigger trg_boards_updated_at before update on task_center.boards for each row execute function task_center.set_updated_at();
create trigger trg_board_members_updated_at before update on task_center.board_members for each row execute function task_center.set_updated_at();
create trigger trg_task_cards_updated_at before update on task_center.task_cards for each row execute function task_center.set_updated_at();
create trigger trg_task_checklist_items_updated_at before update on task_center.task_checklist_items for each row execute function task_center.set_updated_at();
create trigger trg_task_comments_updated_at before update on task_center.task_comments for each row execute function task_center.set_updated_at();

-- Board card read view for frontend.
create or replace view task_center.v_task_cards_frontend as
select
  c.task_id,
  c.board_id,
  b.board_code,
  c.title,
  c.description,
  c.status,
  c.priority,
  c.module_key,
  c.due_at,
  c.due_label,
  c.source_module,
  c.source_type,
  c.source_id,
  c.source_url,
  c.source_payload,
  c.tags,
  c.progress,
  c.ai_state,
  c.ai_payload,
  c.sort_order,
  c.created_at,
  c.updated_at,
  m.board_member_id as assignee_member_id,
  m.external_user_key as assignee_key,
  m.display_name as assignee_name,
  m.initials as assignee_initials,
  m.color as assignee_color,
  coalesce(chk.total_checklist, 0) as checklist_total,
  coalesce(chk.done_checklist, 0) as checklist_done,
  coalesce(com.comment_count, 0) as comment_count
from task_center.task_cards c
join task_center.boards b on b.board_id = c.board_id
left join task_center.board_members m on m.board_member_id = c.assigned_to_member_id
left join lateral (
  select count(*)::int as total_checklist, count(*) filter (where is_done)::int as done_checklist
  from task_center.task_checklist_items x
  where x.task_id = c.task_id
) chk on true
left join lateral (
  select count(*)::int as comment_count
  from task_center.task_comments y
  where y.task_id = c.task_id
) com on true
where c.is_deleted = false and c.is_archived = false;

-- Create/update card from any source module.
create or replace function task_center.upsert_task_from_source(
  p_board_code text,
  p_source_module text,
  p_source_type text,
  p_source_id text,
  p_title text,
  p_description text default null,
  p_status text default 'new',
  p_priority text default 'normal',
  p_module_key text default 'general',
  p_assignee_external_user_key text default null,
  p_due_at timestamptz default null,
  p_due_label text default null,
  p_tags text[] default '{}',
  p_source_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
as $$
declare
  v_board_id uuid;
  v_member_id uuid;
  v_task_id uuid;
begin
  select board_id into v_board_id from task_center.boards where board_code = p_board_code and is_active = true;
  if v_board_id is null then
    raise exception 'Unknown or inactive board_code: %', p_board_code;
  end if;

  if p_assignee_external_user_key is not null then
    select board_member_id into v_member_id
    from task_center.board_members
    where board_id = v_board_id
      and external_user_key = p_assignee_external_user_key
      and is_active = true
    limit 1;
  end if;

  select task_id into v_task_id
  from task_center.task_cards
  where board_id = v_board_id
    and source_module is not distinct from p_source_module
    and source_type is not distinct from p_source_type
    and source_id is not distinct from p_source_id
    and is_deleted = false
  limit 1;

  if v_task_id is null then
    insert into task_center.task_cards(
      board_id, source_module, source_type, source_id,
      title, description, status, priority, module_key,
      assigned_to_member_id, assigned_to_external_user_key,
      due_at, due_label, tags, source_payload
    ) values (
      v_board_id, p_source_module, p_source_type, p_source_id,
      p_title, p_description, p_status, p_priority, p_module_key,
      v_member_id, p_assignee_external_user_key,
      p_due_at, p_due_label, p_tags, coalesce(p_source_payload,'{}'::jsonb)
    ) returning task_id into v_task_id;

    insert into task_center.task_events(task_id, board_id, event_type, new_value)
    values (v_task_id, v_board_id, 'created_from_source', to_jsonb(p_source_payload));
  else
    update task_center.task_cards
    set title = p_title,
        description = coalesce(p_description, description),
        status = coalesce(p_status, status),
        priority = coalesce(p_priority, priority),
        module_key = coalesce(p_module_key, module_key),
        assigned_to_member_id = coalesce(v_member_id, assigned_to_member_id),
        assigned_to_external_user_key = coalesce(p_assignee_external_user_key, assigned_to_external_user_key),
        due_at = coalesce(p_due_at, due_at),
        due_label = coalesce(p_due_label, due_label),
        tags = coalesce(p_tags, tags),
        source_payload = coalesce(p_source_payload, source_payload)
    where task_id = v_task_id;

    insert into task_center.task_events(task_id, board_id, event_type, new_value)
    values (v_task_id, v_board_id, 'updated_from_source', to_jsonb(p_source_payload));
  end if;

  return v_task_id;
end;
$$;

-- Move card status.
create or replace function task_center.move_task(
  p_task_id uuid,
  p_new_status text,
  p_actor_member_id uuid default null,
  p_new_sort_order numeric default null
)
returns task_center.task_cards
language plpgsql
as $$
declare
  v_old task_center.task_cards;
  v_new task_center.task_cards;
begin
  select * into v_old from task_center.task_cards where task_id = p_task_id and is_deleted = false;
  if v_old.task_id is null then
    raise exception 'Task not found: %', p_task_id;
  end if;

  update task_center.task_cards
  set status = p_new_status,
      sort_order = coalesce(p_new_sort_order, sort_order)
  where task_id = p_task_id
  returning * into v_new;

  insert into task_center.task_events(task_id, board_id, actor_member_id, event_type, old_value, new_value)
  values (
    p_task_id,
    v_new.board_id,
    p_actor_member_id,
    'status_change',
    jsonb_build_object('status', v_old.status, 'sort_order', v_old.sort_order),
    jsonb_build_object('status', v_new.status, 'sort_order', v_new.sort_order)
  );

  return v_new;
end;
$$;

-- Queue AI job.
create or replace function task_center.queue_agent_job(
  p_task_id uuid,
  p_job_type text,
  p_requested_by_member_id uuid default null,
  p_input_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
as $$
declare
  v_task task_center.task_cards;
  v_job_id uuid;
begin
  select * into v_task from task_center.task_cards where task_id = p_task_id and is_deleted = false;
  if v_task.task_id is null then
    raise exception 'Task not found: %', p_task_id;
  end if;

  insert into task_center.agent_jobs(task_id, board_id, requested_by_member_id, job_type, input_payload)
  values (p_task_id, v_task.board_id, p_requested_by_member_id, p_job_type, coalesce(p_input_payload,'{}'::jsonb))
  returning agent_job_id into v_job_id;

  update task_center.task_cards
  set ai_state = 'queued'
  where task_id = p_task_id;

  insert into task_center.task_events(task_id, board_id, actor_member_id, event_type, new_value)
  values (p_task_id, v_task.board_id, p_requested_by_member_id, 'agent_queued', jsonb_build_object('agent_job_id', v_job_id, 'job_type', p_job_type));

  return v_job_id;
end;
$$;
