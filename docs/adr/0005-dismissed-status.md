# ADR 0005 — Dismissed Status as Terminal Triage State

## Status

Accepted

## Context

ADR 0003 defines the submission lifecycle as `pending → accepted → shipped`. During
implementation, a fourth status — `dismissed` — was introduced to handle submissions
the developer chooses not to act on. This was not captured in ADR 0003.

## Decision

`dismissed` is a valid terminal status alongside `shipped`. The full lifecycle is:

```
pending → accepted → shipped
    ↓
dismissed
```

- **dismissed** — developer has reviewed the submission and will not action it.
  The record is preserved in the database (not deleted). No notification is sent
  to the collaborator for MVP.

`dismissed` submissions are excluded from the triage inbox (`pending_review` scope)
and from the collaborator's status view.

## Rationale

- Inbox management requires a way to remove submissions that won't be actioned,
  without deleting historical data.
- Preserving dismissed submissions allows future features (e.g. collaborator
  notification, re-opening) without data loss.
- Silent dismissal is an acceptable MVP tradeoff — adding notification is deferred.

## Consequences

- `Submission::STATUSES` includes `"dismissed"`.
- `SubmissionPolicy#dismiss?` gates on `status == "pending"`.
- Dismissed submissions do not appear in the developer's inbox or the collaborator's
  status list.
