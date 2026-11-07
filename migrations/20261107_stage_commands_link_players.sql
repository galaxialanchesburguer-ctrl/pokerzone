-- Vincula as comandas de etapas com jogadores aos jogadores cadastrados na própria etapa.
ALTER TABLE public.stage_commands
  ADD COLUMN IF NOT EXISTS tournament_player_id uuid REFERENCES public.players(id) ON DELETE SET NULL;

-- Aproveita as comandas existentes, associando-as aos jogadores pela posição na etapa.
WITH ranked_players AS (
  SELECT r.stage_id, r.player_id,
         row_number() OVER (PARTITION BY r.stage_id ORDER BY r.position, r.player_id) AS rn
  FROM public.results r
)
UPDATE public.stage_commands c
SET tournament_player_id = rp.player_id
FROM ranked_players rp
WHERE c.stage_id = rp.stage_id
  AND c.command_number = rp.rn
  AND c.tournament_player_id IS NULL;

-- Atualiza também os lançamentos antigos para refletir o jogador da comanda.
UPDATE public.club_player_ledger l
SET tournament_player_id = c.tournament_player_id
FROM public.stage_commands c
WHERE l.stage_command_id = c.id
  AND l.tournament_player_id IS NULL
  AND c.tournament_player_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS stage_commands_stage_player_idx
  ON public.stage_commands(stage_id, tournament_player_id);
