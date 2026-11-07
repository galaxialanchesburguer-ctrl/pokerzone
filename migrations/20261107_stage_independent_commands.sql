-- Comandas independentes por etapa: 10 iniciais e expansão sob demanda.
CREATE TABLE IF NOT EXISTS public.stage_commands (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 stage_id uuid NOT NULL REFERENCES public.stages(id) ON DELETE CASCADE,
 club_id uuid NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
 command_number integer NOT NULL CHECK(command_number>0),
 club_player_id uuid REFERENCES public.club_players(id) ON DELETE SET NULL,
 created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(stage_id,command_number)
);
ALTER TABLE public.stage_commands ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS stage_commands_manage ON public.stage_commands;
CREATE POLICY stage_commands_manage ON public.stage_commands FOR ALL TO authenticated
USING(public.can_manage_stage(stage_id))
WITH CHECK(public.can_manage_stage(stage_id) AND EXISTS(
 SELECT 1 FROM public.stages s JOIN public.seasons se ON se.id=s.season_id
 JOIN public.tournaments t ON t.id=se.tournament_id
 WHERE s.id=stage_commands.stage_id AND t.club_id=stage_commands.club_id
));
ALTER TABLE public.club_player_ledger ADD COLUMN IF NOT EXISTS stage_command_id uuid REFERENCES public.stage_commands(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS stage_commands_stage_number_idx ON public.stage_commands(stage_id,command_number);
CREATE INDEX IF NOT EXISTS club_player_ledger_stage_command_idx ON public.club_player_ledger(stage_id,stage_command_id);
DROP POLICY IF EXISTS club_player_ledger_stage_commands ON public.club_player_ledger;
CREATE POLICY club_player_ledger_stage_commands ON public.club_player_ledger FOR ALL TO authenticated
USING(stage_command_id IS NOT NULL AND EXISTS(
 SELECT 1 FROM public.stage_commands c WHERE c.id=club_player_ledger.stage_command_id
 AND c.stage_id=club_player_ledger.stage_id AND public.can_manage_stage(c.stage_id)
))
WITH CHECK(stage_command_id IS NOT NULL AND EXISTS(
 SELECT 1 FROM public.stage_commands c WHERE c.id=club_player_ledger.stage_command_id
 AND c.stage_id=club_player_ledger.stage_id AND public.can_manage_stage(c.stage_id)
 AND c.club_player_id=club_player_ledger.club_player_id
));
CREATE OR REPLACE FUNCTION public.create_initial_stage_commands()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_club_id uuid;
BEGIN
 SELECT t.club_id INTO v_club_id FROM public.seasons se JOIN public.tournaments t ON t.id=se.tournament_id WHERE se.id=NEW.season_id;
 IF v_club_id IS NOT NULL THEN
  INSERT INTO public.stage_commands(stage_id,club_id,command_number)
  SELECT NEW.id,v_club_id,n FROM generate_series(1,10) AS n
  ON CONFLICT(stage_id,command_number) DO NOTHING;
 END IF;
 RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS stages_create_initial_commands ON public.stages;
CREATE TRIGGER stages_create_initial_commands AFTER INSERT ON public.stages
FOR EACH ROW EXECUTE FUNCTION public.create_initial_stage_commands();
