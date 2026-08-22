-- ============================================================
-- Migrazione 3 — ruolo delle persone: expert / pro
-- Incolla nello SQL Editor di Supabase ed esegui.
-- ============================================================

-- tutti expert per impostazione predefinita
alter table public.people
  add column if not exists role text not null default 'expert';

-- Lanfranchi è Pro (lo crea se non c'è, altrimenti aggiorna il ruolo)
insert into public.people (name, role) values ('Lanfranchi', 'pro')
  on conflict (name) do update set role = 'pro';
