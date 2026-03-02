# Implementation Plan — bendev-web

**Generated:** 2026-03-01
**Based on:** `docs/implementation-roadmap.md` + codebase audit

---

## Current State vs Roadmap

### Database — Complete

All database migrations from the roadmap are in version control and applied:

| Migration | Status |
| --------- | ------ |
| `geometry`, `bounds`, `description`, `status`, `start_date`, `end_date`, `community_id` on `projects` | ✅ Done |
| `project_layers` table + indexes + RLS | ✅ Done |
| `project_attachments` table + indexes + RLS | ✅ Done |
| Storage buckets (`project-attachments`, `project-images`) + policies | ✅ Done |
| User roles on signup trigger (`handle_new_user`) | ✅ Done |

### Infrastructure — Complete

| Item | Status |
| ---- | ------ |
| Admin route guard (`requireGlobalAdmin`) | ✅ Done |
| Skeleton v4 + Tailwind v4 migration | ✅ Done |
| No `svelte-5-ui-lib` / `flowbite-svelte` imports remaining | ✅ Done |

### Frontend + API — Remaining Work

| Area | Status |
| ---- | ------ |
| `projects/+page.server.ts` | ❌ Stub — returns `{}` |
| `projects/+page.svelte` | ❌ Stub |
| `projects/new/+page.server.ts` | ❌ Stub — returns `{}` |
| `projects/new/+page.svelte` | ❌ Stub |
| `projects/[projectId]/+page.server.ts` | ❌ Stub — returns `{}` |
| `projects/[projectId]/+page.svelte` | ❌ `// TODO Specific project` |
| `projects/[projectId]/edit/` | ❌ Stub |
| `projects/[projectId]/users/` | ❌ Stub |
| `communities/[communityId]/+page.server.ts` | ❌ Stub |
| `communities/[communityId]/+page.svelte` | ❌ Stub |
| `communities/new/` | ❌ Stub |
| `users/+page.svelte` | ❌ Has sidebar nav, `// TODO: User list` in main |
| `src/routes/api/projects/` | ❌ Does not exist |
| `src/components/projects/` | ❌ Does not exist |
| `src/components/maps/ProjectMapView.svelte` | ❌ Does not exist |
| `src/lib/db.types.ts` | ❌ Needs regeneration to include new schema columns |
| `auth/verifying/+page.svelte` | ❌ Template literal bug + "dasboard" typo |

---

## Immediate Fixes

Quick wins before starting Phase 1 — no design decisions needed.

1. **Fix `auth/verifying/+page.svelte`**
   - `goto('/users/[{user.id}]/dasboard')` → `` goto(`/users/${user.id}/dashboard`) ``

2. **Remove debug `console.log`** in `src/components/maps/leaflet/LeafletBasicReactiveMap.svelte`

3. **Regenerate `src/lib/db.types.ts`**

   ```bash
   npx supabase gen types typescript --local > src/lib/db.types.ts
   ```

   Required to expose `geometry`, `bounds`, `status`, `project_layers`, `project_attachments` to TypeScript.

4. **Check root layout for broken user links** — look for `href="/users/[{user.id}]/..."` pattern and fix template literal syntax.

---

## Phase 1 — Project CRUD + Spatial Basics

**Goal:** Users can list, create, view, and edit projects with a map boundary drawn on a Leaflet map.

**New dependencies:** None (uses existing Leaflet + Geoman).

### Tasks (in order)

| # | Task | Files |
| - | ---- | ----- |
| 1 | Load project list from Supabase | `src/routes/projects/+page.server.ts` |
| 2 | Project list page — card/table view with status badges, link to new/view | `src/routes/projects/+page.svelte` |
| 3 | `ProjectMapView.svelte` — compose `LeafletMap` + `LeafletGeoJSONPolygonLayer` + optional `GeomanControls`; props: `geometry`, `editable`, `layers` | `src/components/maps/ProjectMapView.svelte` |
| 4 | Project create form — name, description, status, dates, community dropdown, map drawing; serialise drawn geometry to hidden GeoJSON input | `src/routes/projects/new/+page.svelte` |
| 5 | Project create action — insert project, assign creator as `owner` in `user_roles`, redirect to `/projects/[id]` | `src/routes/projects/new/+page.server.ts` |
| 6 | Project view server — load project + layers via joined query; expose user's project role | `src/routes/projects/[projectId]/+page.server.ts` |
| 7 | Project view page — map (via `ProjectMapView`), detail panel, placeholder tabs for Layers / Documents / Users | `src/routes/projects/[projectId]/+page.svelte` |
| 8 | Project edit form + action — same form as create, pre-populated; update with RBAC check (owner/admin/editor) | `src/routes/projects/[projectId]/edit/+page.server.ts` + `+page.svelte` |
| 9 | Project members page — list project members + roles, add/remove with role selector | `src/routes/projects/[projectId]/users/+page.server.ts` + `+page.svelte` |

