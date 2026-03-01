# Project Instructions for Claude

## Project: bendev-web

This project uses an AI-assisted development system for design documentation, conventions, and domain knowledge.

## Knowledge System Location

`~/projects/ai/ai-dev-system/`

## Before Responding to Implementation Questions

1. **Read the grounding protocol**: `~/projects/ai/ai-dev-system/core/prompts/grounding-protocol.md`
2. **Check project design docs**: `~/projects/ai/ai-dev-system/projects/bendev-web/design/`
3. **Follow conventions**: `~/projects/ai/ai-dev-system/core/conventions/`
4. **Reference domain knowledge**: `~/projects/ai/ai-dev-system/domains/community-environmental-management/`

## Source Priority (highest to lowest)

1. Project design documents and ADRs in `~/projects/ai/ai-dev-system/projects/bendev-web/design/`
2. Code conventions in `~/projects/ai/ai-dev-system/core/conventions/`
3. Library documentation (via GitHub MCP or Fetch MCP)
4. Domain knowledge in `~/projects/ai/ai-dev-system/domains/community-environmental-management/`
5. General knowledge (flag as unverified)

## When Providing Code

- Follow patterns in `~/projects/ai/ai-dev-system/core/conventions/component-patterns.md`
- Follow database conventions in `~/projects/ai/ai-dev-system/core/conventions/database-conventions.md`
- Follow API conventions in `~/projects/ai/ai-dev-system/core/conventions/api-conventions.md`
- Cite sources for technical recommendations
- Flag uncertainty rather than guessing

## Project Context

| Attribute | Value |
| --------- | ----- |
| **Project name** | bendev-web |
| **Domain** | Community Environmental Management |
| **Design docs** | `~/projects/ai/ai-dev-system/projects/bendev-web/design/` |
| **Current iteration** | v0.3 (Skeleton v4 migration complete — 2026-03-01) |
| **Related project** | community-orgs-portal (same repo) |

## Technology Stack

| Layer | Technology | Version |
| ----- | ---------- | ------- |
| **Frontend** | SvelteKit + Svelte 5 (runes) | svelte ^5.1.0, @sveltejs/kit ^2.7.2 |
| **UI Library** | Skeleton v4 (no AppShell — semantic HTML + Tailwind grid) | @skeletonlabs/skeleton ^4.12.0, @skeletonlabs/skeleton-svelte ^4.12.0 |
| **CSS** | Tailwind v4 (Vite plugin — no postcss config, no tailwind.config.ts) | tailwindcss ^4.1.18 |
| **Backend** | Supabase (PostgreSQL + PostGIS + Auth) | @supabase/supabase-js ^2.45.6 |
| **Spatial** | PostGIS | — |
| **Mapping** | TBD (Leaflet or OpenLayers) | — |

## Completed Migrations

- **v0.3** — Migrated from `svelte-5-ui-lib` (Flowbite-based) to Skeleton v4 + Tailwind v4. All
  `svelte-5-ui-lib`/`flowbite-svelte` imports removed. Layout restructured to semantic HTML + Tailwind
  grid (no AppShell). zxcvbn loaded via dynamic import in `onMount` to avoid large bundle chunk.
  See design doc: `~/projects/ai/ai-dev-system/projects/bendev-web/design/iterations/v0.3-skeleton-v4-migration.md`

## Key Commands

```bash
npm run dev      # Development server
npm run build    # Production build
npm run check    # Svelte type check
```

## Route Structure

```text
src/routes/
├── +layout.svelte / +layout.server.ts / +layout.ts
├── +page.svelte                    # Home / landing
├── admin/
├── api/
├── auth/
│   ├── callback/                   # OAuth callback
│   ├── signin/                     # Email + OAuth (azure, discord, github, google)
│   ├── signup/
│   ├── signout/
│   ├── reset/password/
│   ├── set/password/ + set/profile/
│   ├── verifying/                  # Email verification polling page
│   └── auth-code-error / auth-error / auth-invite-error / auth-verify-error
├── communities/
├── projects/
│   ├── new/
│   └── [projectId]/
├── testing/
└── users/
    ├── +page.svelte
    └── [userId]/
        ├── +layout.svelte
        ├── communities/
        ├── dashboard/
        └── profile/
```

## Component Structure

```text
src/components/
├── UploadAvatar.svelte
├── admin/
├── auth/
│   ├── EmailRegistrationInput.svelte   # Email + password + confirm (zxcvbn strength)
│   ├── PasswordSet.svelte              # Password + confirm (zxcvbn strength)
│   └── SocialMediaRegistrationInput.svelte
├── custom/
├── icons/                              # Icons.svelte wrapper
├── maps/
└── structure/
    └── ThreePanelLayout.svelte
```

## Important Files

- `src/routes/layout.css` — Tailwind v4 CSS entrypoint (imports theme + @tailwind utilities)
- `src/theme-bendev.css` — Skeleton v4 custom theme (CSS custom properties)
- `src/app.html` — Sets `data-theme="bendev"` on `<html>`
- `src/stores/app.ts` — `themeStore` watches `data-mode` attribute for dark/light
- `supabase/migrations/` — Database migrations

## Database Notes

- Users get a default `global` `member` role on signup via `handle_new_user()` trigger
- Table: `public.user_roles` with `user_id`, `role_type`, `role_name`, `entity_id`
- Role types: `global`, `project`, `community`
- Latest migration: `20260217000000_add_default_user_role_on_signup.sql`

## Related Project

This project shares a repository with `community-orgs-portal`.
Design docs for that project: `~/projects/ai/ai-dev-system/projects/community-orgs-portal/design/`
