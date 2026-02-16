# Implementation Roadmap: Spatial Environment Management Platform

## Executive Summary

This document analyses the existing bendev-web codebase and recommends the changes needed to deliver a platform where authorised users can create, edit, and view local environment management projects with spatial awareness, overlay layers, document/image attachments, QGIS connectivity, and map production.

The codebase already has solid foundations: SvelteKit + Svelte 5, Supabase auth with JWT-embedded RBAC, Leaflet with Geoman drawing tools, PostGIS on communities, and a scaffolded route structure. However, most CRUD operations are stubbed, projects have no spatial column, there is no file attachment system beyond avatars, and there is no OGC service layer for QGIS.

---

## 1. Current State Assessment

### What Already Exists

| Area | Status | Details |
| ---- | ------ | ------- |
| **Auth** | Working | Email/password, GitHub OAuth, Discord OAuth, JWT-based session |
| **RBAC** | Designed, partially implemented | Roles in JWT (`owner`, `admin`, `editor`, `gis`, `viewer`, `moderator`, `member`, `system_admin`, `system_moderator`), role types (`project`, `community`, `global`), but no route guards enforce them yet |
| **Communities** | Partially working | List page with map, PostGIS `extent` geometry, RPC for transformed extents. Create/edit/view pages are stubbed |
| **Projects** | Scaffolded only | Route structure exists (`/projects`, `/projects/new`, `/projects/[projectId]`, `/projects/[projectId]/edit`). All server load functions return `{}` |
| **Maps** | Good foundation | `LeafletMap.svelte` (full-featured with context API), `LeafletGeoJSONPolygonLayer.svelte`, `GeomanControls.svelte` (drawing/editing), `LeafletBasicReactiveMap.svelte`, `MaplibreGLBasicMap.svelte` |
| **Spatial schema** | Partial | Communities have PostGIS geometry. `projects` schema and `projects_tables` auto-tracking system documented but status unclear. No geometry column on `projects` table |
| **File uploads** | Avatar only | Single `UploadAvatar.svelte` component uploading to Supabase Storage `avatars` bucket |
| **QGIS access** | Documented concept | `rbac.md` describes PostgreSQL roles (`qgis_user`) and an `initialize_connection` function, but nothing is implemented |
| **Map production** | Not started | No print/export capability |

### What Needs to Be Built

1. **Project CRUD with spatial data** — full create/edit/view with geometry column
2. **Overlay spatial layers** — user-uploadable GeoJSON/Shapefile layers per project
3. **Document & image attachments** — file upload/management per project
4. **QGIS connectivity** — OGC-compliant service or direct PostGIS access
5. **Map production** — print/export from the web app
6. **RBAC enforcement** — actually check roles on routes and operations

---

## 2. Database Changes

### 2.1 Add Geometry to Projects

The `projects` table currently has no spatial column. Add one:

```sql
-- Add PostGIS geometry column to projects
ALTER TABLE public.projects
  ADD COLUMN geometry geometry(Geometry, 4326);

-- Add spatial index
CREATE INDEX idx_projects_geometry ON public.projects USING GIST (geometry);

-- Add a bounding box column for quick extent queries
ALTER TABLE public.projects
  ADD COLUMN bounds geometry(Polygon, 4326);
```

Also add fields for richer project metadata:

```sql
ALTER TABLE public.projects
  ADD COLUMN description text,
  ADD COLUMN status text DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'archived')),
  ADD COLUMN start_date date,
  ADD COLUMN end_date date,
  ADD COLUMN community_id uuid REFERENCES public.community(id);
```

### 2.2 Project Spatial Layers Table

For user-uploaded overlay layers:

