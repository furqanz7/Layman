create extension if not exists pgcrypto;

create table if not exists public.saved_articles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  article_id text not null,
  headline text not null,
  source text not null,
  image_url text,
  original_url text,
  plain_summary text not null,
  raw_description text not null,
  raw_content text not null,
  category text not null,
  summary_cards text[] not null,
  created_at timestamptz not null default now(),
  unique (user_id, article_id)
);

alter table public.saved_articles enable row level security;

drop policy if exists "Users can read their own saved articles" on public.saved_articles;
create policy "Users can read their own saved articles"
on public.saved_articles for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert their own saved articles" on public.saved_articles;
create policy "Users can insert their own saved articles"
on public.saved_articles for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own saved articles" on public.saved_articles;
create policy "Users can delete their own saved articles"
on public.saved_articles for delete
using (auth.uid() = user_id);
