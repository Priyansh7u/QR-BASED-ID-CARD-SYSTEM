-- Run this once in Supabase → SQL Editor

create table if not exists public.cards (
  id          text primary key,          -- random id used in the QR link (never changes)
  name        text not null,
  blood_group text,
  college     text,
  address     text,
  photo_path  text,
  fav_food    text,
  friendly    text,
  son_of      text,
  husband_of  text,
  kids        int,
  crush_on    text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Lock the table: no public access at all.
-- Only the website's server (using the service role key) can read/write.
alter table public.cards enable row level security;

-- Public bucket for profile photos (file names are random, so they can't be guessed)
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;