```sql
CREATE TABLE public.project_layers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  layer_type text NOT NULL CHECK (layer_type IN ('geojson', 'wms', 'wfs', 'xyz_tiles', 'drawn')),
  geojson_data jsonb,                    -- for uploaded/drawn GeoJSON
  source_url text,                       -- for WMS/WFS/XYZ external sources
  style jsonb,                           -- layer styling (fill, stroke, opacity)
  visible boolean DEFAULT true,
  display_order integer DEFAULT 0,
  editable boolean DEFAULT false,
  created_by uuid REFERENCES public.userprofile(id),
  created_at timestamptz DEFAULT now(),
  last_updated timestamptz DEFAULT now()
);

CREATE INDEX idx_project_layers_project ON public.project_layers(project_id);
```

### 2.3 Project Attachments Table

```sql
CREATE TABLE public.project_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_path text NOT NULL,               -- Supabase Storage path
  file_type text NOT NULL,               -- MIME type
  file_size bigint,
  category text DEFAULT 'document' CHECK (category IN ('document', 'image', 'report', 'data', 'other')),
  description text,
  uploaded_by uuid REFERENCES public.userprofile(id),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_project_attachments_project ON public.project_attachments(project_id);
```

### 2.4 Create Supabase Storage Buckets

```sql
-- Via Supabase dashboard or migration
INSERT INTO storage.buckets (id, name, public) VALUES
  ('project-attachments', 'project-attachments', false),
  ('project-images', 'project-images', true);
```

Storage policies should restrict uploads to project members with `editor` role or above.

### 2.5 RLS Policies

```sql
-- Projects: anyone can read public projects, members can read private
CREATE POLICY projects_select ON public.projects FOR SELECT USING (
  public = true
  OR EXISTS (
    SELECT 1 FROM public.projects_users
    WHERE project_id = projects.id AND user_id = auth.uid()
  )
);

-- Projects: editors and above can update
CREATE POLICY projects_update ON public.projects FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND entity_id = projects.id
      AND role_type = 'project'
      AND role_name IN ('owner', 'admin', 'editor', 'gis')
  )
);

-- Project layers: project members can read
CREATE POLICY project_layers_select ON public.project_layers FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.projects_users
    WHERE project_id = project_layers.project_id AND user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.projects
    WHERE id = project_layers.project_id AND public = true
  )
);

-- Project layers: editors/gis role can insert/update
CREATE POLICY project_layers_insert ON public.project_layers FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND entity_id = project_layers.project_id
      AND role_type = 'project'
      AND role_name IN ('owner', 'admin', 'editor', 'gis')
  )
);

-- Similar policies for project_attachments...
```

### 2.6 RPC Functions for Spatial Queries

```sql
-- Get project with transformed geometry (matching community pattern)
CREATE OR REPLACE FUNCTION get_project_with_spatial_data(p_project_id uuid)
RETURNS json AS $$
  SELECT json_build_object(
    'id', p.id,
    'projectname', p.projectname,
    'projectinfo', p.projectinfo,
    'status', p.status,
    'geometry', ST_AsGeoJSON(p.geometry)::json,
    'bounds', ST_AsGeoJSON(p.bounds)::json,
    'center', json_build_array(
      ST_Y(ST_Centroid(p.geometry)),
      ST_X(ST_Centroid(p.geometry))
    ),
    'layers', (
      SELECT json_agg(json_build_object(
        'id', l.id,
        'name', l.name,
        'layer_type', l.layer_type,
        'geojson_data', l.geojson_data,
        'source_url', l.source_url,
        'style', l.style,
        'visible', l.visible,
        'display_order', l.display_order,
        'editable', l.editable
      ) ORDER BY l.display_order)
      FROM public.project_layers l WHERE l.project_id = p.id
    )
  )
  FROM public.projects p
  WHERE p.id = p_project_id;
$$ LANGUAGE sql STABLE;
```

---

## 3. Backend / API Changes

### 3.1 Implement Project CRUD Server Functions

All project route server files currently return `{}`. Implement them:

