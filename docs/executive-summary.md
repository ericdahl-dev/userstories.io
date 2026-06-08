# userstories.io — Executive Summary

## What It Is

userstories.io is a lightweight collaboration tool that lets non-technical stakeholders
submit user stories directly into a developer's GitHub workflow — without needing a
GitHub account.

## The Problem

Developers want feedback and feature requests from the people who use their software:
product owners, clients, managers, internal teams. But the tools developers live in
(GitHub Issues, Linear, Jira) are unfamiliar and intimidating to non-technical
collaborators. The result is feedback that arrives over Slack, email, and sticky notes —
unstructured, untracked, and easy to lose.

At the same time, developers don't want their issue trackers flooded with unreviewed
noise. They need to stay in control of what enters their backlog.

## The Solution

userstories.io sits between the two sides:

- **Collaborators** get a simple, familiar submission form — no GitHub account required.
  They arrive via a shareable link the developer sends them, log in with a magic link
  to their email, and submit stories in plain language. They can see the status of
  everything they've submitted and know when their ideas ship.

- **Developers** get a triage inbox. Submissions arrive as pending items to review.
  They accept what's actionable (which creates the GitHub issue automatically) and
  ignore what isn't. Their issue tracker stays clean. Their collaborators feel heard.

## How It Works

1. Developer connects their GitHub repo and copies a shareable link.
2. Developer sends the link to whoever they want feedback from.
3. Collaborator clicks the link, enters their email, and gets a one-click login.
4. Collaborator writes and submits a user story.
5. Developer sees the submission in their triage inbox, reviews it, and accepts it.
6. On acceptance, a GitHub issue is created automatically.
7. When the issue ships, the collaborator sees their story marked as delivered.

## Who It's For

**Primary user (developer):** An independent developer or small engineering team who
works in GitHub and has non-technical stakeholders — clients, product owners, or
internal business users — who need a way to contribute ideas without GitHub access.

**Secondary user (collaborator):** A non-technical person — product manager, client,
operations team member — who has ideas and feedback but no interest in learning a
developer tool to share them.

## MVP Scope

- Developer account with GitHub OAuth
- Project creation linked to a GitHub repo
- Shareable link for collaborator access (no email invitation management)
- Magic link (passwordless) login for collaborators
- Submission form with title and body
- Developer triage inbox (pending → accepted → shipped)
- Automatic GitHub issue creation on acceptance
- Collaborator submissions view with status tracking

## What It Is Not (Yet)

- A project management tool
- A replacement for GitHub Issues, Linear, or Jira
- A two-way commenting or discussion thread
- An analytics or reporting product

## The Wedge

The initial value is narrow and deliberate: one frictionless path from stakeholder
feedback to GitHub issue. Once that workflow is proven, the surface expands naturally —
story templates, status notifications, team-level views, multiple repos per project,
and a richer collaborator experience.
