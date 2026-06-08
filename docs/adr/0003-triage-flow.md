# ADR 0003 — Developer Triage Step Before GitHub Issue Creation

## Status

Accepted

## Context

The core workflow of userstories.io is: collaborator submits a user story →
story becomes a GitHub issue on the developer's repository. However, creating a
GitHub issue directly on submission raises several problems:

- Collaborators may submit duplicates, vague stories, or out-of-scope requests.
- The developer's GitHub issue tracker would fill with unreviewed noise.
- Developers want to remain the gatekeeper for what enters their tracked backlog.
- Some submissions may need clarification before they're actionable.

## Decision

A **triage step** sits between story submission and GitHub issue creation. The developer
must explicitly accept a submission before it becomes a GitHub issue.

Submission lifecycle:

```
pending → accepted → shipped
               ↓
          (GitHub issue created)
```

- **pending** — submitted by collaborator, awaiting developer review
- **accepted** — developer has reviewed and accepted; GitHub issue has been created
- **shipped** — the GitHub issue has been closed/merged; story is delivered

Collaborators see their submission's current status in their submissions view, giving
them visibility without requiring GitHub access.

## Rationale

- Keeps the developer's GitHub issue tracker clean — only accepted, actionable stories
  appear there.
- Gives the developer control over scope and timing. They can batch-process submissions
  rather than being flooded with issues in real time.
- The triage inbox is a natural developer workflow surface — a queue to process, not
  just a log.
- Status visibility for collaborators ("your story was accepted" / "is being worked on"
  / "has shipped") closes the feedback loop without exposing GitHub internals.

## GitHub issue creation

On acceptance, the app creates a GitHub issue via the GitHub API using the developer's
connected OAuth token. The issue body includes the original story text and a backlink
to the submission on userstories.io.

## Alternatives considered

**Auto-create GitHub issue on submission**
Simpler, no triage UI needed. Rejected because it removes developer control and pollutes
the issue tracker with unreviewed submissions.

**No GitHub integration (manual copy-paste)**
Keeps the app simple but eliminates the core value proposition — reducing friction in
the developer's workflow.

## Consequences

- The developer needs a triage inbox UI — a queue of pending submissions per project
  with accept/dismiss actions.
- Dismissing a submission (not accepting it) should optionally notify the collaborator.
  For MVP, dismissed submissions are simply not acted on (no notification).
- The `shipped` status depends on GitHub webhook events (issue closed). This requires
  the developer to authorize the userstories.io GitHub App on their repository.
  Webhook setup is out of scope for MVP; `shipped` status can be set manually initially.