| Route | File | Action |
| ----- | ---- | ------ |
| `/projects` | `+page.server.ts` | List projects (with optional spatial filter/bbox) |
| `/projects/new` | `+page.server.ts` | Form action: insert project with geometry |
| `/projects/[projectId]` | `+page.server.ts` | Load project with spatial data and layers |
| `/projects/[projectId]/edit` | `+page.server.ts` | Form action: update project and geometry |
| `/projects/[projectId]/users` | `+page.server.ts` | List/manage project members |
| `/projects/[projectId]/users/add` | `+page.server.ts` | Add user to project with role |

Example for project creation:

```typescript
// src/routes/projects/new/+page.server.ts
export const actions = {
  default: async ({ request, locals }) => {
    const { supabase, user } = locals;
    const formData = await request.formData();

    const projectname = formData.get('projectname');
    const description = formData.get('description');
    const geometry = formData.get('geometry'); // GeoJSON string from map
    const community_id = formData.get('community_id');

    const { data, error } = await supabase
      .from('projects')
      .insert({
        projectname,
        description,
        geometry: geometry ? JSON.parse(geometry) : null,
        community_id,
        projectinfo: {}
      })
      .select()
      .single();

    if (error) return fail(400, { error: error.message });

    // Add creator as owner
    await supabase.from('user_roles').insert({
      user_id: user.id,
      role_name: 'owner',
      role_type: 'project',
      entity_id: data.id
    });

    throw redirect(303, `/projects/${data.id}`);
  }
};
```

### 3.2 File Upload API Endpoints

Create API routes for file management:

```text
src/routes/api/projects/[projectId]/attachments/
  +server.ts          -- GET (list), POST (upload)
src/routes/api/projects/[projectId]/attachments/[attachmentId]/
  +server.ts          -- GET (download), DELETE
src/routes/api/projects/[projectId]/layers/
  +server.ts          -- GET (list), POST (upload GeoJSON/Shapefile)
src/routes/api/projects/[projectId]/layers/[layerId]/
  +server.ts          -- GET, PUT (update style/visibility), DELETE
```

For file uploads, use Supabase Storage:

```typescript
// POST handler for attachments
const file = formData.get('file') as File;
const storagePath = `projects/${projectId}/${crypto.randomUUID()}-${file.name}`;

const { error: uploadError } = await supabase.storage
  .from('project-attachments')
  .upload(storagePath, file);

const { data } = await supabase
  .from('project_attachments')
  .insert({
    project_id: projectId,
    file_name: file.name,
    file_path: storagePath,
    file_type: file.type,
    file_size: file.size,
    uploaded_by: user.id
  })
  .select()
  .single();
```

### 3.3 Shapefile/GeoPackage Upload Processing

For spatial layer uploads (Shapefiles, GeoPackage, KML), options:

### Option A: Client-side conversion (recommended for v1)

- Use libraries like `shpjs` (Shapefile to GeoJSON) or `togeojson` (KML to GeoJSON) in the browser
- Store the converted GeoJSON in `project_layers.geojson_data`
- Simpler, no server processing needed

### Option B: Server-side with ogr2ogr (for production)

- Install GDAL on the server (or use a Supabase Edge Function)
- Convert uploaded files to GeoJSON server-side
- Better for large files and format validation

### 3.4 Enforce RBAC on Routes

The admin layout server (`src/routes/admin/+layout.server.ts`) has a TODO. Implement guards:

```typescript
// src/routes/admin/+layout.server.ts
export const load: LayoutServerLoad = async ({ locals }) => {
  const { session, roles } = await locals.safeGetSession();

  if (!session) throw redirect(303, '/auth/signin');

  const isAdmin = roles.some(r =>
    r.role_name === 'system_admin' && r.role_type === 'global'
  );

  if (!isAdmin) throw error(403, 'Forbidden');
  return {};
};
```

Apply similar guards to project edit/delete routes checking for project-level roles.

---

## 4. Frontend Changes

### 4.1 Project Map View Component

Create a new component that composes the existing map building blocks:

```text
src/components/maps/ProjectMapView.svelte
```

