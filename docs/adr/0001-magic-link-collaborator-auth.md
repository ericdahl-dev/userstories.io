# ADR 0001 — Magic Link Authentication for Collaborators

## Status

Accepted

## Context

Collaborators are non-technical users (product owners, managers, stakeholders) who are
invited by a developer to submit user stories against a GitHub project. They are not
developers themselves and have no existing account on userstories.io.

The MVP access model uses a shareable link (no email invitations). When a collaborator
arrives via that link, we need a way to establish their identity with minimum friction.
Password-based signup is disproportionate to the task — they are being asked to do
something simple by someone they trust, and a password creates unnecessary cognitive
overhead and a credential they will likely never reuse.

We also need persistent identity: the same collaborator should see all their previous
submissions across return visits, so anonymous/session-only access is insufficient.

## Decision

Collaborators authenticate via **magic link (passwordless email login)**.

The flow:

1. Collaborator arrives at `userstories.io/p/:share_token` (the developer's shareable link).
2. They are prompted to enter their email address.
3. The app finds-or-creates a `Collaborator` record keyed on that email.
4. A short-lived `MagicToken` is generated and a login link is emailed to them.
5. Clicking the link validates the token, establishes a session, and redirects them to
   their submissions view for that project.
6. The token is single-use and expires (15 minutes).

## Implementation notes

- `MagicToken` model: `collaborator_id`, `token` (secure random hex), `expires_at`, `used_at`.
- Token is validated in a `SessionsController` action; consumed on first use.
- Session stores `collaborator_id` (separate from the developer `User` session).
- No Devise for collaborators — a lightweight custom implementation is cleaner given
  the scoped, passwordless nature of their access.
- Developers authenticate separately via Devise (standard username/password or OAuth).

## Alternatives considered

**Shareable link = session token (no email required)**
The link itself grants access without identifying the individual. Rejected because
attribution matters — the developer needs to know *who* submitted each story, not just
that someone with the link did. Also weaker security: anyone who obtains the link can
submit stories.

**Devise passwordless gem**
Would work but adds Devise complexity for a user type that doesn't need most of Devise's
features. A custom `MagicToken` model is ~50 lines and exactly scoped to the use case.

**OAuth (Google, GitHub)**
Higher friction for non-technical users. Adds third-party dependency. Overkill for MVP.

## Consequences

- Collaborators need access to their email to log in. This is acceptable — the developer
  is already communicating with them by some means to share the link.
- Email delivery reliability matters. A failed magic link email blocks access. Ensure
  transactional email is configured before launch.
- No password reset flow needed — magic link IS the auth mechanism.
