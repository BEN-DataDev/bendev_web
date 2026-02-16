-- Create storage buckets and apply baseline RLS policies for projects

-- Buckets
INSERT INTO storage.buckets (id, name, public)
VALUES
	('project-attachments', 'project-attachments', false),
	('project-images', 'project-images', true)
ON CONFLICT (id)
DO UPDATE SET
	name = EXCLUDED.name,
	public = EXCLUDED.public;

-- Projects RLS
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS projects_select ON public.projects;
CREATE POLICY projects_select
ON public.projects
FOR SELECT
USING (
	public = true
	OR EXISTS (
		SELECT 1
		FROM public.projects_users
		WHERE project_id = projects.id
			AND user_id = auth.uid()
	)
);

DROP POLICY IF EXISTS projects_update ON public.projects;
CREATE POLICY projects_update
ON public.projects
FOR UPDATE
USING (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = projects.id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);
