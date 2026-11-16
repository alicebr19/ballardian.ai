-- Ballardian: database schema for Supabase (Postgres).
-- Run once in the Supabase SQL editor. Safe to re-run.
-- Access rules live here, not in the page: the browser only ever holds the public anon key.

-- ---------------------------------------------------------------- tables
create table if not exists public.site_admins (
  email text primary key                       -- people who become admin when they first sign in
);

create table if not exists public.profiles (
  id           uuid primary key references auth.users on delete cascade,
  handle       text unique not null check (handle ~ '^[a-z0-9_]{2,24}$'),
  display_name text not null check (char_length(display_name) between 1 and 60),
  bio          text not null default '' check (char_length(bio) <= 400),
  x_handle     text,                           -- set only from a verified X sign-in, never typed
  avatar_url   text,
  role         text not null default 'member' check (role in ('member','writer','admin')),
  created_at   timestamptz not null default now()
);

create table if not exists public.essays (
  id           uuid primary key default gen_random_uuid(),
  author_id    uuid not null default auth.uid() references public.profiles on delete cascade,
  slug         text unique not null check (slug ~ '^[a-z0-9-]{1,80}$'),
  title        text not null check (char_length(title) between 1 and 200),
  subtitle     text not null default '' check (char_length(subtitle) <= 300),
  body         text not null default '' check (char_length(body) <= 200000),
  excerpt      text not null default '',
  word_count   int  not null default 0,
  status       text not null default 'draft' check (status in ('draft','published')),
  published_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists essays_published_idx on public.essays (published_at desc) where status = 'published';

-- Essays shared from Substack: the entry carries the link and its details, not the text.
alter table public.essays add column if not exists kind text not null default 'essay' check (kind in ('essay','substack'));
alter table public.essays add column if not exists external_url text check (external_url is null or (external_url ~ '^https://[A-Za-z0-9.-]+/p/[A-Za-z0-9%_-]+$' and char_length(external_url) <= 300));
alter table public.essays add column if not exists cover_url text check (cover_url is null or (cover_url ~ '^https://(substackcdn\.com|substack-post-media\.s3\.amazonaws\.com)/' and char_length(cover_url) <= 1000));
alter table public.essays add column if not exists source_author text check (source_author is null or char_length(source_author) <= 120);
alter table public.essays add column if not exists source_words int check (source_words is null or source_words between 0 and 1000000);
alter table public.essays add column if not exists source_date timestamptz;
-- Entries can also point at writing on other sites ('link'), carry the name of the publication,
-- and be added from the dashboard without a member account (author_id empty).
alter table public.essays alter column author_id drop not null;
alter table public.essays add column if not exists source_name text;
alter table public.essays drop constraint if exists essays_source_name_check;
alter table public.essays add constraint essays_source_name_check check (source_name is null or char_length(source_name) <= 80);
alter table public.essays drop constraint if exists essays_kind_check;
alter table public.essays add constraint essays_kind_check check (kind in ('essay','substack','link'));
alter table public.essays drop constraint if exists essays_external_url_check;
alter table public.essays add constraint essays_external_url_check check (external_url is null or (external_url ~ '^https://[A-Za-z0-9.-]+(/[^[:space:]"<>]*)?$' and char_length(external_url) <= 500));
alter table public.essays drop constraint if exists essays_cover_url_check;
alter table public.essays add constraint essays_cover_url_check check (cover_url is null or (cover_url ~ '^https://(substackcdn\.com|substack-post-media\.s3\.amazonaws\.com|images\.squarespace-cdn\.com)/' and char_length(cover_url) <= 1000));
alter table public.essays drop constraint if exists essays_kind_matches_link;
alter table public.essays add constraint essays_kind_matches_link check ((kind = 'essay' and external_url is null) or (kind <> 'essay' and external_url is not null));
create unique index if not exists essays_external_url_key on public.essays (external_url) where external_url is not null;

create table if not exists public.threads (
  id          uuid primary key default gen_random_uuid(),
  author_id   uuid not null default auth.uid() references public.profiles on delete cascade,
  title       text not null check (char_length(title) between 4 and 200),
  body        text not null default '' check (char_length(body) <= 10000),
  topic       text check (topic is null or char_length(topic) between 1 and 24),
  essay_slug  text check (essay_slug is null or essay_slug ~ '^[a-z0-9-]{1,80}$'),
  score       int not null default 0,
  reply_count int not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists threads_created_idx on public.threads (created_at desc);

-- Ballard this week: an admin posts a line of his against the week's news as a special thread
-- (kind 'weekly'). It carries the quotation, where it is from, and a link to the news story;
-- the thread's body is the question put to readers, and their takes are ordinary replies.
alter table public.threads add column if not exists kind text not null default 'thread';
alter table public.threads drop constraint if exists threads_kind_check;
alter table public.threads add constraint threads_kind_check check (kind in ('thread','weekly'));
alter table public.threads add column if not exists quote text;
alter table public.threads add column if not exists quote_source text;
alter table public.threads add column if not exists link_url text;
alter table public.threads drop constraint if exists threads_weekly_check;
alter table public.threads add constraint threads_weekly_check check (
  (kind = 'thread' and quote is null and quote_source is null and link_url is null) or
  (kind = 'weekly' and quote is not null and char_length(quote) between 1 and 1500 and (quote_source is null or char_length(quote_source) <= 200)
     and (link_url is null or (link_url ~ '^https://[A-Za-z0-9.-]+(/[^[:space:]"<>]*)?$' and char_length(link_url) <= 500))));
create index if not exists threads_weekly_idx on public.threads (created_at desc) where kind = 'weekly';

-- A thread can point at one post on X; the page shows it above the discussion.
alter table public.threads add column if not exists tweet_url text check (tweet_url is null or tweet_url ~ '^https://x\.com/[A-Za-z0-9_]{1,15}/status/[0-9]{1,25}$');

create table if not exists public.replies (
  id         uuid primary key default gen_random_uuid(),
  thread_id  uuid not null references public.threads on delete cascade,
  parent_id  uuid references public.replies on delete cascade,
  author_id  uuid not null default auth.uid() references public.profiles on delete cascade,
  body       text not null check (char_length(body) between 1 and 5000),
  score      int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists replies_thread_idx on public.replies (thread_id, created_at);

-- Essays are grouped on the Essays tab by theme, each tied to a part of J.G. Ballard's work,
-- and ordered by hand inside a theme. Admins arrange them (see arrange_essay below).
create table if not exists public.themes (
  name     text primary key check (char_length(name) between 1 and 80),
  blurb    text not null default '' check (char_length(blurb) <= 300),
  position int  not null default 100
);
alter table public.essays add column if not exists theme text references public.themes (name) on update cascade on delete set null;
alter table public.essays add column if not exists sort_order int not null default 1000;
-- An essay can answer a weekly quote and prompt (a 'weekly' thread).
alter table public.essays add column if not exists prompt_id uuid references public.threads (id) on delete set null;
-- Members who are not writers can send an essay in for review ('submitted'); an admin publishes it.
alter table public.essays drop constraint if exists essays_status_check;
alter table public.essays add constraint essays_status_check check (status in ('draft','submitted','published'));

-- Optional links a member can show beside their name.
alter table public.profiles add column if not exists linkedin_url text;
alter table public.profiles add column if not exists substack_url text;
alter table public.profiles drop constraint if exists profiles_linkedin_url_check;
alter table public.profiles add constraint profiles_linkedin_url_check check (linkedin_url is null or linkedin_url ~ '^https://(www\.)?linkedin\.com/in/[A-Za-z0-9_%-]{1,100}/?$');
alter table public.profiles drop constraint if exists profiles_substack_url_check;
alter table public.profiles add constraint profiles_substack_url_check check (substack_url is null or (substack_url ~ '^https://[A-Za-z0-9.-]+/?$' and char_length(substack_url) <= 200));

create table if not exists public.thread_votes (
  user_id   uuid not null default auth.uid() references public.profiles on delete cascade,
  thread_id uuid not null references public.threads on delete cascade,
  value     smallint not null check (value in (-1, 1)),
  primary key (user_id, thread_id)
);
create index if not exists thread_votes_thread_idx on public.thread_votes (thread_id);

create table if not exists public.reply_votes (
  user_id   uuid not null default auth.uid() references public.profiles on delete cascade,
  reply_id  uuid not null references public.replies on delete cascade,
  thread_id uuid not null references public.threads on delete cascade,
  value     smallint not null check (value in (-1, 1)),
  primary key (user_id, reply_id)
);
create index if not exists reply_votes_reply_idx on public.reply_votes (reply_id);

create table if not exists public.subscribers (
  email      text primary key check (email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' and char_length(email) <= 254),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------- helpers
create or replace function public.is_writer() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.profiles where id = auth.uid() and role in ('writer','admin')) $$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') $$;

-- A profile for every new account. Email sign-ups get a neutral placeholder handle
-- (never derived from the address); X sign-ups start with their X username.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare base text; h text; n int := 0; meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  base := lower(regexp_replace(coalesce(meta->>'user_name', meta->>'preferred_username', ''), '[^a-zA-Z0-9_]', '', 'g'));
  if char_length(base) < 2 then base := 'reader' || (floor(random() * 900000) + 100000)::int::text; end if;
  base := left(base, 20); h := base;
  while exists (select 1 from public.profiles where handle = h) loop n := n + 1; h := base || n::text; end loop;
  insert into public.profiles (id, handle, display_name, avatar_url, role)
  values (new.id, h,
          left(coalesce(nullif(meta->>'name', ''), nullif(meta->>'full_name', ''), h), 60),
          coalesce(meta->>'avatar_url', meta->>'picture'),
          case when exists (select 1 from public.site_admins a where lower(a.email) = lower(new.email)) then 'admin' else 'member' end)
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- Copies the verified X username from the signed-in person's linked identity (or clears it after unlinking).
create or replace function public.sync_x() returns void
language plpgsql security definer set search_path = public as $$
declare meta jsonb;
begin
  if auth.uid() is null then return; end if;
  select i.identity_data into meta from auth.identities i
   where i.user_id = auth.uid() and i.provider in ('x', 'twitter') order by i.created_at desc limit 1;
  update public.profiles p
     set x_handle  = case when meta is null then null else coalesce(meta->>'user_name', meta->>'preferred_username', meta->>'username') end,
         avatar_url = coalesce(meta->>'avatar_url', meta->>'picture', p.avatar_url)
   where p.id = auth.uid();
end $$;

create or replace function public.arrange_essay(target uuid, new_theme text, new_order int) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Only an admin can arrange essays.'; end if;
  update public.essays set theme = nullif(btrim(coalesce(new_theme, '')), ''), sort_order = coalesce(new_order, 1000) where id = target;
end $$;

create or replace function public.set_role(target uuid, new_role text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Only an admin can change roles.'; end if;
  if new_role not in ('member','writer','admin') then raise exception 'Unknown role.'; end if;
  if target = auth.uid() then raise exception 'You cannot change your own role.'; end if;
  update public.profiles set role = new_role where id = target;
end $$;

-- Subscribing goes through this function so the list itself is never exposed,
-- and nobody can test whether an address is already on it.
create or replace function public.subscribe(addr text) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.subscribers (email) values (lower(btrim(addr))) on conflict (email) do nothing;
end $$;

-- Essay housekeeping: timestamps, excerpt, word count.
create or replace function public.essay_before_write() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  new.word_count := coalesce(array_length(regexp_split_to_array(btrim(new.body), '\s+'), 1), 0);
  if btrim(new.body) = '' then new.word_count := 0; end if;
  new.excerpt := left(btrim(regexp_replace(regexp_replace(regexp_replace(regexp_replace(new.body, '(^|\n)(#{1,3} [^\n]*|-{3,})', '\1', 'g'), '\[([^\]]+)\]\([^)]+\)', '\1', 'g'), '[#>*_`]', '', 'g'), '\s+', ' ', 'g')), 220);
  if new.status = 'published' and new.published_at is null then new.published_at := now(); end if;
  if tg_op = 'UPDATE' then new.author_id := old.author_id; new.slug := old.slug; new.created_at := old.created_at; new.kind := old.kind; end if;
  return new;
end $$;
drop trigger if exists essay_before_write on public.essays;
create trigger essay_before_write before insert or update on public.essays for each row execute function public.essay_before_write();

-- Scores and reply counts are kept by the database, so nobody can set their own.
create or replace function public.tally_thread_votes() returns trigger
language plpgsql security definer set search_path = public as $$
declare tid uuid := coalesce(new.thread_id, old.thread_id);
begin
  update public.threads t set score = coalesce((select sum(v.value) from public.thread_votes v where v.thread_id = tid), 0) where t.id = tid;
  return null;
end $$;
drop trigger if exists tally_thread_votes on public.thread_votes;
create trigger tally_thread_votes after insert or update or delete on public.thread_votes for each row execute function public.tally_thread_votes();

create or replace function public.tally_reply_votes() returns trigger
language plpgsql security definer set search_path = public as $$
declare rid uuid := coalesce(new.reply_id, old.reply_id);
begin
  update public.replies r set score = coalesce((select sum(v.value) from public.reply_votes v where v.reply_id = rid), 0) where r.id = rid;
  return null;
end $$;
drop trigger if exists tally_reply_votes on public.reply_votes;
create trigger tally_reply_votes after insert or update or delete on public.reply_votes for each row execute function public.tally_reply_votes();

create or replace function public.tally_replies() returns trigger
language plpgsql security definer set search_path = public as $$
declare tid uuid := coalesce(new.thread_id, old.thread_id);
begin
  update public.threads t set reply_count = (select count(*) from public.replies r where r.thread_id = tid) where t.id = tid;
  return null;
end $$;
drop trigger if exists tally_replies on public.replies;
create trigger tally_replies after insert or delete on public.replies for each row execute function public.tally_replies();

-- A reply must sit in the same thread as the reply it answers.
create or replace function public.reply_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.parent_id is not null and not exists (select 1 from public.replies p where p.id = new.parent_id and p.thread_id = new.thread_id) then
    raise exception 'That reply belongs to a different thread.';
  end if;
  return new;
end $$;
drop trigger if exists reply_before_insert on public.replies;
create trigger reply_before_insert before insert on public.replies for each row execute function public.reply_before_insert();

create or replace function public.reply_vote_before_write() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  select r.thread_id into new.thread_id from public.replies r where r.id = new.reply_id;
  return new;
end $$;
drop trigger if exists reply_vote_before_write on public.reply_votes;
create trigger reply_vote_before_write before insert or update on public.reply_votes for each row execute function public.reply_vote_before_write();

-- ---------------------------------------------------------------- privileges
-- Start from nothing, then grant exactly what the page needs.
revoke all on public.site_admins, public.profiles, public.essays, public.threads, public.replies,
              public.thread_votes, public.reply_votes, public.subscribers, public.themes from anon, authenticated;

grant select on public.profiles, public.essays, public.threads, public.replies, public.themes to anon, authenticated;
grant insert (name, blurb, position), update (name, blurb, position), delete on public.themes to authenticated;   -- limited to admins by the rules below
grant update (handle, display_name, bio, linkedin_url, substack_url) on public.profiles to authenticated;
grant insert (slug, title, subtitle, body, status, kind, external_url, cover_url, source_author, source_name, source_words, source_date, prompt_id),
      update (title, subtitle, body, status, external_url, cover_url, source_author, source_name, source_words, source_date), delete on public.essays to authenticated;
grant insert (title, body, topic, essay_slug, tweet_url, kind, quote, quote_source, link_url),
      update (title, body, quote, quote_source, link_url), delete on public.threads to authenticated;   -- update is limited to admins by the rule below
grant insert (thread_id, parent_id, body), delete on public.replies to authenticated;
grant select, insert, update, delete on public.thread_votes, public.reply_votes to authenticated;
grant select on public.subscribers to authenticated;      -- rows limited to admins by the rule below

revoke execute on function public.sync_x(), public.set_role(uuid, text), public.arrange_essay(uuid, text, int) from public, anon;
grant execute on function public.sync_x(), public.set_role(uuid, text), public.arrange_essay(uuid, text, int), public.is_writer(), public.is_admin() to authenticated;
grant execute on function public.is_writer(), public.is_admin(), public.subscribe(text) to anon, authenticated;

-- ---------------------------------------------------------------- row-level rules
alter table public.site_admins  enable row level security;   -- no policies: reachable only from the dashboard
alter table public.profiles     enable row level security;
alter table public.essays       enable row level security;
alter table public.threads      enable row level security;
alter table public.replies      enable row level security;
alter table public.thread_votes enable row level security;
alter table public.reply_votes  enable row level security;
alter table public.subscribers  enable row level security;
alter table public.themes       enable row level security;

drop policy if exists "profiles are public" on public.profiles;
create policy "profiles are public" on public.profiles for select using (true);
drop policy if exists "edit own profile" on public.profiles;
create policy "edit own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "read published essays and own drafts" on public.essays;
create policy "read published essays and own drafts" on public.essays for select using (status = 'published' or author_id = auth.uid() or public.is_admin());
drop policy if exists "writers add essays" on public.essays;
create policy "writers add essays" on public.essays for insert to authenticated with check (author_id = auth.uid() and (public.is_writer() or (kind = 'essay' and status in ('draft','submitted'))));
drop policy if exists "writers edit own essays" on public.essays;
create policy "writers edit own essays" on public.essays for update to authenticated using (author_id = auth.uid() or public.is_admin())
  with check ((author_id = auth.uid() and (public.is_writer() or status in ('draft','submitted'))) or public.is_admin());
drop policy if exists "remove own essays, admins any" on public.essays;
create policy "remove own essays, admins any" on public.essays for delete to authenticated using (author_id = auth.uid() or public.is_admin());

drop policy if exists "threads are public" on public.threads;
create policy "threads are public" on public.threads for select using (true);
drop policy if exists "members start threads" on public.threads;
create policy "members start threads" on public.threads for insert to authenticated with check (author_id = auth.uid() and (kind = 'thread' or public.is_admin()));
drop policy if exists "admins edit the weekly post" on public.threads;
create policy "admins edit the weekly post" on public.threads for update to authenticated using (kind = 'weekly' and public.is_admin()) with check (kind = 'weekly' and public.is_admin());
drop policy if exists "remove own threads, admins any" on public.threads;
create policy "remove own threads, admins any" on public.threads for delete to authenticated using (author_id = auth.uid() or public.is_admin());

drop policy if exists "replies are public" on public.replies;
create policy "replies are public" on public.replies for select using (true);
drop policy if exists "members reply" on public.replies;
create policy "members reply" on public.replies for insert to authenticated with check (author_id = auth.uid());
drop policy if exists "remove own replies, admins any" on public.replies;
create policy "remove own replies, admins any" on public.replies for delete to authenticated using (author_id = auth.uid() or public.is_admin());

drop policy if exists "own thread votes" on public.thread_votes;
create policy "own thread votes" on public.thread_votes for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "own reply votes" on public.reply_votes;
create policy "own reply votes" on public.reply_votes for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "admins read subscribers" on public.subscribers;
create policy "admins read subscribers" on public.subscribers for select to authenticated using (public.is_admin());


drop policy if exists "themes are public" on public.themes;
create policy "themes are public" on public.themes for select using (true);
drop policy if exists "admins add themes" on public.themes;
create policy "admins add themes" on public.themes for insert to authenticated with check (public.is_admin());
drop policy if exists "admins edit themes" on public.themes;
create policy "admins edit themes" on public.themes for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admins remove themes" on public.themes;
create policy "admins remove themes" on public.themes for delete to authenticated using (public.is_admin());
