# Supabase MCP + Supabase CLI: Workspace Setup (bendev-web)

This repo already has Supabase configuration checked in (see `supabase/config.toml`) and MCP configs for both VS Code and Claude Code. This document explains how to finish wiring your local environment so you get the *full* value from:

- **Supabase MCP server** (project introspection, SQL execution, migrations, Edge Functions, logs/advisors)
- **Supabase CLI** (local stack, schema diffs/migrations, type generation)

> Security note: do **not** commit tokens/keys. This repo already ignores `.env`, `.envrc*`, and `supabase/.env`.

---

## 1) What’s already in this repo

### MCP configs

- VS Code MCP config: `.vscode/mcp.json`
- Claude Code MCP config: `.mcp.json`

Both are configured to use the **hosted Supabase MCP endpoint**:

- `https://mcp.supabase.com/mcp?project_ref=...`
- `Authorization: Bearer ...`

So you do **not** need to install `@anthropic-ai/mcp-server-supabase` unless you *prefer* running a local MCP binary (see Option B below).

### Supabase local config

- Local stack ports and auth settings: `supabase/config.toml`
- SQL seed file: `supabase/seed.sql`
- Email templates exist in both:
  - repo root `email_templates/`
  - `supabase/email_templates/`

`supabase/config.toml` currently points auth templates at the **Supabase email templates**:

- `./supabase/email_templates/invite.html`
- `./supabase/email_templates/magic_link.html`
- `./supabase/email_templates/recovery.html`
- `./supabase/email_templates/verify.html`

### Current gaps (normal for early projects)

- No `supabase/migrations/` directory yet.
  - That’s fine — it appears schema changes haven’t been captured as migrations in this repo yet.

---

## 2) Required secrets and environment variables

### For Supabase MCP (hosted)

Your MCP config expands these environment variables:

- `SUPABASE_ACCESS_TOKEN` (Supabase personal access token)
- `SUPABASE_PROJECT_REF` (the project ref in your dashboard URL)

If either is missing, you’ll see errors like:

- `401 ... Format is Authorization: Bearer [token]`

### For the app runtime (SvelteKit)

This repo provides `.env.example` with the public runtime values:

- `PUBLIC_SUPABASE_URL`
- `PUBLIC_SUPABASE_ANON_KEY`

You’ll typically set these in a local `.env` (ignored by git) for app development.

---

## 3) Recommended secrets workflow (Linux-friendly)

Because `.vscode/mcp.json` uses `${env:VAR}` (VS Code process environment), the *most reliable* workflow is:

1. Put secrets into `.envrc`
2. Load them with `direnv`
3. Launch VS Code from that same shell (`code .`)

### 3.1 Create `.envrc` (ignored)

Create a file named `.envrc` in the repo root:

```bash
export SUPABASE_ACCESS_TOKEN="<your_supabase_pat>"
export SUPABASE_PROJECT_REF="<your_project_ref>"

# Optional: if you use the GitHub MCP server in .vscode/mcp.json
export GITHUB_BENDATADEV_PERSONAL_ACCESS_TOKEN="<your_github_pat>"
```

### 3.2 Enable `direnv`

```bash
direnv allow
```

### 3.3 Launch VS Code with environment loaded

From the repo root:

```bash
code .
```

> If you open VS Code from the OS launcher, it may not inherit your shell env vars, and MCP auth can fail.

---

## 4) MCP configuration options

### Option A (current repo): Hosted Supabase MCP (recommended)

Nothing to install — just ensure `SUPABASE_ACCESS_TOKEN` and `SUPABASE_PROJECT_REF` are set.

What you get:

- Consistent access to project resources (tables, SQL, Edge Functions, logs/advisors)
- No local Node global installs

### Option B: Local Supabase MCP server (only if you want it)

This is the approach described in `docs/MCP_SETUP_GUIDE.md` (installing an MCP server binary and using `type: stdio`).

When it’s useful:

- You want MCP to work without the hosted endpoint
- You want a pinned local MCP server version in your tooling

If you go this route, keep secrets out of git (same `.envrc` strategy applies).

---

## 5) Supabase CLI setup (best practice)

Supabase docs recommend using the CLI via a dev dependency:

```bash
npm install supabase --save-dev
```

This makes `npx supabase ...` consistent across the team.

### 5.1 Prerequisites

- Docker installed and running (Supabase local stack runs via Docker)
- Node.js installed (already required by this repo)

