# ADR 0004 — Shareable Link for Collaborator Access (MVP)

## Status

Accepted

## Context

Developers need a way to grant collaborators access to their project's submission portal.
The two natural options are email invitations (developer enters collaborator emails,
app sends invites) or a shareable link (developer copies a URL and sends it themselves).

## Decision

For MVP, collaborator access is granted via a **shareable link**, not email invitations.

Each project has a unique `share_token`. The developer copies the link
`userstories.io/p/:share_token` and sends it to collaborators however they choose
(Slack, email, a wiki page, etc.). Anyone with the link can reach the submission portal
and authenticate via magic link.

## Rationale

- **Lower implementation complexity.** No invitation management UI, no invitation email
  flow, no pending/accepted invite states to track.
- **Lower friction for the developer.** Sharing a link in an existing conversation is
  faster than entering email addresses in a UI.
- **Flexible distribution.** The developer may want to share with a Slack channel, a
  team wiki, or a recurring email. A link works in all of these; per-email invitations
  require knowing addresses in advance.
- **Consistent with the MVP principle** of keeping the developer in control without
  building administrative overhead into the product before the core workflow is proven.

## Access revocation

If a developer wants to cut off access (e.g. a collaborator leaves the project), they
rotate the project's `share_token`. All existing links become invalid immediately. The
developer shares the new link with the remaining collaborators.

Existing submissions from the revoked collaborator are retained — they are associated
with the `Collaborator` record, not the token.

## Alternatives considered

**Email invitation model**
More controlled — developer explicitly manages who has access. Rejected for MVP because
it adds meaningful UI and backend complexity before the core submission/triage workflow
is validated. Can be added as a later tier feature.

**Public, unauthenticated submission form**
Requires no login at all. Rejected because persistent collaborator identity (see ADR 0002)
requires knowing who submitted what across visits.

## Consequences

- Any person who obtains the shareable link can reach the submission portal. This is
  intentional and acceptable — developers are sharing with trusted collaborators.
- The link should not be indexed by search engines. The submission portal page should
  include `<meta name="robots" content="noindex">`.
- A future "invite by email" feature is not blocked by this decision — it can coexist
  with shareable links as an additional access method.
