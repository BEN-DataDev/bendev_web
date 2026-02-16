-- Create project_layers table for user-uploaded/drawn overlay layers

CREATE TABLE IF NOT EXISTS public.project_layers (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
	name text NOT NULL,
	description text,
	layer_type text NOT NULL CHECK (layer_type IN ('geojson', 'wms', 'wfs', 'xyz_tiles', 'drawn')),
	geojson_data jsonb,
	source_url text,
	style jsonb,
	visible boolean DEFAULT true NOT NULL,
	display_order integer DEFAULT 0 NOT NULL,
	editable boolean DEFAULT false NOT NULL,
	created_by uuid REFERENCES public.userprofile(id),
	created_at timestamptz DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
	last_updated timestamptz DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
	CONSTRAINT project_layers_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS idx_project_layers_project ON public.project_layers(project_id);

ALTER TABLE public.project_layers ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS set_last_updated ON public.project_layers;
CREATE TRIGGER set_last_updated
BEFORE INSERT OR UPDATE ON public.project_layers
FOR EACH ROW EXECUTE FUNCTION public.update_last_updated();

-- RLS policies
DROP POLICY IF EXISTS project_layers_select ON public.project_layers;
CREATE POLICY project_layers_select
ON public.project_layers
FOR SELECT
USING (
	EXISTS (
		SELECT 1
		FROM public.projects_users
		WHERE project_id = project_layers.project_id
			AND user_id = auth.uid()
	)
	OR EXISTS (
		SELECT 1
		FROM public.projects
		WHERE id = project_layers.project_id
			AND public = true
	)
);

DROP POLICY IF EXISTS project_layers_insert ON public.project_layers;
CREATE POLICY project_layers_insert
ON public.project_layers
FOR INSERT
WITH CHECK (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = project_layers.project_id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);

DROP POLICY IF EXISTS project_layers_update ON public.project_layers;
CREATE POLICY project_layers_update
ON public.project_layers
FOR UPDATE
USING (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = project_layers.project_id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
)
WITH CHECK (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = project_layers.project_id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);

DROP POLICY IF EXISTS project_layers_delete ON public.project_layers;
CREATE POLICY project_layers_delete
ON public.project_layers
FOR DELETE
USING (
	EXISTS (
		SELECT 1
		FROM public.user_roles
		WHERE user_id = auth.uid()
			AND entity_id = project_layers.project_id
			AND role_type = 'project'
			AND role_name IN ('owner', 'admin', 'editor', 'gis')
	)
);
