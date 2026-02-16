-- Create project_attachments table for files attached to projects

CREATE TABLE IF NOT EXISTS public.project_attachments (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
	file_name text NOT NULL,
	file_path text NOT NULL,
	file_type text NOT NULL,
	file_size bigint,
	category text DEFAULT 'document' CHECK (category IN ('document', 'image', 'report', 'data', 'other')),
	description text,
	uploaded_by uuid REFERENCES public.userprofile(id),
	created_at timestamptz DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
	last_updated timestamptz DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
	CONSTRAINT project_attachments_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS idx_project_attachments_project ON public.project_attachments(project_id);

ALTER TABLE public.project_attachments ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS set_last_updated ON public.project_attachments;
CREATE TRIGGER set_last_updated
BEFORE INSERT OR UPDATE ON public.project_attachments
FOR EACH ROW EXECUTE FUNCTION public.update_last_updated();

-- RLS policies
DROP POLICY IF EXISTS project_attachments_select ON public.project_attachments;
CREATE POLICY project_attachments_select
ON public.project_attachments
FOR SELECT
USING (
	EXISTS (
		SELECT 1
		FROM public.projects_users
		WHERE project_id = project_attachments.project_id
			AND user_id = auth.uid()
	)
	OR EXISTS (
		SELECT 1
		FROM public.projects
		WHERE id = project_attachments.project_id
			AND public = true
	)
);

DROP POLICY IF EXISTS project_attachments_insert ON public.project_attachments;
CREATE POLICY project_attachments_insert
ON public.project_attachments
FOR INSERT
WITH CHECK (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = project_attachments.project_id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);

DROP POLICY IF EXISTS project_attachments_update ON public.project_attachments;
CREATE POLICY project_attachments_update
ON public.project_attachments
FOR UPDATE
USING (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = project_attachments.project_id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
)
WITH CHECK (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = project_attachments.project_id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);

DROP POLICY IF EXISTS project_attachments_delete ON public.project_attachments;
CREATE POLICY project_attachments_delete
ON public.project_attachments
FOR DELETE
USING (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = project_attachments.project_id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);