### 5.2 Initialize (already done here)

This repo already contains `supabase/config.toml`, so it has effectively been initialized.

If you ever need to re-init in a fresh repo, it’s:

```bash
npx supabase init
```

### 5.3 Login + link to remote

```bash
npx supabase login
npx supabase link --project-ref "$SUPABASE_PROJECT_REF"
```

Linking allows commands like generating types and pushing migrations to target the correct project.

---

## 6) Local Supabase stack workflow

### 6.1 Start local stack

```bash
npx supabase start
```

Key local services from `supabase/config.toml`:

- Studio: [http://127.0.0.1:54323](http://127.0.0.1:54323)
- API: [http://127.0.0.1:54321](http://127.0.0.1:54321)
- DB: `localhost:54322`

### 6.2 Reset local DB (apply migrations + seed)

Once you start using migrations, the typical “clean slate” command is:

```bash
npx supabase db reset
```

This applies migrations in order and runs `supabase/seed.sql`.

---

## 7) Migrations: capturing schema changes in git

Right now, there’s no `supabase/migrations/` folder in the repo. To start managing schema changes properly:

1. Make schema changes (locally)
2. Generate a migration SQL file
3. Review it
4. Apply it locally
5. Commit it

Typical CLI workflow:

```bash
# Ensure local DB is running (required for db diff)
npx supabase start

# Generate a migration from changes
npx supabase db diff -f create_initial_schema

# Apply migrations to your local DB
npx supabase db push
```

Notes:

- If you see `connect: connection refused` to `127.0.0.1:54322`, the local stack isn’t running yet. Run `npx supabase start` (or check `npx supabase status`).
- Keep migrations small and focused.
- Prefer migrations over “clicking changes” directly in production.
- If you already have a remote schema you want to baseline into migrations, you may want an initial capture step (team-dependent). If you want, I can help propose a safe baseline plan.

---

## 8) Type generation (make `src/lib/db.types.ts` reliable)

This repo has a script:

- `npm run update-db-types`

It currently uses a hard-coded `--project-id` value in `package.json`. For team friendliness, consider switching the script to use `SUPABASE_PROJECT_REF`.

### Remote types (from hosted Supabase)

```bash
npx supabase gen types typescript \
  --project-id "$SUPABASE_PROJECT_REF" \
  --schema public \
  > src/lib/db.types.ts
```

### Local types (from local stack)

```bash
npx supabase gen types typescript --local > src/lib/db.types.ts
```

When to use which:

- Use `--local` when iterating on schema locally.
- Use `--project-id` when you want types from the remote environment.

---

## 9) Edge Functions (optional, but supported by this repo)

There’s a GitHub Action workflow at `.github/workflows/supabase-keepalive.yml` that pings an Edge Function URL.

If you add Edge Functions to this repo later, the usual conventions are:

- Store functions under `supabase/functions/<function-name>/`
- Use VS Code Deno tooling (this repo already enables Deno paths in `.vscode/settings.json`)

CLI examples (once functions exist):

```bash
npx supabase functions serve
npx supabase functions deploy <function-name>
```

---

## 10) “Fullest advantage” workflow (practical daily loop)

- **Local dev**: `npx supabase start` + `npm run dev`
- **Schema changes**: change locally → `npx supabase db diff -f ...` → commit migrations
- **Sync remote**: `npx supabase db push` (after linking)
- **Types**: regenerate via `npx supabase gen types ... > src/lib/db.types.ts`
- **Use MCP for**:
  - quick project introspection (“what tables exist?”)
  - running *read-only* queries for debugging
  - checking logs/advisors
  - Edge Function inspection/deploy (if you use that feature)

---

## 11) Troubleshooting

### MCP 401 / auth errors

- Ensure you set `SUPABASE_ACCESS_TOKEN` and `SUPABASE_PROJECT_REF`
- Ensure VS Code inherited your environment (launch with `code .` from a shell where `direnv` has loaded `.envrc`)

### Supabase local stack won’t start

- Ensure Docker is running
- Check ports in `supabase/config.toml` aren’t already in use

### Types generation fails

- Make sure you ran `npx supabase login`
- If generating from remote: ensure you linked the project (`npx supabase link --project-ref ...`)

---

## 12) Suggested small repo improvements (optional)

These are not required, but they typically make the setup smoother for teams:

- Add `.envrc.example` with *variable names only* (no secrets)
