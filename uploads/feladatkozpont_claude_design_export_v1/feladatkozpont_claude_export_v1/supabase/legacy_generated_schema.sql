-- =========================================================
-- HDD / UAHUN - FELADATKÖZPONT alap séma
-- Supabase / PostgreSQL full replace-safe bootstrap
-- Cél: Retool + külön HTML kanban + agent + értesítés bekötési alap
-- =========================================================

create extension if not exists pgcrypto;

create schema if not exists task_center;

-- ---------------------------------------------------------
-- 1) Enumok / domain jellegű constraint nélküli text mezők
--    Direkt text alapú, hogy később új státusz / modul gyorsan felvehető legyen.
-- ---------------------------------------------------------

create table if not exists task_center.task_cards (
  task_id uuid primary key default gen_random_uuid(),

  title text not null,
  description text,

  module_key text not null default 'general',
  module_label text not null default 'Általános',

  -- source_* mezők: bármely modul rekordjára rámutathat.
  -- Példa: module_key='uahun', source_schema='public', source_table='workflow_cases', source_pk='<uuid>'
  source_schema text,
  source_table text,
  source_pk text,
  source_url text,

  status text not null default 'new',
  status_label text generated always as (
    case status
      when 'new' then 'Új'
      when 'in_progress' then 'Folyamatban'
      when 'approval_wait' then 'Jóváhagyásra vár'
      when 'ai_preparing' then 'AI előkészítés'
      when 'done' then 'Kész'
      when 'cancelled' then 'Törölve'
      else status
    end
  ) stored,

  priority text not null default 'normal',
  priority_label text generated always as (
    case priority
      when 'critical' then 'Kritikus'
      when 'high' then 'Magas'
      when 'normal' then 'Normál'
      when 'low' then 'Alacsony'
      else priority
    end
  ) stored,

  assigned_to_email text,
  assigned_to_name text,
  created_by_email text,
  created_by_name text,

  due_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  archived_at timestamptz,

  -- jogosultsági minimum: adott emailek explicit láthatják.
  -- később ezt role/team táblákkal lehet szigorítani.
  allowed_emails text[] not null default '{}',
  watcher_emails text[] not null default '{}',
  is_private boolean not null default false,

  tags jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,

  ai_state text not null default 'none',
  ai_summary text,
  ai_suggestion jsonb not null default '{}'::jsonb,

  notification_state text not null default 'none',
  last_notified_at timestamptz,

  sort_order numeric not null default 1000,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint task_cards_status_chk check (
    status in ('new', 'in_progress', 'approval_wait', 'ai_preparing', 'done', 'cancelled')
  ),
  constraint task_cards_priority_chk check (
    priority in ('critical', 'high', 'normal', 'low')
  ),
  constraint task_cards_ai_state_chk check (
    ai_state in ('none', 'suggested', 'queued', 'running', 'ready', 'failed', 'applied')
  )
);

create index if not exists ix_task_cards_status on task_center.task_cards(status);
create index if not exists ix_task_cards_priority on task_center.task_cards(priority);
create index if not exists ix_task_cards_module on task_center.task_cards(module_key);
create index if not exists ix_task_cards_assigned_email on task_center.task_cards(lower(assigned_to_email));
create index if not exists ix_task_cards_due_at on task_center.task_cards(due_at);
create index if not exists ix_task_cards_source on task_center.task_cards(module_key, source_schema, source_table, source_pk);
create index if not exists ix_task_cards_allowed_emails on task_center.task_cards using gin(allowed_emails);
create index if not exists ix_task_cards_watcher_emails on task_center.task_cards using gin(watcher_emails);
create index if not exists ix_task_cards_tags on task_center.task_cards using gin(tags);
create index if not exists ix_task_cards_metadata on task_center.task_cards using gin(metadata);

