-- ============================================================
-- OBINWANNEM FOUNDATION WORLDWIDE
-- Supabase Database Schema
-- Run this in your Supabase SQL Editor (supabase.com/dashboard)
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- PROFILES TABLE
-- Extends Supabase auth.users with member data
-- ============================================================
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  -- Personal Info
  full_name text not null,
  display_name text,
  email text not null,
  phone text,
  date_of_birth date,
  gender text check (gender in ('male','female','non-binary','prefer-not-to-say')),
  avatar_url text,
  bio text,

  -- Location
  country text,
  city text,
  state_province text,

  -- Igbo Identity
  state_of_origin text,    -- e.g. Enugu, Anambra, Imo, Abia, Ebonyi, Delta, Rivers
  lga text,                -- Local Government Area
  village_town text,
  clan text,
  igbo_language_level text check (igbo_language_level in ('none','basic','conversational','fluent','native')),

  -- Membership
  membership_tier text not null default 'friend'
    check (membership_tier in ('friend','associate','full_member','patron','founding_fellow')),
  membership_status text not null default 'pending'
    check (membership_status in ('pending','active','expired','suspended')),
  membership_number text unique,
  joined_at timestamptz default now(),
  renewal_due_at timestamptz,

  -- Profile flags
  is_verified boolean default false,
  is_public boolean default true,        -- allows other members to see profile
  show_in_directory boolean default true,

  -- Social links
  linkedin_url text,
  twitter_url text,
  facebook_url text,
  website_url text,

  -- Professional
  occupation text,
  employer text,
  industry text
);

-- ============================================================
-- MEMBERSHIP PAYMENTS
-- ============================================================
create table public.membership_payments (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamptz default now(),
  member_id uuid references public.profiles(id) on delete cascade not null,
  amount numeric(10,2) not null,
  currency text default 'EUR',
  payment_method text check (payment_method in ('card','bank_transfer','paypal','cash')),
  payment_status text not null default 'pending'
    check (payment_status in ('pending','completed','failed','refunded')),
  payment_reference text,
  payment_for text check (payment_for in ('membership_dues','donation','event_ticket','other')),
  membership_tier text,
  notes text,
  period_start date,
  period_end date
);

-- ============================================================
-- EVENTS TABLE
-- ============================================================
create table public.events (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamptz default now(),
  title text not null,
  description text,
  event_type text check (event_type in ('cultural','advocacy','fundraiser','gala','summit','webinar','other')),
  location text,
  is_virtual boolean default false,
  virtual_link text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  capacity integer,
  is_members_only boolean default false,
  min_tier text default 'friend'
    check (min_tier in ('friend','associate','full_member','patron','founding_fellow')),
  image_url text,
  is_published boolean default true
);

-- ============================================================
-- EVENT REGISTRATIONS
-- ============================================================
create table public.event_registrations (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamptz default now(),
  event_id uuid references public.events(id) on delete cascade not null,
  member_id uuid references public.profiles(id) on delete cascade not null,
  status text not null default 'registered'
    check (status in ('registered','waitlisted','cancelled','attended')),
  unique(event_id, member_id)
);

-- ============================================================
-- MEMBER DIRECTORY (connection requests)
-- ============================================================
create table public.member_connections (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamptz default now(),
  requester_id uuid references public.profiles(id) on delete cascade not null,
  recipient_id uuid references public.profiles(id) on delete cascade not null,
  status text not null default 'pending'
    check (status in ('pending','accepted','declined')),
  unique(requester_id, recipient_id)
);

