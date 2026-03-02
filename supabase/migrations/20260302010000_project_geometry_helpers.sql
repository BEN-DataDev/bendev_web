-- Migration: project_geometry_helpers
-- RPC functions for reading and writing projects with PostGIS geometry.
-- Follows the pattern established by get_communities_with_transformed_extent.

-- ─────────────────────────────────────────────────────────────────────────────
-- get_project(uuid)
--   Returns a single project row with its boundary as WGS84 GeoJSON and a
--   bounding-box float array [lon_min, lat_min, lon_max, lat_max].
--   SECURITY INVOKER: existing projects_select RLS policy applies.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_project(p_id uuid)
RETURNS TABLE (
    id            uuid,
    projectname   text,
    description   text,
    status        text,
    start_date    date,
    end_date      date,
    community_id  uuid,
    community_name text,
    public        boolean,
    created_at    timestamptz,
    last_updated  timestamptz,
    boundary      json,
    bounds        float[]
)
LANGUAGE sql SECURITY INVOKER STABLE AS $$
    SELECT
        p.id,
        p.projectname,
        p.description,
        p.status,
        p.start_date,
        p.end_date,
        p.community_id,
        c.name AS community_name,
        p.public,
        p.created_at,
        p.last_updated,
        CASE WHEN p.geometry IS NOT NULL
            THEN ST_AsGeoJSON(p.geometry)::json
            ELSE NULL
        END AS boundary,
        CASE WHEN p.geometry IS NOT NULL THEN
            ARRAY[
                ST_XMin(ST_Envelope(p.geometry)),
                ST_YMin(ST_Envelope(p.geometry)),
                ST_XMax(ST_Envelope(p.geometry)),
                ST_YMax(ST_Envelope(p.geometry))
            ]
        ELSE NULL END AS bounds
    FROM   projects p
    LEFT JOIN community c ON c.id = p.community_id
    WHERE  p.id = p_id;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- create_project(...)
--   Inserts a new project with an optional GeoJSON boundary, then grants the
--   calling user owner access via user_roles and projects_users.
--   SECURITY DEFINER: no projects INSERT RLS policy exists; auth.uid() check
--   is performed explicitly.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION create_project(
    p_name              text,
    p_description       text    DEFAULT NULL,
    p_status            text    DEFAULT 'draft',
    p_start_date        date    DEFAULT NULL,
    p_end_date          date    DEFAULT NULL,
    p_community_id      uuid    DEFAULT NULL,
    p_public            boolean DEFAULT false,
    p_boundary_geojson  text    DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_project_id uuid;
    v_user_id    uuid := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    INSERT INTO projects (
        projectname, description, status,
        start_date, end_date, community_id, public, geometry
    )
    VALUES (
        p_name,
        p_description,
        p_status,
        p_start_date,
        p_end_date,
        p_community_id,
        p_public,
        CASE
            WHEN p_boundary_geojson IS NOT NULL AND p_boundary_geojson <> ''
            THEN ST_GeomFromGeoJSON(p_boundary_geojson)::geometry
            ELSE NULL
        END
    )
    RETURNING id INTO v_project_id;

    -- Grant select access via the projects_select RLS table
    INSERT INTO projects_users (user_id, project_id)
    VALUES (v_user_id, v_project_id)
    ON CONFLICT DO NOTHING;

    -- Assign owner role
    INSERT INTO user_roles (user_id, role_type, role_name, entity_id)
    VALUES (v_user_id, 'project', 'owner', v_project_id)
    ON CONFLICT DO NOTHING;

    RETURN v_project_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- update_project(...)
--   Updates project metadata and optionally replaces the boundary geometry.
--   If p_boundary_geojson is NULL or empty, the existing geometry is preserved.
--   SECURITY INVOKER: projects_update RLS policy (user_roles check) applies.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_project(
    p_id                uuid,
    p_name              text,
    p_description       text    DEFAULT NULL,
    p_status            text    DEFAULT 'draft',
    p_start_date        date    DEFAULT NULL,
    p_end_date          date    DEFAULT NULL,
    p_community_id      uuid    DEFAULT NULL,
    p_public            boolean DEFAULT false,
    p_boundary_geojson  text    DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    UPDATE projects
    SET
        projectname  = p_name,
        description  = p_description,
        status       = p_status,
        start_date   = p_start_date,
        end_date     = p_end_date,
        community_id = p_community_id,
        public       = p_public,
        geometry     = CASE
                           WHEN p_boundary_geojson IS NOT NULL AND p_boundary_geojson <> ''
                           THEN ST_GeomFromGeoJSON(p_boundary_geojson)::geometry
                           ELSE geometry   -- preserve existing if none supplied
                       END
    WHERE id = p_id;

    RETURN FOUND;
END;
$$;
