-- Memory & Value: tables and storage for the one-site app.
-- Paste all of this into Supabase: SQL Editor -> New query -> Run.

-- One row per memory. The id is the 12-digit code printed on the label (YYMMDDHHMMSS).
create table if not exists public.memories (
  owner       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id          text not null check (id ~ '^[0-9]{12}$'),
  recorded_at timestamptz not null,
  place       text,
  souvenir    text,
  moment      text,
  envelope    jsonb,          -- the waveform outline, for drawing it again
  photo_path  text,
  video_path  text,
  video_type  text,
  label_path  text,
  created_at  timestamptz not null default now(),
  primary key (owner, id)
);

-- Only the person who made a memory can see or change it.
alter table public.memories enable row level security;
create policy "read own memories"   on public.memories for select to authenticated using (owner = auth.uid());
create policy "add own memories"    on public.memories for insert to authenticated with check (owner = auth.uid());
create policy "change own memories" on public.memories for update to authenticated using (owner = auth.uid());
create policy "remove own memories" on public.memories for delete to authenticated using (owner = auth.uid());

-- A private bucket for photos, videos and labels, 50 MB per file.
-- Files live under <user id>/<memory id>/..., and each person reaches only their own folder.
insert into storage.buckets (id, name, public, file_size_limit)
values ('memories', 'memories', false, 52428800)
on conflict (id) do nothing;

create policy "read own files"   on storage.objects for select to authenticated
  using (bucket_id = 'memories' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "add own files"    on storage.objects for insert to authenticated
  with check (bucket_id = 'memories' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "change own files" on storage.objects for update to authenticated
  using (bucket_id = 'memories' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "remove own files" on storage.objects for delete to authenticated
  using (bucket_id = 'memories' and (storage.foldername(name))[1] = auth.uid()::text);