---

## Phase 2 — Overlay Spatial Layers

**Goal:** Users with editor/gis role can upload and manage GeoJSON layers; layers render on the project map.

**New dependencies:** `shpjs` (Shapefile → GeoJSON), `@tmcw/togeojson` (KML/GPX → GeoJSON).

### Phase 2 Tasks

| # | Task | Files |
| - | ---- | ----- |
| 1 | Layer API — `GET` list, `POST` create/upload; RBAC check for write | `src/routes/api/projects/[projectId]/layers/+server.ts` |
| 2 | Layer detail API — `PUT` update style/visibility, `DELETE` | `src/routes/api/projects/[projectId]/layers/[layerId]/+server.ts` |
| 3 | `LayerUpload.svelte` — file input for GeoJSON/Shapefile `.zip`/KML; client-side conversion; map preview; POST to API | `src/components/projects/LayerUpload.svelte` |
| 4 | `LayerPanel.svelte` — ordered list of layers with visibility toggle, reorder handle, delete | `src/components/projects/LayerPanel.svelte` |
| 5 | `LayerStyleEditor.svelte` — fill colour, stroke colour, opacity sliders; save via PUT | `src/components/projects/LayerStyleEditor.svelte` |
| 6 | Wire into project view — add layer panel + upload to `[projectId]/+page.svelte`; pass layers to `ProjectMapView` | `src/routes/projects/[projectId]/+page.svelte` + `ProjectMapView.svelte` |

---

## Phase 3 — Document & Image Attachments

**Goal:** Users can upload and manage files (documents, images, reports) attached to projects.

**New dependencies:** None (uses Supabase Storage).

### Phase 3 Tasks

| # | Task | Files |
| - | ---- | ----- |
| 1 | Attachment API — `GET` list, `POST` multipart upload to Supabase Storage; insert record in `project_attachments` | `src/routes/api/projects/[projectId]/attachments/+server.ts` |
| 2 | Attachment detail API — signed URL download, `DELETE` from storage + DB | `src/routes/api/projects/[projectId]/attachments/[attachmentId]/+server.ts` |
| 3 | `AttachmentUpload.svelte` — drag-and-drop, category selector, progress indicator | `src/components/projects/AttachmentUpload.svelte` |
| 4 | `AttachmentList.svelte` — table/grid with file name, type, size, category, download and delete actions | `src/components/projects/AttachmentList.svelte` |
| 5 | `ImageGallery.svelte` — thumbnail grid for image-category attachments using signed URLs | `src/components/projects/ImageGallery.svelte` |
| 6 | Wire into project view — add to Documents / Images tabs in `[projectId]/+page.svelte` | `src/routes/projects/[projectId]/+page.svelte` |

---

## Phase 4 — GeoJSON Export + QGIS (Quick Win)

**Goal:** Users can download project data as GeoJSON and open it in QGIS.

**New dependencies:** None.

### Phase 4 Tasks

| # | Task | Files |
| - | ---- | ----- |
| 1 | Export API — `GET /api/projects/[projectId]/export/geojson` returning project boundary + all layers as GeoJSON FeatureCollection | `src/routes/api/projects/[projectId]/export/+server.ts` |
| 2 | Per-layer export — `GET /api/projects/[projectId]/layers/[layerId]/export/geojson` | `src/routes/api/projects/[projectId]/layers/[layerId]/+server.ts` (extend) |
| 3 | Add "Export GeoJSON" button to project view page | `src/routes/projects/[projectId]/+page.svelte` |
| 4 | Document QGIS direct PostGIS connection setup | `documentation/qgis-connection.md` |

---

## Phase 5 — Community CRUD (Complete Stubs)

**Goal:** Communities are fully functional — not just listable.

**New dependencies:** None.

### Phase 5 Tasks