create table if not exists task_center.task_events (
  event_id uuid primary key default gen_random_uuid(),
  task_id uuid not null references task_center.task_cards(task_id) on delete cascade,
  event_type text not null,
  event_title text,
  event_body text,
  old_value jsonb,
  new_value jsonb,
  created_by_email text,
  created_by_name text,
  created_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists ix_task_events_task_created on task_center.task_events(task_id, created_at desc);
create index if not exists ix_task_events_type on task_center.task_events(event_type);

create table if not exists task_center.task_notifications (
  notification_id uuid primary key default gen_random_uuid(),
  task_id uuid references task_center.task_cards(task_id) on delete cascade,
  channel text not null default 'retool',
  recipient_email text not null,
  subject text not null,
  body text,
  status text not null default 'queued',
  scheduled_at timestamptz not null default now(),
  sent_at timestamptz,
  error_text text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),

  constraint task_notifications_channel_chk check (channel in ('retool', 'email', 'slack', 'teams', 'webhook')),
  constraint task_notifications_status_chk check (status in ('queued', 'sent', 'failed', 'cancelled'))
);

create index if not exists ix_task_notifications_queue on task_center.task_notifications(status, scheduled_at);
create index if not exists ix_task_notifications_recipient on task_center.task_notifications(lower(recipient_email));

create table if not exists task_center.agent_jobs (
  agent_job_id uuid primary key default gen_random_uuid(),
  task_id uuid references task_center.task_cards(task_id) on delete cascade,
  agent_key text not null,
  job_type text not null,
  status text not null default 'queued',
  input_payload jsonb not null default '{}'::jsonb,
  output_payload jsonb not null default '{}'::jsonb,
  error_text text,
  requested_by_email text,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint agent_jobs_status_chk check (status in ('queued', 'running', 'ready', 'failed', 'cancelled', 'applied'))
);

create index if not exists ix_agent_jobs_status on task_center.agent_jobs(status, created_at);
create index if not exists ix_agent_jobs_task on task_center.agent_jobs(task_id, created_at desc);

-- ---------------------------------------------------------
-- 2) updated_at trigger
-- ---------------------------------------------------------

create or replace function task_center.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_task_cards_updated_at on task_center.task_cards;
create trigger trg_task_cards_updated_at
before update on task_center.task_cards
for each row execute function task_center.set_updated_at();

drop trigger if exists trg_agent_jobs_updated_at on task_center.agent_jobs;
create trigger trg_agent_jobs_updated_at
before update on task_center.agent_jobs
for each row execute function task_center.set_updated_at();

-- ---------------------------------------------------------
-- 3) Audit helper
-- ---------------------------------------------------------

