# userstories.io — Agent Instructions

Two-sided platform bridging GitHub-based development workflows with non-technical
collaborators. Developers connect GitHub repos and manage a triage inbox; collaborators
submit user stories via a shareable link without needing GitHub access.

## Platform Baseline

This app follows the shared Rails 8 platform baseline:
https://github.com/ericdahl-dev/rails-platform

Read `PLATFORM.md` and `BASELINE.md` there before making architectural decisions.
Deviations from the baseline must be recorded as ADRs in `docs/adr/`.

## Useful Commands

```bash
# Development
bin/rails server                    # start web server
bin/rails tailwindcss:watch         # watch CSS (run alongside server)
bundle exec good_job start          # start background worker (not needed in dev — runs async)

# Testing
bundle exec rspec                   # full suite
bundle exec rspec spec/models/
bundle exec rspec spec/requests/
bundle exec rspec spec/system/

# Quality gates (run before every PR)
bundle exec brakeman -q
bundle exec bundler-audit check --update
bundle exec rubocop

# Database
bin/rails db:prepare                # create + migrate (safe to re-run)
bin/rails db:migrate
bin/rails db:seed
```

## Build & Test

```bash
rvm use .                           # activate Ruby version from .ruby-version
bundle install
bin/rails db:prepare
bundle exec rspec
```

PostgreSQL must include **pgvector** (submission embeddings). For local dev/test, run
`docker compose up -d postgres` and set `DATABASE_URL` in `.env` — see `.env.example`.
Production and CI also set `DATABASE_URL` explicitly.

## Key Decisions

See `docs/adr/` for full decision records. Summary:

- **Collaborator auth**: magic link (passwordless email). No Devise for collaborators.
  Custom `MagicToken` model. Developer auth uses Devise separately. (ADR 0001)
- **Collaborator identity**: global, keyed on email. One `Collaborator` record per
  person across all projects. (ADR 0002)
- **Triage flow**: submissions go `pending → accepted → shipped`. Developer must accept
  before a GitHub issue is created. (ADR 0003)
- **Access model**: shareable link (`/p/:share_token`) — no email invitations in MVP.
  Rotating `share_token` revokes access. (ADR 0004)

## Data Model

See `docs/data-model.md` for the full schema and relationship map.

Core models: `User` (developer), `Project`, `Collaborator`, `Submission`, `MagicToken`.

## Authorization

Pundit is used throughout. Two distinct session types:

- Developer session: `current_user` (Devise) — scoped to their own projects/submissions
- Collaborator session: `current_collaborator` (custom) — scoped to their own submissions only

`ApplicationController` includes `Pundit::Authorization`. Every controller action calls
`authorize` or `policy_scope`. `verify_authorized` / `verify_policy_scoped` after_actions
are enforced.

Never mix developer and collaborator session keys — they are independent.

## GitHub Integration

Developers connect via GitHub OAuth. The OAuth token is stored encrypted on `User`.
Issue creation on submission acceptance uses the Octokit gem with the developer's token.

The `/p/:share_token` portal is collaborator-facing and has no GitHub dependency.

## Routes Shape

```
/                          → landing page (branded, day-one requirement)
/p/:share_token            → collaborator submission portal (unauthenticated entry point)
/p/:share_token/sessions   → magic link email prompt + token validation
/dashboard                 → developer triage inbox
/projects                  → developer project management
/auth/github               → GitHub OAuth (Devise + OmniAuth)
```

## Learned Workspace Facts

_(add environment-specific gotchas here as they are discovered)_

- macOS: `PGGSSENCMODE=disable` initializer present at
  `config/initializers/0_pg_gssenc_fork_safety.rb` — do not remove

## Secrets Management

Secrets are stored in **Doppler** (project: `userstories`) and synced to Coolify env
vars via:

```bash
./script/sync_doppler_to_coolify.sh
```

- `prd` → production deploys
- `stg` → PR preview deploys (`is_preview=true` in Coolify)

To rotate or update a secret:
1. Update the value in Doppler (`doppler secrets set --project userstories --config prd|stg KEY value`)
2. Run the sync script to push to Coolify and restart the app

Do **not** edit env vars directly in the Coolify dashboard — they will be overwritten
on the next sync. Doppler is the source of truth.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (`gh issue create` / `gh issue view`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: `CONTEXT.md` at root + `docs/adr/`. See `docs/agents/domain.md`.
