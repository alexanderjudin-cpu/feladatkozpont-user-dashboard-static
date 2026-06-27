-- Demo seed. Replace user UUIDs before running in real Supabase.

insert into task_center.boards(board_key, board_title, board_description)
values ('main_user_dashboard', 'Feladatközpont', 'Alap user dashboard')
on conflict (board_key) do update set board_title = excluded.board_title;

-- Create status columns
insert into task_center.task_columns(board_id, status_key, status_label, icon, color, sort_order, is_done_column)
select b.board_id, x.status_key, x.status_label, x.icon, x.color, x.sort_order, x.is_done
from task_center.boards b
cross join (values
  ('new','Új','＋','#2f80ed',10,false),
  ('in_progress','Folyamatban','▶','#f8991c',20,false),
  ('waiting','Jóváhagyásra vár','◷','#c98912',30,false),
  ('ai_preparing','AI előkészítés','✦','#8757e8',40,false),
  ('done','Kész','✓','#20a464',50,true)
) as x(status_key,status_label,icon,color,sort_order,is_done)
where b.board_key = 'main_user_dashboard'
on conflict (board_id, status_key) do update set status_label = excluded.status_label, sort_order = excluded.sort_order;