This should use the existing `LeafletMap.svelte` with:

- Base layer selection (already supported via `baseLayers` prop)
- `LeafletGeoJSONPolygonLayer` for the project boundary
- Dynamic `LeafletGeoJSONPolygonLayer` instances for each overlay layer
- `GeomanControls` for geometry editing (when user has edit permission)
- A layer panel showing overlay layers with visibility toggles
- Click-to-identify on features

### 4.2 Project Create/Edit Pages

The existing route structure at `/projects/new` and `/projects/[projectId]/edit` needs actual forms:

**Project form should include:**

- Project name, description, status, dates
- Community association (dropdown)
- **Map for drawing the project boundary** — use `LeafletMap` + `GeomanControls`
- The drawn geometry gets serialised to GeoJSON and submitted with the form

**Project view page should include:**

- Project details panel
- Full-width map showing:
  - Project boundary
  - All overlay layers with legend
  - Layer panel with visibility toggles
- Tabs/panels for: Layers, Documents, Images, Users, Comments

### 4.3 Layer Management UI

```text
src/components/projects/LayerPanel.svelte       -- layer list with toggle/reorder
src/components/projects/LayerUpload.svelte       -- upload GeoJSON/Shapefile
src/components/projects/LayerStyleEditor.svelte  -- edit fill/stroke/opacity
```

**Layer upload flow:**

1. User selects file (GeoJSON, Shapefile .zip, KML)
2. Client converts to GeoJSON (using `shpjs` or `togeojson`)
3. Preview on map
4. User names the layer and confirms
5. POST to API, stored in `project_layers`

### 4.4 Document/Image Attachment UI

```text
src/components/projects/AttachmentList.svelte    -- list/grid of attachments
src/components/projects/AttachmentUpload.svelte  -- drag-and-drop file upload
src/components/projects/ImageGallery.svelte      -- image preview gallery
```

Build on the existing `UploadAvatar.svelte` pattern for the upload component. Use Supabase Storage signed URLs for private file downloads.

### 4.5 Map Production / Print

Two approaches, both addable to the project view:

#### Option A: Leaflet print plugin**

- Add `leaflet-easyprint` or `leaflet.browser.print` package
- Adds a print button to the map that captures the current view
- Quick to implement, limited customisation

#### Option B: Server-side map rendering (for formal reports)**

- Use a Supabase Edge Function or API route
- Render map with `maplibre-gl-native` or generate a PDF with map tiles + vector overlays
- More complex but produces publication-quality output

**Recommended: Start with Option A**, add Option B later if needed.

```bash
npm install leaflet-easyprint
```

Add a print control to `LeafletMap.svelte` as an optional feature.

---

## 5. QGIS Connectivity

There are three approaches to connect QGIS to the project data, from simplest to most capable:

### 5.1 Option A: Direct PostGIS Connection (Simplest)

QGIS connects directly to the Supabase PostgreSQL database.

**Setup required:**

1. Create a read-only database role in Supabase SQL editor:

```sql
-- Create a role for QGIS access
CREATE ROLE qgis_readonly LOGIN PASSWORD 'secure_password';
GRANT USAGE ON SCHEMA public TO qgis_readonly;
GRANT SELECT ON public.projects, public.project_layers, public.community TO qgis_readonly;

-- For read-write access (specific users)
CREATE ROLE qgis_editor LOGIN PASSWORD 'secure_password';
GRANT USAGE ON SCHEMA public TO qgis_editor;
GRANT SELECT, INSERT, UPDATE ON public.projects, public.project_layers TO qgis_editor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO qgis_editor;
```

1. In QGIS: Layer > Add Layer > Add PostGIS Layer, using the Supabase connection string (available from Supabase dashboard > Settings > Database).

**Pros:** Simplest setup, QGIS gets full PostGIS query capability, can edit geometry directly.
**Cons:** Exposes database directly, harder to enforce app-level RBAC, requires managing DB credentials per user.