create or replace function task_center.add_event(
  p_task_id uuid,
  p_event_type text,
  p_event_title text default null,
  p_event_body text default null,
  p_old_value jsonb default null,
  p_new_value jsonb default null,
  p_user_email text default null,
  p_user_name text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = task_center, public
as $$
declare
  v_event_id uuid;
begin
  insert into task_center.task_events (
    task_id,
    event_type,
    event_title,
    event_body,
    old_value,
    new_value,
    created_by_email,
    created_by_name,
    metadata
  ) values (
    p_task_id,
    p_event_type,
    p_event_title,
    p_event_body,
    p_old_value,
    p_new_value,
    p_user_email,
    p_user_name,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning event_id into v_event_id;

  return v_event_id;
end;
$$;

-- ---------------------------------------------------------
-- 4) Forrásból task létrehozása / frissítése
--    Ezt lehet triggerből, Retool queryből, Edge Functionből vagy agentből hívni.
-- ---------------------------------------------------------

create or replace function task_center.upsert_task_from_source(
  p_title text,
  p_description text default null,
  p_module_key text default 'general',
  p_module_label text default 'Általános',
  p_source_schema text default null,
  p_source_table text default null,
  p_source_pk text default null,
  p_source_url text default null,
  p_status text default 'new',
  p_priority text default 'normal',
  p_assigned_to_email text default null,
  p_assigned_to_name text default null,
  p_created_by_email text default null,
  p_created_by_name text default null,
  p_due_at timestamptz default null,
  p_allowed_emails text[] default '{}',
  p_watcher_emails text[] default '{}',
  p_tags jsonb default '[]'::jsonb,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = task_center, public
as $$
declare
  v_task_id uuid;
  v_existing uuid;
begin
  select task_id
    into v_existing
  from task_center.task_cards
  where module_key = coalesce(p_module_key, 'general')
    and coalesce(source_schema, '') = coalesce(p_source_schema, '')
    and coalesce(source_table, '') = coalesce(p_source_table, '')
    and coalesce(source_pk, '') = coalesce(p_source_pk, '')
    and archived_at is null
  order by created_at desc
  limit 1;

  if v_existing is null then
    insert into task_center.task_cards (
      title,
      description,
      module_key,
      module_label,
      source_schema,
      source_table,
      source_pk,
      source_url,
      status,
      priority,
      assigned_to_email,
      assigned_to_name,
      created_by_email,
      created_by_name,
      due_at,
      allowed_emails,
      watcher_emails,
      tags,
      metadata
    ) values (
      p_title,
      p_description,
      coalesce(p_module_key, 'general'),
      coalesce(p_module_label, 'Általános'),
      p_source_schema,
      p_source_table,
      p_source_pk,
      p_source_url,
      coalesce(p_status, 'new'),
      coalesce(p_priority, 'normal'),
      p_assigned_to_email,
      p_assigned_to_name,
      p_created_by_email,
      p_created_by_name,
      p_due_at,
      coalesce(p_allowed_emails, '{}'),
      coalesce(p_watcher_emails, '{}'),
      coalesce(p_tags, '[]'::jsonb),
      coalesce(p_metadata, '{}'::jsonb)
    )
    returning task_id into v_task_id;

    perform task_center.add_event(
      v_task_id,
      'created',
      'Feladat létrehozva',
      p_title,
      null,
      to_jsonb((select x from (select p_title as title, p_module_key as module_key, p_source_pk as source_pk) x)),
      p_created_by_email,
      p_created_by_name,
      '{}'::jsonb
    );
  else
    update task_center.task_cards
       set title = p_title,
           description = coalesce(p_description, description),
           module_label = coalesce(p_module_label, module_label),
           source_url = coalesce(p_source_url, source_url),
           priority = coalesce(p_priority, priority),
           assigned_to_email = coalesce(p_assigned_to_email, assigned_to_email),
           assigned_to_name = coalesce(p_assigned_to_name, assigned_to_name),
           due_at = coalesce(p_due_at, due_at),
           allowed_emails = coalesce(p_allowed_emails, allowed_emails),
           watcher_emails = coalesce(p_watcher_emails, watcher_emails),
           tags = coalesce(p_tags, tags),
           metadata = coalesce(metadata, '{}'::jsonb) || coalesce(p_metadata, '{}'::jsonb)
     where task_id = v_existing
    returning task_id into v_task_id;

    perform task_center.add_event(
      v_task_id,
      'updated_from_source',
      'Feladat frissítve forrás alapján',
      p_title,
      null,
      coalesce(p_metadata, '{}'::jsonb),
      p_created_by_email,
      p_created_by_name,
      '{}'::jsonb
    );
  end if;

  return v_task_id;
end;
$$;

-- ---------------------------------------------------------
-- 5) Kártya mozgatás / lezárás / AI job queue
-- ---------------------------------------------------------

create or replace function task_center.move_task(
  p_task_id uuid,
  p_new_status text,
  p_user_email text default null,
  p_user_name text default null,
  p_sort_order numeric default null
)
returns task_center.task_cards
language plpgsql
security definer
set search_path = task_center, public
as $$
declare
  v_old_status text;
  v_row task_center.task_cards;
begin
  select status into v_old_status
  from task_center.task_cards
  where task_id = p_task_id;

  if v_old_status is null then
    raise exception 'task_id not found: %', p_task_id;
  end if;

  update task_center.task_cards
     set status = p_new_status,
         sort_order = coalesce(p_sort_order, sort_order),
         started_at = case when p_new_status = 'in_progress' and started_at is null then now() else started_at end,
         completed_at = case when p_new_status = 'done' then now() else completed_at end
   where task_id = p_task_id
   returning * into v_row;

  perform task_center.add_event(
    p_task_id,
    'status_changed',
    'Státusz módosítva',
    null,
    jsonb_build_object('status', v_old_status),
    jsonb_build_object('status', p_new_status),
    p_user_email,
    p_user_name,
    '{}'::jsonb
  );

  return v_row;
end;
$$;

create or replace function task_center.close_task(
  p_task_id uuid,
  p_user_email text default null,
  p_user_name text default null,
  p_note text default null
)
returns task_center.task_cards
language plpgsql
security definer
set search_path = task_center, public
as $$
declare
  v_row task_center.task_cards;
begin
  update task_center.task_cards
     set status = 'done',
         completed_at = coalesce(completed_at, now())
   where task_id = p_task_id
   returning * into v_row;

  if v_row.task_id is null then
    raise exception 'task_id not found: %', p_task_id;
  end if;

  perform task_center.add_event(
    p_task_id,
    'closed',
    'Feladat lezárva',
    p_note,
    null,
    jsonb_build_object('status', 'done'),
    p_user_email,
    p_user_name,
    '{}'::jsonb
  );

  return v_row;
end;
$$;

create or replace function task_center.queue_agent_job(
  p_task_id uuid,
  p_agent_key text default 'task_center_agent',
  p_job_type text default 'prepare_next_steps',
  p_requested_by_email text default null,
  p_input_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = task_center, public
as $$
declare
  v_job_id uuid;
begin
  insert into task_center.agent_jobs (
    task_id,
    agent_key,
    job_type,
    status,
    requested_by_email,
    input_payload
  ) values (
    p_task_id,
    coalesce(p_agent_key, 'task_center_agent'),
    coalesce(p_job_type, 'prepare_next_steps'),
    'queued',
    p_requested_by_email,
    coalesce(p_input_payload, '{}'::jsonb)
  ) returning agent_job_id into v_job_id;

  update task_center.task_cards
     set ai_state = 'queued'
   where task_id = p_task_id;

  perform task_center.add_event(
    p_task_id,
    'agent_queued',
    'AI agent előkészítés sorba állítva',
    p_job_type,
    null,
    jsonb_build_object('agent_job_id', v_job_id, 'agent_key', p_agent_key, 'job_type', p_job_type),
    p_requested_by_email,
    null,
    '{}'::jsonb
  );

  return v_job_id;
end;
$$;

-- ---------------------------------------------------------
-- 6) Retool / HTML dashboard olvasó függvény
-- ---------------------------------------------------------

create or replace function task_center.retool_get_cards(
  p_user_email text default null,
  p_module_key text default 'all',
  p_status text default 'all',
  p_search text default null,
  p_include_done boolean default true,
  p_limit integer default 500
)
returns table (
  task_id uuid,
  title text,
  description text,
  module_key text,
  module_label text,
  source_schema text,
  source_table text,
  source_pk text,
  source_url text,
  status text,
  status_label text,
  priority text,
  priority_label text,
  assigned_to_email text,
  assigned_to_name text,
  due_at timestamptz,
  tags jsonb,
  metadata jsonb,
  ai_state text,
  ai_summary text,
  ai_suggestion jsonb,
  comment_count bigint,
  notification_state text,
  created_at timestamptz,
  updated_at timestamptz,
  sort_order numeric
)
language sql
security definer
set search_path = task_center, public
as $$
  select
    c.task_id,
    c.title,
    c.description,
    c.module_key,
    c.module_label,
    c.source_schema,
    c.source_table,
    c.source_pk,
    c.source_url,
    c.status,
    c.status_label,
    c.priority,
    c.priority_label,
    c.assigned_to_email,
    c.assigned_to_name,
    c.due_at,
    c.tags,
    c.metadata,
    c.ai_state,
    c.ai_summary,
    c.ai_suggestion,
    coalesce(ev.comment_count, 0) as comment_count,
    c.notification_state,
    c.created_at,
    c.updated_at,
    c.sort_order
  from task_center.task_cards c
  left join lateral (
    select count(*)::bigint as comment_count
    from task_center.task_events e
    where e.task_id = c.task_id
      and e.event_type in ('comment', 'note', 'agent_ready', 'status_changed')
  ) ev on true
  where c.archived_at is null
    and (p_include_done = true or c.status <> 'done')
    and (p_module_key is null or p_module_key in ('', 'all', 'Összes') or c.module_key = p_module_key)
    and (p_status is null or p_status in ('', 'all', 'Összes') or c.status = p_status)
    and (
      coalesce(p_user_email, '') = ''
      or c.is_private = false
      or lower(c.assigned_to_email) = lower(p_user_email)
      or lower(c.created_by_email) = lower(p_user_email)
      or lower(p_user_email) = any (select lower(x) from unnest(c.allowed_emails) x)
      or lower(p_user_email) = any (select lower(x) from unnest(c.watcher_emails) x)
    )
    and (
      nullif(trim(coalesce(p_search, '')), '') is null
      or lower(c.title) like '%' || lower(p_search) || '%'
      or lower(coalesce(c.description, '')) like '%' || lower(p_search) || '%'
      or lower(coalesce(c.module_label, '')) like '%' || lower(p_search) || '%'
      or lower(coalesce(c.source_pk, '')) like '%' || lower(p_search) || '%'
      or c.tags::text ilike '%' || p_search || '%'
      or c.metadata::text ilike '%' || p_search || '%'
    )
  order by
    case c.priority when 'critical' then 1 when 'high' then 2 when 'normal' then 3 else 4 end,
    c.due_at asc nulls last,
    c.sort_order asc,
    c.created_at desc
  limit greatest(1, least(coalesce(p_limit, 500), 2000));
$$;

create or replace view task_center.v_retool_task_cards as
select *
from task_center.retool_get_cards(null, 'all', 'all', null, true, 2000);

-- ---------------------------------------------------------
-- 7) Mintakártyák - biztonságos, csak akkor tölt, ha még üres.
-- ---------------------------------------------------------

