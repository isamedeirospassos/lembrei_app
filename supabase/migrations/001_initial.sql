-- supabase/migrations/001_initial.sql

-- Extensão para geolocalização
create extension if not exists postgis;

-- Tabela de perfis de usuário
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  avatar_url text,
  created_at timestamptz default now()
);

-- Tabela principal de lembretes
create table public.reminders (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,

  -- Conteúdo
  raw_text text not null,              -- "me lembra de levar o carregador quando eu sair"
  task text not null,                  -- "Levar o carregador"
  context_note text,                   -- "quando sair de casa"

  -- Tempo
  trigger_type text not null           -- 'datetime' | 'location' | 'context' | 'manual'
    check (trigger_type in ('datetime', 'location', 'context', 'manual')),
  scheduled_at timestamptz,            -- para lembretes com hora definida
  recurrence text,                     -- 'daily' | 'weekly' | null

  -- Localização
  location_name text,                  -- "mercado", "casa", "trabalho"
  location_lat double precision,
  location_lng double precision,
  location_radius_meters int default 200,

  -- IA
  ai_priority text default 'medium'    -- 'low' | 'medium' | 'high'
    check (ai_priority in ('low', 'medium', 'high')),
  ai_tags text[],                      -- ['compras', 'casa', 'pessoa']
  ai_confidence float,                 -- 0.0 a 1.0

  -- Status
  is_done boolean default false,
  is_snoozed boolean default false,
  snoozed_until timestamptz,
  notified_at timestamptz,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS (Row Level Security)
alter table public.profiles enable row level security;
alter table public.reminders enable row level security;

create policy "Usuário vê apenas seus dados"
  on public.profiles for all
  using (auth.uid() = id);

create policy "Usuário vê apenas seus lembretes"
  on public.reminders for all
  using (auth.uid() = user_id);

-- Trigger para atualizar updated_at
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger reminders_updated_at
  before update on public.reminders
  for each row execute function update_updated_at();

-- Índices
create index reminders_user_id_idx on public.reminders(user_id);
create index reminders_scheduled_at_idx on public.reminders(scheduled_at);
create index reminders_is_done_idx on public.reminders(is_done);