### 5.2 Option B: OGC API / WFS via pg_featureserv (Recommended)

Deploy **pg_featureserv** (by CrunchyData) as a lightweight OGC-compliant feature server that reads directly from PostGIS.

**Setup:**

1. Deploy pg_featureserv as a Docker container or on a small VM, pointed at the Supabase PostgreSQL connection string
2. It auto-discovers PostGIS tables and publishes them as OGC API Features / WFS endpoints
3. QGIS connects via: Layer > Add Layer > Add WFS Layer

```yaml
# docker-compose.yml (example)
services:
  pg_featureserv:
    image: pramsey/pg_featureserv
    environment:
      DATABASE_URL: "postgresql://user:pass@db.xxxxx.supabase.co:5432/postgres"
    ports:
      - "9000:9000"
```

**In QGIS:**

- Add WFS connection: `http://your-server:9000/`
- Browse and add layers

**Pros:** Standard OGC protocol, QGIS-native, no direct DB exposure, supports filtering and spatial queries.
**Cons:** Requires hosting an additional service.

### 5.3 Option C: pg_tileserv for Tile-Based Access

If you also want to serve vector tiles (for web maps and QGIS):

- Deploy **pg_tileserv** alongside pg_featureserv
- Serves MVT (Mapbox Vector Tiles) directly from PostGIS
- QGIS 3.14+ supports vector tile layers

### 5.4 GeoJSON Export Endpoint (Quick Win)

Regardless of which QGIS approach you choose, add a GeoJSON export API:

```html
GET /api/projects/[projectId]/export/geojson
GET /api/projects/[projectId]/layers/[layerId]/export/geojson
```

This allows users to download data as GeoJSON and open it in any GIS tool, including QGIS.

---

## 6. Implementation Phases

### Phase 1: Project CRUD + Spatial Basics (Foundation)

**Goal:** Users can create, view, and edit projects with a map boundary.

| Task | Files to Change |
| ---- | -------------- |
| Add `geometry`, `bounds`, `description`, `status` columns to `projects` | Supabase migration |
| Regenerate `db.types.ts` | `src/lib/db.types.ts` |
| Implement project list server load | `src/routes/projects/+page.server.ts` |
| Implement project list page (table/cards with map overview) | `src/routes/projects/+page.svelte` |
| Implement project create form with map drawing | `src/routes/projects/new/+page.server.ts`, `+page.svelte` |
| Implement project view with map display | `src/routes/projects/[projectId]/+page.server.ts`, `+page.svelte` |
| Implement project edit with geometry editing | `src/routes/projects/[projectId]/edit/+page.server.ts`, `+page.svelte` |
| Create `ProjectMapView.svelte` composing existing map components | `src/components/maps/ProjectMapView.svelte` |
| Add RLS policies for projects | Supabase migration |
| Enforce RBAC on admin routes | `src/routes/admin/+layout.server.ts` |

**New dependencies:** None (uses existing Leaflet + Geoman).

### Phase 2: Overlay Spatial Layers

**Goal:** Users can upload and manage GeoJSON layers on projects.

| Task | Files to Change |
| ---- | -------------- |
| Create `project_layers` table | Supabase migration |
| Create layer API routes | `src/routes/api/projects/[projectId]/layers/+server.ts` |
| Build `LayerPanel.svelte` | New component |
| Build `LayerUpload.svelte` with GeoJSON/Shapefile parsing | New component |
| Build `LayerStyleEditor.svelte` | New component |
| Integrate layer panel into project view page | `src/routes/projects/[projectId]/+page.svelte` |
| Add dynamic GeoJSON layers to `ProjectMapView` | `src/components/maps/ProjectMapView.svelte` |

**New dependencies:** `shpjs` (Shapefile parsing), `togeojson` (KML parsing).

### Phase 3: Document & Image Attachments

**Goal:** Users can upload and manage files on projects.