do $$
begin
  if not exists (select 1 from task_center.task_cards) then
    perform task_center.upsert_task_from_source(
      'UAHUN: Hiányzó útlevél ellenőrzése',
      'Új UAHUN ügyben hiányzik vagy ellenőrzésre vár az útlevél adat.',
      'uahun', 'UAHUN', 'public', 'workflow_cases', 'demo-uahun-passport', null,
      'new', 'critical', null, null, 'system@hdd.local', 'System', now() + interval '4 hours',
      '{}', '{}', '["UAHUN", "Okmány"]'::jsonb, '{"demo": true}'::jsonb
    );

    perform task_center.upsert_task_from_source(
      'Szállás: Ár nélküli cím javítása',
      'A szállás címhez nincs nettó ár vagy ár label rögzítve.',
      'housing', 'Szállás', 'housing', 'addresses', 'demo-housing-price', null,
      'new', 'high', null, null, 'system@hdd.local', 'System', now() + interval '1 day',
      '{}', '{}', '["Szállás", "Ár"]'::jsonb, '{"demo": true}'::jsonb
    );

    perform task_center.upsert_task_from_source(
      'P01 → P02 átemelés ellenőrzése',
      'Ellenőrizni kell, hogy a planned_personnel rekordból helyesen jött-e létre az actual / workflow környezet.',
      'project', 'Projekt', 'planned', 'planned_personnel', 'demo-p01-p02', null,
      'in_progress', 'high', null, 'Gál Balázs', 'system@hdd.local', 'System', now() + interval '8 hours',
      '{}', '{}', '["Átemelés", "Validáció", "AI"]'::jsonb, '{"demo": true}'::jsonb
    );

    perform task_center.upsert_task_from_source(
      'AI: Adatkinyerés – Szállás árlista',
      'AI agent előkészítés: árlista beolvasása és címekhez kötése.',
      'ai', 'AI előkészítés', 'task_center', 'agent_jobs', 'demo-ai-housing-prices', null,
      'ai_preparing', 'normal', null, null, 'system@hdd.local', 'System', now() + interval '2 days',
      '{}', '{}', '["AI", "Szállás"]'::jsonb, '{"demo": true}'::jsonb
    );

    update task_center.task_cards
       set ai_state = 'suggested',
           ai_summary = 'Az AI szerint ez a feladat gyorsan előkészíthető, ha a forrásrekord és a kapcsolódó dokumentumok elérhetők.'
     where title like 'AI:%' or title like 'P01%';
  end if;
end $$;
