-- Dados adicionais do cadastro rápido de clientes das comandas
ALTER TABLE public.club_players
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS notes text;