| Task | Files to Change |
| ---- | -------------- |
| Create `project_attachments` table | Supabase migration |
| Create Supabase Storage buckets + policies | Supabase dashboard / migration |
| Create attachment API routes | `src/routes/api/projects/[projectId]/attachments/+server.ts` |
| Build `AttachmentUpload.svelte` | New component |
| Build `AttachmentList.svelte` | New component |
| Build `ImageGallery.svelte` | New component |
| Integrate into project view page | `src/routes/projects/[projectId]/+page.svelte` |

**New dependencies:** None (uses Supabase Storage).

### Phase 4: QGIS Connectivity + Export

**Goal:** Users can connect QGIS to project data.

| Task | Files to Change |
| ---- | -------------- |
| Create database roles for external access | Supabase migration |
| Add GeoJSON export API endpoints | `src/routes/api/projects/[projectId]/export/+server.ts` |
| Deploy pg_featureserv (if choosing OGC route) | Infrastructure / Docker |
| Document QGIS connection setup for users | New documentation |
| Add "Connect with QGIS" instructions to project view | `src/routes/projects/[projectId]/+page.svelte` |

**New dependencies:** pg_featureserv (infrastructure), or none if direct PostGIS only.

### Phase 5: Map Production

**Goal:** Users can print/export maps from the web app.

| Task | Files to Change |
| ---- | -------------- |
| Add `leaflet-easyprint` to `LeafletMap` | `src/components/maps/leaflet/LeafletMap.svelte` |
| Add print button to project map view | `src/components/maps/ProjectMapView.svelte` |
| Add map legend to print output | New CSS / component |
| (Optional) Server-side PDF generation | Supabase Edge Function or API route |

**New dependencies:** `leaflet-easyprint`.

### Phase 6: Polish & Complete

| Task | Details |
| ---- | ------- |
| Complete community CRUD (currently stubbed) | Wire up existing routes |
| Complete user management pages | Wire up existing routes |
| Implement project user management with role assignment | `/projects/[projectId]/users/` routes |
| Add activity feed | As documented in `user_routes.md` |
| Add project search/filter | As documented in `user_routes.md` |
| Full dark mode testing across all new components | Using existing theme system |

---

## 7. New NPM Dependencies

| Package | Purpose | Phase |
| ------- | ------- | ----- |
| `shpjs` | Parse Shapefiles to GeoJSON in browser | Phase 2 |
| `@tmcw/togeojson` | Parse KML/GPX to GeoJSON | Phase 2 |
| `leaflet-easyprint` | Map print/export | Phase 5 |

All other functionality can be built with existing dependencies (Leaflet, Geoman, Supabase, SvelteKit).

---

## 8. Architecture Decisions to Make

### 8.1 Spatial Layer Storage: GeoJSON in JSONB vs Dedicated PostGIS Tables

#### Option A: JSONB column (recommended for v1)**

- Store GeoJSON in `project_layers.geojson_data` as JSONB
- Simpler, no dynamic table creation needed
- Works well for layers up to ~10MB
- Limited spatial query capability on the data itself

#### Option B: Dynamic PostGIS tables (existing `projects_tables` pattern)**

- Your `spatial_schema.md` documents a `create_table_and_check()` system
- Each layer gets its own table in the `projects` schema with proper geometry columns
- Full PostGIS spatial query capability
- More complex, but better for QGIS integration and large datasets

**Recommendation:** Start with Option A. Migrate to Option B for layers that need spatial queries or QGIS editing.

### 8.2 QGIS Access Method

| Approach | Complexity | Security | QGIS Experience |
| -------- | --------- | -------- | --------------- |
| Direct PostGIS | Low | Lower (DB exposed) | Best (full PostGIS) |
| pg_featureserv (WFS) | Medium | Better (HTTP layer) | Good (standard WFS) |
| GeoJSON export only | Lowest | Best (read-only files) | Basic (no live editing) |

**Recommendation:** Start with GeoJSON export (Phase 4 quick win), then add direct PostGIS access with read-only roles. Add pg_featureserv later if you need proper WFS.

