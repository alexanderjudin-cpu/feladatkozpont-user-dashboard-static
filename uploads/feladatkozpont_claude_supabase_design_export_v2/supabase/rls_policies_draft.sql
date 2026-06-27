-- =========================================================
-- RLS draft for task_center
-- Adjust to your Supabase auth model before production.
-- =========================================================

alter table task_center.user_profiles enable row level security;
alter table task_center.boards enable row level security;
alter table task_center.board_members enable row level security;
alter table task_center.task_cards enable row level security;
alter table task_center.task_watchers enable row level security;
alter table task_center.task_checklist_items enable row level security;
alter table task_center.task_comments enable row level security;
alter table task_center.task_events enable row level security;
alter table task_center.task_notifications enable row level security;
alter table task_center.agent_jobs enable row level security;
alter table task_center.automations enable row level security;

-- Helper: user is active board member.
create or replace function task_center.is_board_member(p_board_id uuid, p_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path = task_center, public as $$
  select exists (
    select 1
    from task_center.board_members bm
    where bm.board_id = p_board_id
      and bm.user_id = p_user_id
      and bm.is_active = true
      and bm.can_view = true
  );
$$;

-- Helper: user can edit all cards on board.
create or replace function task_center.can_edit_board(p_board_id uuid, p_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path = task_center, public as $$
  select exists (
    select 1
    from task_center.board_members bm
    where bm.board_id = p_board_id
      and bm.user_id = p_user_id
      and bm.is_active = true
      and (bm.can_edit_all = true or bm.can_manage_board = true)
  );
$$;

-- Profiles: users can see active profiles that share a board.
create policy if not exists user_profiles_select_shared_board on task_center.user_profiles
for select using (
  user_id = auth.uid()
  or exists (
    select 1
    from task_center.board_members bm1
    join task_center.board_members bm2 on bm2.board_id = bm1.board_id
    where bm1.user_id = auth.uid()
      and bm2.user_id = task_center.user_profiles.user_id
      and bm1.is_active = true
      and bm2.is_active = true
  )
);

create policy if not exists boards_select_member on task_center.boards
for select using (task_center.is_board_member(board_id));

create policy if not exists board_members_select_same_board on task_center.board_members
for select using (task_center.is_board_member(board_id));

-- Task visibility.
create policy if not exists task_cards_select_visible on task_center.task_cards
for select using (
  is_deleted = false
  and (
    assignee_user_id = auth.uid()
    or created_by_user_id = auth.uid()
    or task_center.is_board_member(board_id)
    or exists (
      select 1 from task_center.task_watchers tw
      where tw.task_id = task_center.task_cards.task_id
        and tw.user_id = auth.uid()
    )
  )
);

create policy if not exists task_cards_insert_member on task_center.task_cards
for insert with check (task_center.is_board_member(board_id));

create policy if not exists task_cards_update_owner_or_editor on task_center.task_cards
for update using (
  assignee_user_id = auth.uid()
  or created_by_user_id = auth.uid()
  or task_center.can_edit_board(board_id)
) with check (
  assignee_user_id = auth.uid()
  or created_by_user_id = auth.uid()
  or task_center.can_edit_board(board_id)
);

-- Child rows follow task visibility.
create policy if not exists checklist_select_visible on task_center.task_checklist_items
for select using (exists(select 1 from task_center.task_cards tc where tc.task_id = task_checklist_items.task_id));

create policy if not exists comments_select_visible on task_center.task_comments
for select using (exists(select 1 from task_center.task_cards tc where tc.task_id = task_comments.task_id));

create policy if not exists events_select_visible on task_center.task_events
for select using (task_id is null or exists(select 1 from task_center.task_cards tc where tc.task_id = task_events.task_id));

create policy if not exists notifications_select_recipient on task_center.task_notifications
for select using (recipient_user_id = auth.uid());

create policy if not exists agent_jobs_select_visible on task_center.agent_jobs
for select using (task_id is null or exists(select 1 from task_center.task_cards tc where tc.task_id = agent_jobs.task_id));
