-- Storage object RLS policies for project-attachments and project-images buckets.
-- Path convention: {projectId}/{uuid}/{filename}
-- The first path segment is always the project UUID.

-- ── project-attachments (private) ────────────────────────────────────────────

DROP POLICY IF EXISTS "project-attachments: read for project members" ON storage.objects;
CREATE POLICY "project-attachments: read for project members"
ON storage.objects FOR SELECT
TO authenticated
USING (
	bucket_id = 'project-attachments'
	AND (
		EXISTS (
			SELECT 1 FROM public.projects_users pu
			WHERE pu.project_id = split_part(name, '/', 1)::uuid
				AND pu.user_id = auth.uid()
		)
		OR EXISTS (
			SELECT 1 FROM public.projects p
			WHERE p.id = split_part(name, '/', 1)::uuid
				AND p.public = true
		)
	)
);

DROP POLICY IF EXISTS "project-attachments: upload for project editors" ON storage.objects;
CREATE POLICY "project-attachments: upload for project editors"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
	bucket_id = 'project-attachments'
	AND EXISTS (
		SELECT 1 FROM public.user_roles ur
		WHERE ur.user_id = auth.uid()
			AND ur.entity_id = split_part(name, '/', 1)::uuid
			AND ur.role_type = 'project'
			AND ur.role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);

DROP POLICY IF EXISTS "project-attachments: delete for project editors" ON storage.objects;
CREATE POLICY "project-attachments: delete for project editors"
ON storage.objects FOR DELETE
TO authenticated
USING (
	bucket_id = 'project-attachments'
	AND EXISTS (
		SELECT 1 FROM public.user_roles ur
		WHERE ur.user_id = auth.uid()
			AND ur.entity_id = split_part(name, '/', 1)::uuid
			AND ur.role_type = 'project'
			AND ur.role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);

-- ── project-images (public) ───────────────────────────────────────────────────

DROP POLICY IF EXISTS "project-images: read for all" ON storage.objects;
CREATE POLICY "project-images: read for all"
ON storage.objects FOR SELECT
USING (bucket_id = 'project-images');

DROP POLICY IF EXISTS "project-images: upload for project editors" ON storage.objects;
CREATE POLICY "project-images: upload for project editors"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
	bucket_id = 'project-images'
	AND EXISTS (
		SELECT 1 FROM public.user_roles ur
		WHERE ur.user_id = auth.uid()
			AND ur.entity_id = split_part(name, '/', 1)::uuid
			AND ur.role_type = 'project'
			AND ur.role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);

DROP POLICY IF EXISTS "project-images: delete for project editors" ON storage.objects;
CREATE POLICY "project-images: delete for project editors"
ON storage.objects FOR DELETE
TO authenticated
USING (
	bucket_id = 'project-images'
	AND EXISTS (
		SELECT 1 FROM public.user_roles ur
		WHERE ur.user_id = auth.uid()
			AND ur.entity_id = split_part(name, '/', 1)::uuid
			AND ur.role_type = 'project'
			AND ur.role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);
