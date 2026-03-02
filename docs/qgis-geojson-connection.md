# Loading bendev-web GeoJSON Exports into QGIS

This guide explains how to download project data from bendev-web and load it into QGIS for further analysis.

---

## Exporting GeoJSON from bendev-web

### Full project export (boundary + all layers)

On any project view page, click **↓ Export GeoJSON** in the left panel. The browser downloads a `.geojson` file containing:

- The project boundary as a `Feature` with `_type: "project_boundary"` in `properties`
- Every layer's features, each annotated with `_layer_name` and `_layer_id` in `properties`

### Single layer export

In the **Layers** tab on the project view, each layer has a **↓** button that downloads only that layer's GeoJSON FeatureCollection.

### Direct API access

Both endpoints are available as authenticated GET requests:

| URL | Returns |
| --- | ------- |
| `/api/projects/{projectId}/export` | Full project FeatureCollection |
| `/api/projects/{projectId}/export?layer={layerId}` | Single layer FeatureCollection |

---

## Loading into QGIS

### Method 1 — Drag and drop (QGIS 3.x)

1. Export the `.geojson` file from bendev-web
2. Drag the file from your file manager into the QGIS map canvas or the **Layers** panel

### Method 2 — Add Vector Layer dialog

1. In QGIS, go to **Layer → Add Layer → Add Vector Layer…** (or press `Ctrl+Shift+V`)
2. Set **Source Type** to **File**
3. Click **…** and browse to the downloaded `.geojson` file
4. Click **Add**, then **Close**

### Method 3 — Browser panel

1. Open the **Browser** panel (View → Panels → Browser)
2. Navigate to the folder containing the `.geojson` file
3. Double-click the file to add it as a layer

---

## Coordinate Reference System

All GeoJSON exported from bendev-web uses **WGS84 (EPSG:4326)** — longitude/latitude decimal degrees.

QGIS will auto-detect this from the GeoJSON specification. If prompted, confirm **EPSG:4326**.

To reproject to GDA2020 / MGA zone 55 (EPSG:7855) — which matches the internal storage CRS — right-click the layer in the Layers panel → **Export → Save Features As…**, set CRS to **EPSG:7855**.

---

## Filtering by Layer

The full project export annotates each feature with `_layer_name`. To split features by layer in QGIS:

1. Load the full export
2. Open the **Attribute Table** (right-click layer → Open Attribute Table)
3. Use **Select by Expression**: `"_layer_name" = 'My Layer Name'`
4. Export selected features via **Save Features As…**

Alternatively, use the per-layer download button in bendev-web to get each layer as a separate file.

---

## Direct PostGIS Connection (future)

Direct read-only PostGIS access for QGIS is planned for a future release. This will allow QGIS to connect to the live database via a read-only role and load spatial data without exporting files.
