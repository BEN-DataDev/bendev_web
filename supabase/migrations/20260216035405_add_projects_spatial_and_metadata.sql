CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE public.projects
	ADD COLUMN IF NOT EXISTS geometry geometry(Geometry, 4326);

CREATE INDEX IF NOT EXISTS idx_projects_geometry
	ON public.projects
	USING GIST (geometry);

ALTER TABLE public.projects
	ADD COLUMN IF NOT EXISTS bounds geometry(Polygon, 4326);

ALTER TABLE public.projects
	ADD COLUMN IF NOT EXISTS description text,
	ADD COLUMN IF NOT EXISTS status text DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'archived')),
	ADD COLUMN IF NOT EXISTS start_date date,
	ADD COLUMN IF NOT EXISTS end_date date,
	ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.community(id);
