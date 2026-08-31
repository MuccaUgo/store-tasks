-- ============================================================
-- Migrazione 9 — Debrief a tre liste
-- Le demo non si scelgono da un elenco: si scrivono, come le
-- altre due liste. Quelle già registrate diventano punti.
-- ============================================================

do $$
declare rec record;
begin
  if exists (select 1 from public.shift_points where kind = 'demo') then return; end if;

  for rec in
    select d.slot_id, x.demo, d.created_at
    from public.debriefs d,
         lateral jsonb_array_elements_text(coalesce(d.demos, '[]'::jsonb)) as x(demo)
    where d.slot_id is not null
  loop
    insert into public.shift_points (slot_id, kind, text, actor_name, created_at)
    values (rec.slot_id, 'demo', rec.demo, 'Nota condivisa', rec.created_at);
  end loop;
end $$;

-- la colonna resta per lo storico, ma l'app non la scrive più
comment on column public.debriefs.demos is 'storico: ora le demo sono shift_points con kind = demo';
comment on column public.debriefs.reached is 'persone invitate al tavolo';
