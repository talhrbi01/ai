create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (char_length(username) between 3 and 32),
  display_name text not null check (char_length(display_name) between 1 and 80),
  bio text not null default '' check (char_length(bio) <= 500),
  country_code text not null default 'SA' check (country_code ~ '^[A-Z]{2}$'),
  avatar_path text,
  is_private boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  language_code text not null default 'ar',
  timezone_name text not null default 'Asia/Riyadh',
  theme text not null default 'system' check (theme in ('system', 'light', 'dark')),
  quiet_hours_start time,
  quiet_hours_end time,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.media_cache (
  id bigint primary key,
  media_type text not null check (media_type in ('movie', 'series')),
  title text not null,
  original_title text,
  overview text not null default '',
  poster_path text,
  backdrop_path text,
  release_date date,
  vote_average numeric(3,1) not null default 0 check (vote_average between 0 and 10),
  payload jsonb not null default '{}'::jsonb,
  fetched_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.watch_status (
  user_id uuid not null references public.profiles(id) on delete cascade,
  media_id bigint not null references public.media_cache(id) on delete cascade,
  status text not null check (status in ('plan_to_watch', 'watching', 'completed', 'on_hold', 'dropped', 'rewatching')),
  started_at timestamptz,
  completed_at timestamptz,
  current_season integer not null default 0 check (current_season >= 0),
  current_episode integer not null default 0 check (current_episode >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, media_id)
);

create table if not exists public.watch_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  media_id bigint not null references public.media_cache(id) on delete cascade,
  season_number integer check (season_number is null or season_number >= 0),
  episode_number integer check (episode_number is null or episode_number >= 0),
  watched_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.ratings (
  user_id uuid not null references public.profiles(id) on delete cascade,
  media_id bigint not null references public.media_cache(id) on delete cascade,
  score numeric(2,1) not null check (score between 0 and 10),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, media_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  media_id bigint not null references public.media_cache(id) on delete cascade,
  parent_id uuid references public.comments(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  season_number integer,
  episode_number integer,
  contains_spoilers boolean not null default false,
  is_hidden boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.comment_likes (
  comment_id uuid not null references public.comments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (comment_id, user_id)
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table if not exists public.custom_lists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  description text not null default '' check (char_length(description) <= 1000),
  visibility text not null default 'private' check (visibility in ('public', 'private', 'unlisted')),
  cover_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.custom_list_items (
  list_id uuid not null references public.custom_lists(id) on delete cascade,
  media_id bigint not null references public.media_cache(id) on delete cascade,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (list_id, media_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists watch_status_user_updated_idx on public.watch_status(user_id, updated_at desc);
create index if not exists watch_history_user_watched_idx on public.watch_history(user_id, watched_at desc);
create index if not exists comments_media_created_idx on public.comments(media_id, created_at desc);
create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
drop trigger if exists settings_updated_at on public.user_settings;
create trigger settings_updated_at before update on public.user_settings for each row execute procedure public.set_updated_at();
drop trigger if exists media_cache_updated_at on public.media_cache;
create trigger media_cache_updated_at before update on public.media_cache for each row execute procedure public.set_updated_at();
drop trigger if exists watch_status_updated_at on public.watch_status;
create trigger watch_status_updated_at before update on public.watch_status for each row execute procedure public.set_updated_at();
drop trigger if exists ratings_updated_at on public.ratings;
create trigger ratings_updated_at before update on public.ratings for each row execute procedure public.set_updated_at();
drop trigger if exists comments_updated_at on public.comments;
create trigger comments_updated_at before update on public.comments for each row execute procedure public.set_updated_at();
drop trigger if exists lists_updated_at on public.custom_lists;
create trigger lists_updated_at before update on public.custom_lists for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.media_cache enable row level security;
alter table public.watch_status enable row level security;
alter table public.watch_history enable row level security;
alter table public.ratings enable row level security;
alter table public.comments enable row level security;
alter table public.comment_likes enable row level security;
alter table public.follows enable row level security;
alter table public.custom_lists enable row level security;
alter table public.custom_list_items enable row level security;
alter table public.notifications enable row level security;

create policy "profiles are readable when public or self" on public.profiles for select using (
  id = auth.uid() or not is_private
);
create policy "users update own profile" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy "users insert own profile" on public.profiles for insert with check (id = auth.uid());

create policy "users manage own settings" on public.user_settings for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "media cache is readable" on public.media_cache for select using (true);
create policy "users manage own watch status" on public.watch_status for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage own watch history" on public.watch_history for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "ratings are readable" on public.ratings for select using (true);
create policy "users manage own ratings" on public.ratings for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "visible comments are readable" on public.comments for select using (not is_hidden and deleted_at is null);
create policy "users manage own comments" on public.comments for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage own comment likes" on public.comment_likes for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "follows are readable" on public.follows for select using (follower_id = auth.uid() or following_id = auth.uid());
create policy "users manage own follows" on public.follows for all using (follower_id = auth.uid()) with check (follower_id = auth.uid());
create policy "public or owned lists are readable" on public.custom_lists for select using (
  owner_id = auth.uid() or visibility = 'public'
);
create policy "users manage own lists" on public.custom_lists for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "list items follow list access" on public.custom_list_items for select using (
  exists (select 1 from public.custom_lists l where l.id = list_id and (l.owner_id = auth.uid() or l.visibility = 'public'))
);
create policy "owners manage list items" on public.custom_list_items for all using (
  exists (select 1 from public.custom_lists l where l.id = list_id and l.owner_id = auth.uid())
) with check (
  exists (select 1 from public.custom_lists l where l.id = list_id and l.owner_id = auth.uid())
);
create policy "users read own notifications" on public.notifications for select using (user_id = auth.uid());
create policy "users update own notifications" on public.notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Social, calendar, provider, notification, and moderation tables.
create table if not exists public.user_streaming_providers (
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider_id bigint not null,
  country_code text not null check (country_code ~ '^[A-Z]{2}$'),
  enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, provider_id, country_code)
);

create table if not exists public.seasons_cache (
  id bigint primary key,
  media_id bigint not null references public.media_cache(id) on delete cascade,
  season_number integer not null check (season_number >= 0),
  name text not null,
  episode_count integer not null default 0 check (episode_count >= 0),
  air_date date,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default timezone('utc', now()),
  unique (media_id, season_number)
);

create table if not exists public.episodes_cache (
  id bigint primary key,
  media_id bigint not null references public.media_cache(id) on delete cascade,
  season_number integer not null check (season_number >= 0),
  episode_number integer not null check (episode_number >= 0),
  name text not null,
  overview text not null default '',
  air_date date,
  runtime_minutes integer check (runtime_minutes is null or runtime_minutes >= 0),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default timezone('utc', now()),
  unique (media_id, season_number, episode_number)
);

create table if not exists public.follow_requests (
  requester_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (requester_id, recipient_id),
  check (requester_id <> recipient_id)
);

create table if not exists public.blocked_users (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table if not exists public.muted_users (
  muter_id uuid not null references public.profiles(id) on delete cascade,
  muted_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (muter_id, muted_id),
  check (muter_id <> muted_id)
);

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null,
  media_id bigint references public.media_cache(id) on delete set null,
  payload jsonb not null default '{}'::jsonb,
  is_public boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.custom_list_collaborators (
  list_id uuid not null references public.custom_lists(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'editor' check (role in ('editor', 'viewer')),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (list_id, user_id)
);

create table if not exists public.list_follows (
  list_id uuid not null references public.custom_lists(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (list_id, user_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('user', 'comment', 'list', 'media')),
  target_id text not null,
  reason text not null check (char_length(reason) between 1 and 500),
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz not null default timezone('utc', now()),
  resolved_at timestamptz
);

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  episode_reminders boolean not null default true,
  episode_releases boolean not null default true,
  social_activity boolean not null default true,
  comments_and_replies boolean not null default true,
  follows boolean not null default true,
  quiet_hours_start time,
  quiet_hours_end time,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.achievements (
  id text primary key,
  title_key text not null,
  description_key text not null,
  icon_name text not null,
  threshold numeric,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_achievements (
  user_id uuid not null references public.profiles(id) on delete cascade,
  achievement_id text not null references public.achievements(id) on delete cascade,
  earned_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, achievement_id)
);

create table if not exists public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check (platform in ('ios', 'web', 'admin')),
  app_version text not null,
  last_seen_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.push_tokens (
  device_id uuid primary key references public.devices(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  environment text not null default 'development' check (environment in ('development', 'production')),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.admin_actions (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles(id) on delete restrict,
  action text not null,
  target_type text,
  target_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists episodes_media_air_date_idx on public.episodes_cache(media_id, air_date);
create index if not exists activities_created_idx on public.activities(created_at desc);
create index if not exists reports_status_created_idx on public.reports(status, created_at desc);
create index if not exists push_tokens_user_idx on public.push_tokens(user_id);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

drop trigger if exists follow_requests_updated_at on public.follow_requests;
create trigger follow_requests_updated_at before update on public.follow_requests for each row execute procedure public.set_updated_at();
drop trigger if exists notification_preferences_updated_at on public.notification_preferences;
create trigger notification_preferences_updated_at before update on public.notification_preferences for each row execute procedure public.set_updated_at();

alter table public.user_streaming_providers enable row level security;
alter table public.seasons_cache enable row level security;
alter table public.episodes_cache enable row level security;
alter table public.follow_requests enable row level security;
alter table public.blocked_users enable row level security;
alter table public.muted_users enable row level security;
alter table public.activities enable row level security;
alter table public.custom_list_collaborators enable row level security;
alter table public.list_follows enable row level security;
alter table public.reports enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.devices enable row level security;
alter table public.push_tokens enable row level security;
alter table public.admin_actions enable row level security;

create policy "users manage own streaming providers" on public.user_streaming_providers for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "season cache is readable" on public.seasons_cache for select using (true);
create policy "episode cache is readable" on public.episodes_cache for select using (true);
create policy "participants manage follow requests" on public.follow_requests for all using (requester_id = auth.uid() or recipient_id = auth.uid()) with check (requester_id = auth.uid() or recipient_id = auth.uid());
create policy "users manage own blocks" on public.blocked_users for all using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());
create policy "users manage own mutes" on public.muted_users for all using (muter_id = auth.uid()) with check (muter_id = auth.uid());
create policy "public activities are readable" on public.activities for select using (
  user_id = auth.uid() or (is_public and exists (select 1 from public.profiles p where p.id = user_id and not p.is_private))
);
create policy "users create own activities" on public.activities for insert with check (user_id = auth.uid());
create policy "list collaborators are visible to members" on public.custom_list_collaborators for select using (
  user_id = auth.uid() or exists (select 1 from public.custom_lists l where l.id = list_id and l.owner_id = auth.uid())
);
create policy "list owners manage collaborators" on public.custom_list_collaborators for all using (
  exists (select 1 from public.custom_lists l where l.id = list_id and l.owner_id = auth.uid())
) with check (
  exists (select 1 from public.custom_lists l where l.id = list_id and l.owner_id = auth.uid())
);
create policy "public list follows are readable" on public.list_follows for select using (
  user_id = auth.uid() or exists (select 1 from public.custom_lists l where l.id = list_id and l.visibility = 'public')
);
create policy "users manage own list follows" on public.list_follows for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users create own reports" on public.reports for insert with check (reporter_id = auth.uid());
create policy "users read own reports" on public.reports for select using (reporter_id = auth.uid());
create policy "users manage own notification preferences" on public.notification_preferences for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "achievements are readable" on public.achievements for select using (true);
create policy "earned achievements follow profile visibility" on public.user_achievements for select using (
  user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = user_id and not p.is_private)
);
create policy "users manage own devices" on public.devices for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage own push tokens" on public.push_tokens for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "admins manage admin actions" on public.admin_actions for all using (public.is_admin()) with check (public.is_admin());
