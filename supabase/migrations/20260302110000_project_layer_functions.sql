-- Migration: project_layer_functions
-- RPC functions for reading and writing project layers with PostGIS geometry.
-- Follows the SRID 7855 (GDA2020 / MGA zone 55) convention from ADR-001.
--
-- API write path: ST_Transform(ST_Collect(feature_geometries), 7855)
-- API read path:  ST_AsGeoJSON(ST_Transform(geometry, 4326))::json → WGS84 GeoJSON for Leaflet

-- ─────────────────────────────────────────────────────────────────────────────
-- get_project_layers(p_project_id uuid)
--   Returns all layers for a project with geometry as WGS84 GeoJSON FeatureCollection.
--   SECURITY INVOKER: existing project_layers RLS policies apply.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_project_layers(p_project_id uuid)
RETURNS TABLE (
    id             uuid,
    name           text,
    layer_type     text,
    visible        boolean,
    display_order  integer,
    style          jsonb,
    source_url     text,
    geojson        json,
    created_at     timestamptz
)
LANGUAGE sql SECURITY INVOKER STABLE AS $$
    SELECT
        pl.id,
        pl.name,
        pl.layer_type,
        pl.visible,
        pl.display_order,
        pl.style,
        pl.source_url,
        CASE
            WHEN pl.geometry IS NOT NULL THEN
                json_build_object(
                    'type', 'FeatureCollection',
                    'features', json_build_array(
                        json_build_object(
                            'type', 'Feature',
                            'geometry', ST_AsGeoJSON(ST_Transform(pl.geometry, 4326))::json,
                            'properties', json_build_object()
                        )
                    )
                )
            ELSE NULL
        END AS geojson,
        pl.created_at
    FROM project_layers pl
    WHERE pl.project_id = p_project_id
    ORDER BY pl.display_order, pl.created_at;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- create_project_layer(...)
--   Inserts a new layer, collecting all feature geometries from a GeoJSON
--   FeatureCollection string into a single PostGIS geometry (SRID 7855).
--   SECURITY DEFINER: sets created_by to auth.uid(); bypasses INSERT RLS.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION create_project_layer(
    p_project_id    uuid,
    p_name          text,
    p_layer_type    text,
    p_geojson_text  text    DEFAULT NULL,
    p_style         jsonb   DEFAULT NULL,
    p_source_url    text    DEFAULT NULL,
    p_description   text    DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id            uuid;
    v_geometry      geometry;
    v_display_order integer;
    v_user_id       uuid := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Compute next display_order
    SELECT COALESCE(MAX(display_order), -1) + 1
    INTO v_display_order
    FROM project_layers
    WHERE project_id = p_project_id;

    -- Build geometry from GeoJSON FeatureCollection (collect all feature geometries)
    IF p_geojson_text IS NOT NULL AND p_geojson_text <> ''
       AND p_layer_type NOT IN ('wms', 'wfs', 'xyz_tiles') THEN
        SELECT ST_Transform(
            ST_Collect(
                ARRAY(
                    SELECT ST_GeomFromGeoJSON(f->>'geometry')::geometry
                    FROM jsonb_array_elements((p_geojson_text::jsonb)->'features') f
                    WHERE (f->>'geometry') IS NOT NULL
                )
            )::geometry,
            7855
        ) INTO v_geometry;
    END IF;

    INSERT INTO project_layers (
        project_id, name, layer_type, geometry, style,
        source_url, description, display_order, created_by
    )
    VALUES (
        p_project_id, p_name, p_layer_type, v_geometry, p_style,
        p_source_url, p_description, v_display_order, v_user_id
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- update_project_layer(...)
--   Updates layer metadata and optionally replaces geometry.
--   NULL values for p_name / p_visible / p_display_order / p_style preserve
--   the existing column values.
--   SECURITY INVOKER: project_layers UPDATE RLS applies.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_project_layer(
    p_layer_id      uuid,
    p_name          text    DEFAULT NULL,
    p_visible       boolean DEFAULT NULL,
    p_display_order integer DEFAULT NULL,
    p_style         jsonb   DEFAULT NULL,
    p_geojson_text  text    DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_geometry geometry;
BEGIN
    -- Re-build geometry only when a new FeatureCollection is supplied
    IF p_geojson_text IS NOT NULL AND p_geojson_text <> '' THEN
        SELECT ST_Transform(
            ST_Collect(
                ARRAY(
                    SELECT ST_GeomFromGeoJSON(f->>'geometry')::geometry
                    FROM jsonb_array_elements((p_geojson_text::jsonb)->'features') f
                    WHERE (f->>'geometry') IS NOT NULL
                )
            )::geometry,
            7855
        ) INTO v_geometry;
    END IF;

    UPDATE project_layers SET
        name          = COALESCE(p_name, name),
        visible       = COALESCE(p_visible, visible),
        display_order = COALESCE(p_display_order, display_order),
        style         = COALESCE(p_style, style),
        geometry      = CASE
                            WHEN p_geojson_text IS NOT NULL AND p_geojson_text <> ''
                            THEN v_geometry
                            ELSE geometry
                        END,
        last_updated  = NOW()
    WHERE id = p_layer_id;
END;
$$;
