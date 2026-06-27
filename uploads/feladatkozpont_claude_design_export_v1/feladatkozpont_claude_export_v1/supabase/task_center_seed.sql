-- Demo seed for Feladatközpont

insert into task_center.boards(board_code, board_name)
values ('main_user_dashboard', 'Feladatközpont')
on conflict (board_code) do update set board_name = excluded.board_name;

with b as (
  select board_id from task_center.boards where board_code = 'main_user_dashboard'
)
insert into task_center.board_members(board_id, external_user_key, display_name, initials, color, role_label, permission_level, is_online)
select b.board_id, x.external_user_key, x.display_name, x.initials, x.color, x.role_label, x.permission_level, x.is_online
from b
cross join (values
  ('me','Én','ÉN','#193b69','Saját user','owner',true),
  ('gb','Gál Balázs','GB','#193b69','Board member','member',true),
  ('km','Kovács Míra','KM','#d85c38','Board member','member',true),
  ('an','Admin Nóra','AN','#5868c9','Jóváhagyó','manager',false),
  ('cs','Csapat','CS','#2d9861','Csoport','member',true),
  ('mk','Minta Kitti','MK','#8757e8','Megfigyelő','viewer',false)
) as x(external_user_key, display_name, initials, color, role_label, permission_level, is_online)
on conflict (board_id, external_user_key) do update
set display_name = excluded.display_name,
    initials = excluded.initials,
    color = excluded.color,
    role_label = excluded.role_label,
    permission_level = excluded.permission_level,
    is_online = excluded.is_online;

select task_center.upsert_task_from_source(
  'main_user_dashboard','demo','case','SRC-001',
  'Minta feladat: új ügy ellenőrzése',
  'Placeholder kártya. Később bármelyik Supabase rekordból automatikusan jöhet ilyen feladat.',
  'new','critical','case','me', now() + interval '3 hours', 'Ma 10:00', array['új','ellenőrzés'], '{"demo":true}'::jsonb
);

select task_center.upsert_task_from_source(
  'main_user_dashboard','demo','record','SRC-002',
  'Hiányzó adat pótlása',
  'Dokumentum vagy mezőhiány placeholder.',
  'new','high','document','km', now() + interval '8 hours', 'Ma 14:30', array['adat','hiányzó'], '{"demo":true}'::jsonb
);

select task_center.upsert_task_from_source(
  'main_user_dashboard','demo','approval','SRC-004',
  'Jóváhagyás: rekord ellenőrzése',
  'Jóváhagyási folyamat placeholder.',
  'waiting','high','operation','an', now() + interval '1 day', 'Holnap', array['jóváhagyás'], '{"demo":true}'::jsonb
);

select task_center.upsert_task_from_source(
  'main_user_dashboard','demo','agent_job','SRC-005',
  'AI: ellenőrző lista előkészítése',
  'Agent queue bekötési pont mintája.',
  'ai_preparing','normal','ai','me', now() + interval '5 hours', 'Ma 17:00', array['AI','agent'], '{"demo":true}'::jsonb
);