### 8.3 Map Library: Leaflet vs MapLibre GL

The codebase has both. The Leaflet stack is far more developed.

**Recommendation:** Standardise on **Leaflet** for now. The existing `LeafletMap` + `GeomanControls` + `LeafletGeoJSONPolygonLayer` components give you everything needed. Consider MapLibre GL later only if you need vector tiles or 3D terrain.

---

## 9. Existing Code to Leverage

These existing components can be used directly or with minor modifications:

| Component | Location | Use For |
| --------- | -------- | ------- |
| `LeafletMap.svelte` | `src/components/maps/leaflet/` | All project map views |
| `GeomanControls.svelte` | `src/components/maps/leaflet/controls/` | Drawing project boundaries and layer features |
| `LeafletGeoJSONPolygonLayer.svelte` | `src/components/maps/leaflet/layers/geojson/` | Rendering project boundary and overlay layers |
| `ThreePanelLayout.svelte` | `src/components/structure/` | Project detail page layout |
| `SidebarNavigationMenu.svelte` | `src/components/structure/` | Project sidebar navigation |
| `UploadAvatar.svelte` | `src/components/` | Pattern for file upload components |
| NSW base layers config | `src/routes/communities/+page.svelte` | Base layer definitions for project maps |

---

## 10. Existing Issues to Fix

During investigation, these issues were noted:

1. **Broken user links in root layout** — `href="/users/[{user.id}]/profile"` should be `href="/users/{user.id}/profile"` (remove the square brackets — Svelte embeds expressions with `{expr}` inside quoted attributes)
2. **Admin route guard is a stub** — `src/routes/admin/+layout.server.ts` has a TODO but no actual role check
3. **Debug console.log statements** — `LeafletBasicReactiveMap.svelte` has leftover `console.log` calls
4. **Communities page uses basic map** — Should use the full-featured `LeafletMap` with `LeafletGeoJSONPolygonLayer` (commented-out code suggests this was intended)
5. **No database migrations in version control** — Schema changes are managed directly in Supabase. Consider adopting `supabase db diff` workflow documented in `supabase_local.md`

---

## 11. Summary of All New Files

```text
# Database migrations (in supabase/migrations/)
supabase/migrations/YYYYMMDD_add_project_spatial.sql
supabase/migrations/YYYYMMDD_create_project_layers.sql
supabase/migrations/YYYYMMDD_create_project_attachments.sql
supabase/migrations/YYYYMMDD_add_rls_policies.sql
supabase/migrations/YYYYMMDD_create_storage_buckets.sql
supabase/migrations/YYYYMMDD_create_qgis_roles.sql

# New components
src/components/maps/ProjectMapView.svelte
src/components/projects/LayerPanel.svelte
src/components/projects/LayerUpload.svelte
src/components/projects/LayerStyleEditor.svelte
src/components/projects/AttachmentList.svelte
src/components/projects/AttachmentUpload.svelte
src/components/projects/ImageGallery.svelte

# New API routes
src/routes/api/projects/[projectId]/attachments/+server.ts
src/routes/api/projects/[projectId]/attachments/[attachmentId]/+server.ts
src/routes/api/projects/[projectId]/layers/+server.ts
src/routes/api/projects/[projectId]/layers/[layerId]/+server.ts
src/routes/api/projects/[projectId]/export/+server.ts

# Modified files (implement stubbed CRUD)
src/routes/projects/+page.server.ts
src/routes/projects/+page.svelte
src/routes/projects/new/+page.server.ts
src/routes/projects/new/+page.svelte
src/routes/projects/[projectId]/+page.server.ts
src/routes/projects/[projectId]/+page.svelte
src/routes/projects/[projectId]/edit/+page.server.ts
src/routes/projects/[projectId]/edit/+page.svelte
src/routes/admin/+layout.server.ts
src/lib/db.types.ts (regenerated)
```
