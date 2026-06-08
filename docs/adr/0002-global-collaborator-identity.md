# ADR 0002 — Global Collaborator Identity (Cross-Project)

## Status

Accepted

## Context

A collaborator is a person invited by a developer to submit user stories against a
specific project. The platform is multi-tenant: many developers each have their own
projects, and any given collaborator (e.g. a product manager) might be invited to
contribute to projects owned by different developers.

We need to decide whether a collaborator's identity is:

- **Per-project** — a separate record and login per project they're invited to, or
- **Global** — one identity across the whole platform, keyed on email

## Decision

Collaborator identity is **global**, keyed on email address.

A single `Collaborator` record represents a person across all projects they participate
in. When they log in via magic link, they land on a view of their own submissions —
filterable by project — rather than being siloed into a single project context.

## Rationale

- A collaborator invited to two projects should not have two separate "accounts" they
  are unaware of. Siloed identity creates a confusing experience as usage grows.
- Email is a stable, globally unique identifier that works naturally for magic link auth.
- A unified submissions view ("everything I've submitted, across all projects") is more
  useful than forcing the collaborator to re-enter each project via its share link on
  every visit.
- The `share_token` on the project link scopes the *submission form* to the right
  project; it does not need to scope the collaborator's identity.

## Schema implications

```
collaborators
  id
  email        (unique index)
  name
  created_at
  updated_at

submissions
  id
  collaborator_id   (FK → collaborators)
  project_id        (FK → projects)
  title
  body
  status            (pending | accepted | shipped)
  created_at
  updated_at
```

A collaborator has many submissions across many projects. There is no explicit
join table between collaborators and projects — participation is implicit via submissions.

## Alternatives considered

**Per-project collaborator records**
Simpler initial schema. Rejected because it produces duplicate identities for the same
person across projects, makes a cross-project view impossible, and creates a confusing
experience if the same person receives two separate magic link emails with different
"accounts."

## Consequences

- Email address is the collaborator's canonical identifier. If they change their email
  they would effectively become a new collaborator (acceptable for MVP; mitigatable
  with a name/email update flow later).
- No explicit collaborator ↔ project membership list in MVP — access is granted
  implicitly by the developer sharing the link. If a developer wants to revoke a
  collaborator's access, they rotate the project's `share_token`.
- A future "invite by email" feature (as opposed to shareable link) maps cleanly onto
  this model: find-or-create collaborator by email, send them the magic link directly.
