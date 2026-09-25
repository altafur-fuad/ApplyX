-- =========================
-- Storage Setup
-- =========================

-- Create a bucket for user documents (resumes, cover letters, portfolios).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'documents',
  'documents',
  false, -- Private bucket
  10485760, -- 10 MB
  array['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain']
) on conflict (id) do nothing;

-- =========================
-- Storage RLS Policies
-- =========================

-- Enable RLS for the objects table if not already enabled
alter table storage.objects enable row level security;

-- Only authenticated users can upload to their own user-specific folder
drop policy if exists documents_insert_own on storage.objects;
create policy documents_insert_own on storage.objects
  for insert
  with check (
    bucket_id = 'documents' 
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can read their own documents
drop policy if exists documents_select_own on storage.objects;
create policy documents_select_own on storage.objects
  for select
  using (
    bucket_id = 'documents' 
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can update their own documents
drop policy if exists documents_update_own on storage.objects;
create policy documents_update_own on storage.objects
  for update
  using (
    bucket_id = 'documents' 
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can delete their own documents
drop policy if exists documents_delete_own on storage.objects;
create policy documents_delete_own on storage.objects
  for delete
  using (
    bucket_id = 'documents' 
    and auth.uid()::text = (storage.foldername(name))[1]
  );
