-- Migration: community_crud_functions
-- RPC helpers for creating, reading, and updating communities.
-- Models the pattern established by project_geometry_helpers.

-- ─────────────────────────────────────────────────────────────────────────────
-- get_community(uuid)
--   Returns a single community row with its extent as WGS84 GeoJSON and a
--   bounding-box float array [lon_min, lat_min, lon_max, lat_max].
--   SECURITY INVOKER: community RLS policies apply.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_community(p_id uuid)
RETURNS TABLE (
    id            uuid,
    name          text,
    communityinfo jsonb,
    contactinfo   jsonb,
    public        boolean,
    created_at    timestamptz,
    last_updated  timestamptz,
    boundary      json,
    bounds        float[]
)
LANGUAGE sql SECURITY INVOKER STABLE AS $$
    SELECT
        c.id,
        c.name,
        c.communityinfo,
        c.contactinfo,
        c.public,
        c.created_at,
        c.last_updated,
        CASE WHEN c.extent IS NOT NULL
            THEN ST_AsGeoJSON(ST_Transform(c.extent::geometry, 4326))::json
            ELSE NULL
        END AS boundary,
        CASE WHEN c.extent IS NOT NULL THEN
            ARRAY[
                ST_XMin(ST_Envelope(ST_Transform(c.extent::geometry, 4326))),
                ST_YMin(ST_Envelope(ST_Transform(c.extent::geometry, 4326))),
                ST_XMax(ST_Envelope(ST_Transform(c.extent::geometry, 4326))),
                ST_YMax(ST_Envelope(ST_Transform(c.extent::geometry, 4326)))
            ]
        ELSE NULL END AS bounds
    FROM public.community c
    WHERE c.id = p_id;
$$;

GRANT EXECUTE ON FUNCTION get_community(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_community(uuid) TO service_role;


-- ─────────────────────────────────────────────────────────────────────────────
-- create_community(...)
--   Inserts a new community with a required WGS84 GeoJSON extent, then grants
--   the calling user owner access via user_roles and communities_users.
--   SECURITY DEFINER: community INSERT requires elevated privilege; auth.uid()
--   check is performed explicitly.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION create_community(
    p_name           text,
    p_extent_geojson text,
    p_public         boolean DEFAULT true
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_community_id uuid;
    v_user_id      uuid := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF p_extent_geojson IS NULL OR p_extent_geojson = '' THEN
        RAISE EXCEPTION 'Community extent is required';
    END IF;

    INSERT INTO community (name, extent, public)
    VALUES (
        p_name,
        ST_SetSRID(ST_GeomFromGeoJSON(p_extent_geojson), 4326)::geometry,
        p_public
    )
    RETURNING id INTO v_community_id;

    -- Add creator to communities_users membership table
    INSERT INTO communities_users (user_id, community_id)
    VALUES (v_user_id, v_community_id)
    ON CONFLICT DO NOTHING;

    -- Assign owner role
    INSERT INTO user_roles (user_id, role_type, role_name, entity_id)
    VALUES (v_user_id, 'community', 'owner', v_community_id)
    ON CONFLICT DO NOTHING;

    RETURN v_community_id;
END;
$$;

GRANT EXECUTE ON FUNCTION create_community(text, text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION create_community(text, text, boolean) TO service_role;


-- ─────────────────────────────────────────────────────────────────────────────
-- update_community(...)
--   Updates community metadata and optionally replaces the extent geometry.
--   If p_extent_geojson is NULL or empty, the existing geometry is preserved.
--   SECURITY INVOKER: community UPDATE RLS policy (user_roles check) applies.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_community(
    p_id             uuid,
    p_name           text,
    p_extent_geojson text    DEFAULT NULL,
    p_public         boolean DEFAULT true
)
RETURNS boolean
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    UPDATE community
    SET
        name   = p_name,
        public = p_public,
        extent = CASE
                     WHEN p_extent_geojson IS NOT NULL AND p_extent_geojson <> ''
                     THEN ST_SetSRID(ST_GeomFromGeoJSON(p_extent_geojson), 4326)::geometry
                     ELSE extent   -- preserve existing if none supplied
                 END
    WHERE id = p_id;

    RETURN FOUND;
END;
$$;

GRANT EXECUTE ON FUNCTION update_community(uuid, text, text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION update_community(uuid, text, text, boolean) TO service_role;