| # | Task | Files |
| - | ---- | ----- |
| 1 | Community view — details, map with extent boundary, member list | `src/routes/communities/[communityId]/+page.server.ts` + `+page.svelte` |
| 2 | Community edit — name, description, extent drawing via Geoman | `src/routes/communities/[communityId]/edit/+page.server.ts` + `+page.svelte` |
| 3 | Community create — form with map boundary drawing, assign creator as owner | `src/routes/communities/new/+page.server.ts` + `+page.svelte` |
| 4 | Community members — list, add with role, change role, remove | `src/routes/communities/[communityId]/users/+page.server.ts` + `+page.svelte` |

---

## Phase 6 — User Section + Map Print + Polish

**Goal:** User browsing, map printing, and dark mode consistency across all new components.

| # | Task | Files |
| - | ---- | ----- |
| 1 | User list/browse — paginated public profile list | `src/routes/users/+page.server.ts` + `+page.svelte` |
| 2 | Public user profile view | `src/routes/users/[userId]/profile/+page.svelte` |
| 3 | User communities tab | `src/routes/users/[userId]/communities/+page.svelte` |
| 4 | Map print — add `leaflet-easyprint` print button to `ProjectMapView` | `src/components/maps/ProjectMapView.svelte` |
| 5 | Dark mode pass — verify all new components respect `data-mode` | All new components |

---

## New Files Summary

```text
# API routes (new)
src/routes/api/projects/[projectId]/attachments/+server.ts
src/routes/api/projects/[projectId]/attachments/[attachmentId]/+server.ts
src/routes/api/projects/[projectId]/layers/+server.ts
src/routes/api/projects/[projectId]/layers/[layerId]/+server.ts
src/routes/api/projects/[projectId]/export/+server.ts

# Map component (new)
src/components/maps/ProjectMapView.svelte

# Project components (new directory)
src/components/projects/LayerPanel.svelte
src/components/projects/LayerUpload.svelte
src/components/projects/LayerStyleEditor.svelte
src/components/projects/AttachmentList.svelte
src/components/projects/AttachmentUpload.svelte
src/components/projects/ImageGallery.svelte

# Documentation (new)
documentation/qgis-connection.md
```

## Modified Files Summary

```text
# Core type definitions
src/lib/db.types.ts                                  # Regenerate from Supabase

# Bug fixes
src/routes/auth/verifying/+page.svelte               # Fix template literal + typo
src/components/maps/leaflet/LeafletBasicReactiveMap.svelte  # Remove console.log

# Project routes (implement stubs)
src/routes/projects/+page.server.ts
src/routes/projects/+page.svelte
src/routes/projects/new/+page.server.ts
src/routes/projects/new/+page.svelte
src/routes/projects/[projectId]/+page.server.ts
src/routes/projects/[projectId]/+page.svelte
src/routes/projects/[projectId]/edit/+page.server.ts
src/routes/projects/[projectId]/edit/+page.svelte
src/routes/projects/[projectId]/users/+page.server.ts
src/routes/projects/[projectId]/users/+page.svelte

# Community routes (implement stubs)
src/routes/communities/new/+page.server.ts
src/routes/communities/new/+page.svelte
src/routes/communities/[communityId]/+page.server.ts
src/routes/communities/[communityId]/+page.svelte
src/routes/communities/[communityId]/edit/+page.server.ts
src/routes/communities/[communityId]/edit/+page.svelte
src/routes/communities/[communityId]/users/+page.server.ts
src/routes/communities/[communityId]/users/+page.svelte

# User routes (implement stubs)
src/routes/users/+page.server.ts
src/routes/users/+page.svelte
src/routes/users/[userId]/profile/+page.svelte
src/routes/users/[userId]/communities/+page.svelte
```

---

## Architecture Decisions (Confirmed)

| Decision | Choice | Rationale |
| -------- | ------ | --------- |
| Map library | **Leaflet** (standardise) | Existing `LeafletMap` + `GeomanControls` + `LeafletGeoJSONPolygonLayer` cover all needs |
| Spatial layer storage | **JSONB** in `project_layers.geojson_data` | Simpler for v1; migrate to dynamic PostGIS tables if spatial queries are needed later |
| Shapefile conversion | **Client-side** (`shpjs`) | No server processing needed for v1 |
| QGIS connectivity | **GeoJSON export** for v1, then direct PostGIS read-only roles | Lowest complexity, sufficient for initial use |
| Map production | **`leaflet-easyprint`** for v1 | Quick to implement; server-side PDF deferred |

---

**Reference:** `docs/implementation-roadmap.md` — original design document with SQL, API, and QGIS setup details.