-- ============================================================
-- MEMBER CONTENT (exclusive articles, resources)
-- ============================================================
create table public.member_content (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamptz default now(),
  title text not null,
  slug text unique not null,
  content text,
  excerpt text,
  content_type text check (content_type in ('article','video','document','resource','newsletter')),
  min_tier text default 'friend'
    check (min_tier in ('friend','associate','full_member','patron','founding_fellow')),
  author_id uuid references public.profiles(id),
  image_url text,
  is_published boolean default true,
  published_at timestamptz default now()
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
create table public.notifications (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamptz default now(),
  member_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  message text,
  type text check (type in ('membership','event','payment','content','connection','system')),
  is_read boolean default false,
  action_url text
);

-- ============================================================
-- AUTO-GENERATE MEMBERSHIP NUMBER
-- ============================================================
create or replace function generate_membership_number()
returns trigger as $$
declare
  tier_code text;
  seq_num integer;
  new_number text;
begin
  tier_code := case new.membership_tier
    when 'friend'          then 'OFW-FR'
    when 'associate'       then 'OFW-AS'
    when 'full_member'     then 'OFW-FM'
    when 'patron'          then 'OFW-PT'
    when 'founding_fellow' then 'OFW-FF'
    else 'OFW-XX'
  end;

  select count(*) + 1000 into seq_num
  from public.profiles
  where membership_tier = new.membership_tier;

  new.membership_number := tier_code || '-' || lpad(seq_num::text, 4, '0');
  return new;
end;
$$ language plpgsql;

create trigger set_membership_number
  before insert on public.profiles
  for each row
  when (new.membership_number is null)
  execute function generate_membership_number();

-- ============================================================
-- AUTO-UPDATE updated_at
-- ============================================================
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.profiles enable row level security;
alter table public.membership_payments enable row level security;
alter table public.events enable row level security;
alter table public.event_registrations enable row level security;
alter table public.member_connections enable row level security;
alter table public.member_content enable row level security;
alter table public.notifications enable row level security;

-- PROFILES policies
create policy "Members can view public profiles"
  on public.profiles for select
  using (is_public = true or auth.uid() = id);

create policy "Members can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Members can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- PAYMENTS policies
create policy "Members view own payments"
  on public.membership_payments for select
  using (auth.uid() = member_id);

-- EVENTS policies
create policy "Everyone sees published events"
  on public.events for select
  using (is_published = true);

-- EVENT REGISTRATIONS policies
create policy "Members manage own registrations"
  on public.event_registrations for all
  using (auth.uid() = member_id);

create policy "Members view all registrations for joined events"
  on public.event_registrations for select
  using (true);

-- CONNECTIONS policies
create policy "Members manage own connections"
  on public.member_connections for all
  using (auth.uid() = requester_id or auth.uid() = recipient_id);

-- CONTENT policies
create policy "Members view content by tier"
  on public.member_content for select
  using (
    is_published = true and (
      min_tier = 'friend' or
      exists (
        select 1 from public.profiles p
        where p.id = auth.uid()
        and (
          (min_tier = 'associate' and p.membership_tier in ('associate','full_member','patron','founding_fellow')) or
          (min_tier = 'full_member' and p.membership_tier in ('full_member','patron','founding_fellow')) or
          (min_tier = 'patron' and p.membership_tier in ('patron','founding_fellow')) or
          (min_tier = 'founding_fellow' and p.membership_tier = 'founding_fellow')
        )
      )
    )
  );

-- NOTIFICATIONS policies
create policy "Members view own notifications"
  on public.notifications for all
  using (auth.uid() = member_id);

-- ============================================================
-- SEED: Sample Events
-- ============================================================
insert into public.events (title, description, event_type, location, is_virtual, starts_at, ends_at, is_members_only, min_tier) values
('Biafra Heroes Day Commemoration', 'Annual ceremony honouring the memory and sacrifice of Biafran heroes. Open to all members worldwide.', 'cultural', 'Hamburg, Germany & Virtual', true, '2026-08-15 10:00:00+00', '2026-08-15 14:00:00+00', false, 'friend'),
('OFW Annual Cultural Gala & Awards', 'Our flagship annual gala celebrating Igbo excellence across the diaspora. Black-tie event.', 'gala', 'Nsukka, Enugu State, Nigeria', false, '2026-09-21 18:00:00+00', '2026-09-21 23:00:00+00', true, 'associate'),
('Igbo Language & Arts Festival', 'A celebration of Igbo language, music, visual arts, and storytelling.', 'cultural', 'Virtual & In-Person', true, '2026-10-04 09:00:00+00', '2026-10-04 17:00:00+00', false, 'friend'),
('Diaspora Investor & Strategy Summit', 'Exclusive summit connecting OFW investors, patrons, and founding fellows with strategic initiatives.', 'summit', 'Hamburg, Germany', false, '2026-12-07 09:00:00+00', '2026-12-07 18:00:00+00', true, 'patron');

-- ============================================================
-- SEED: Sample Member Content
-- ============================================================
insert into public.member_content (title, slug, excerpt, content_type, min_tier, is_published) values
('Welcome to the Obinwannem Family', 'welcome-obinwannem', 'A warm welcome letter from the Foundation leadership to all new members.', 'article', 'friend', true),
('Igbo Cultural Almanac 2026', 'igbo-cultural-almanac-2026', 'A comprehensive guide to Igbo festivals, traditions, and cultural observances for 2026.', 'document', 'friend', true),
('OFW Strategic Plan 2026–2030', 'ofw-strategic-plan-2026', 'The full five-year strategic roadmap for Obinwannem Foundation Worldwide.', 'document', 'full_member', true),
('Biafran History: A Documented Account', 'biafran-history-documented', 'An archival deep-dive into the historical records of the Biafran struggle.', 'article', 'associate', true),
('Investor Briefing: OFW Growth Fund Q2 2026', 'investor-briefing-q2-2026', 'Exclusive financial and impact briefing for OFW investors and patrons.', 'document', 'patron', true);

-- ============================================================
-- Done! Next steps:
-- 1. Go to Supabase Dashboard > Authentication > Settings
-- 2. Set Site URL to your deployed domain
-- 3. Enable Email confirmations (or disable for testing)
-- 4. Copy your Project URL and anon key into index.html
-- ============================================================
