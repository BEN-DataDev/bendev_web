-- ADR-001: Replace geojson_data JSONB with PostGIS geometry (SRID 7855 — GDA2020 / MGA zone 55)
--
-- Layer geometries are stored in a projected Australian CRS to enable accurate
-- area/distance calculations and native spatial queries.
--
-- API write path: ST_Transform(ST_GeomFromGeoJSON($geojson)::geometry, 7855)
-- API read path:  ST_AsGeoJSON(ST_Transform(geometry, 4326))::json  →  WGS84 GeoJSON for Leaflet
--
-- The column is nullable: tile-based layer types (wms, wfs, xyz_tiles) have no
-- client-supplied geometry and use source_url instead.

ALTER TABLE public.project_layers
    DROP COLUMN IF EXISTS geojson_data,
    ADD COLUMN geometry geometry(Geometry, 7855);

CREATE INDEX IF NOT EXISTS idx_project_layers_geometry
    ON public.project_layers
    USING GIST (geometry);

COMMENT ON COLUMN public.project_layers.geometry IS
    'Layer geometry stored in GDA2020 / MGA zone 55 (SRID 7855). '
    'Null for tile-based layer types (wms, wfs, xyz_tiles). '
    'Read via ST_AsGeoJSON(ST_Transform(geometry, 4326)) to produce WGS84 GeoJSON for the UI.';
