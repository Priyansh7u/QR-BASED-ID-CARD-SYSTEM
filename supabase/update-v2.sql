-- Run this ONCE in Supabase → SQL Editor to add the new meme fields
alter table public.cards
  add column if not exists fav_food   text,
  add column if not exists friendly   text,
  add column if not exists son_of     text,
  add column if not exists husband_of text,
  add column if not exists kids       int,
  add column if not exists crush_on   text;