-- PokerZone: vínculo entre a comanda da etapa, o cliente e o atendente.
-- Execute este arquivo no SQL Editor do Supabase antes de usar as novas comandas.

alter table public.club_player_ledger
  add column if not exists tournament_player_id uuid
    references public.players(id) on delete set null,
  add column if not exists attendant_name text;

create index if not exists club_player_ledger_stage_tournament_player_idx
  on public.club_player_ledger (stage_id, tournament_player_id);

