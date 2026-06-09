# User Stories

Stories are organized by actor. Each story includes acceptance criteria and a status.

**Statuses:** `draft` | `ready` | `in progress` | `done`

---

## Developer

### Authentication & Onboarding

**US-001** — Connect GitHub account
`done`
> As a developer, I want to sign in with my GitHub account, so that I can connect my
> repositories without managing a separate password.

Acceptance criteria:
- Developer can click "Sign in with GitHub" and complete OAuth flow
- GitHub OAuth token is stored encrypted on the user record
- Developer is redirected to their dashboard on first login
- Subsequent logins restore their session without re-authorizing

---

**US-002** — Create a project linked to a GitHub repo
`done`
> As a developer, I want to create a project linked to one of my GitHub repositories,
> so that accepted stories automatically become issues in the right place.

Acceptance criteria:
- Developer can select from their GitHub repos (fetched via API)
- Project is saved with a repo reference and a generated `share_token`
- Project appears on the developer's dashboard

---

**US-003** — Get a shareable link for a project
`done`
> As a developer, I want to copy a shareable link for my project, so that I can send
> it to collaborators without managing invitations.

Acceptance criteria:
- Each project has a unique URL (`/p/:share_token`)
- Developer can copy the link from the project settings page
- Link is functional immediately after project creation

---

**US-004** — Rotate a project's shareable link
`done`
> As a developer, I want to rotate my project's shareable link, so that I can revoke
> access for collaborators who should no longer submit stories.

Acceptance criteria:
- Developer can regenerate the `share_token` from project settings
- Old link returns 404 immediately after rotation
- Existing submissions are not affected by rotation
- Developer is warned that the old link will stop working before confirming

---

### Triage Inbox

**US-005** — View pending submissions
`done`
> As a developer, I want to see all pending submissions for my projects in a triage
> inbox, so that I can review and act on collaborator feedback.

Acceptance criteria:
- Inbox lists all `pending` submissions across the developer's projects
- Each item shows: project name, collaborator name, title, submitted date
- Submissions are ordered newest first by default
- Empty state is shown when no pending submissions exist

---

**US-006** — Review a submission
`done`
> As a developer, I want to read the full content of a submission, so that I can decide
> whether to accept it.

Acceptance criteria:
- Clicking a submission opens the full title and body
- Collaborator name and submission date are visible
- Accept and dismiss actions are available on the detail view

---

**US-007** — Accept a submission and create a GitHub issue
`done`
> As a developer, I want to accept a submission, so that a GitHub issue is automatically
> created in my repository and the story enters my tracked backlog.

Acceptance criteria:
- Clicking Accept creates a GitHub issue via the API using the developer's OAuth token
- Issue body includes the submission title, body, and a backlink to userstories.io
- Submission status transitions from `pending` to `accepted`
- `github_issue_number` and `github_issue_url` are stored on the submission
- Collaborator sees status update in their view

---

**US-008** — Dismiss a submission
`done`
> As a developer, I want to dismiss a submission I don't intend to act on, so that my
> inbox stays focused on actionable items.

Acceptance criteria:
- Dismissed submissions are removed from the pending inbox
- Submission status is updated (not deleted — preserved for record)
- For MVP: no notification is sent to the collaborator on dismissal

---

## Collaborator

### Access & Authentication

**US-009** — Access a project via shareable link
`done`
> As a collaborator, I want to access a project's submission portal via a link the
> developer shared with me, so that I don't need a GitHub account or a pre-existing
> userstories.io account.

Acceptance criteria:
- Visiting `/p/:share_token` resolves to the correct project's portal
- If the token is invalid or rotated, a clear error is shown (not a generic 404)
- The page does not require login to view — only to submit

---

**US-010** — Log in via magic link
`done`
> As a collaborator, I want to enter my email and receive a one-click login link, so
> that I can access my submissions without creating a password.

Acceptance criteria:
- Collaborator enters email on the portal page and submits
- A `Collaborator` record is found or created for that email
- A magic link email is sent within a few seconds
- Clicking the link in the email establishes a session and redirects to the project portal
- Token is single-use and expires after 15 minutes
- Visiting an expired or already-used token shows a clear message with option to request a new link

---

**US-011** — Stay logged in across visits
`done`
> As a collaborator, I want my session to persist across browser sessions, so that I
> don't have to re-authenticate every time I return.

Acceptance criteria:
- Collaborator session persists for a reasonable duration (e.g. 30 days)
- Returning to any project portal they have access to restores their session
- Explicit sign-out clears the session

---

### Submitting Stories

**US-012** — Submit a user story
`done`
> As a collaborator, I want to write and submit a user story, so that the developer
> can consider it for their backlog.

Acceptance criteria:
- Submission form has a title field and a body field
- Both fields are required
- Successful submission redirects to refinement chat with confirmation: *"Story received — let's refine it before review"*
- Submission is created immediately with `pending` status (visible in submissions list even if refinement is skipped)
- Submission appears in the developer's triage inbox after collaborator submits for review

---

**US-013** — View my previous submissions
`done`
> As a collaborator, I want to see all the stories I've submitted, so that I know what
> I've already suggested and can track their progress.

Acceptance criteria:
- Collaborator sees a list of all their submissions after logging in
- Each item shows: project name, title, status, and submitted date
- Submissions are grouped or filterable by project if they have more than one
- Status reflects the current state (`pending`, `accepted`, `shipped`)

---

**US-014** — Know when my story has shipped
`done`
> As a collaborator, I want to see when a story I submitted has been delivered, so that
> I know my feedback had an impact.

Acceptance criteria:
- Submission status shows `shipped` when the corresponding GitHub issue is closed (synced automatically) or when the developer marks it shipped manually
- Shipped stories are visually distinct in the submissions list
- GitHub issue summary is shown for accepted and shipped submissions

---

## Platform

**US-015** — Branded landing page
`done`
> As a visitor, I want to understand what userstories.io does from the home page, so
> that I can decide whether it's right for my team.

Acceptance criteria:
- Root path (`/`) renders a branded landing page (not a Rails default)
- Page includes headline, value proposition, and a clear CTA (sign in / get started)
- Page is mobile-friendly

---

## Post-MVP (not in original MVP scope)

These features shipped after the initial MVP but are not tracked as MVP user stories:

- **AI-assisted story refinement chat** — optional refinement step after initial submission (see ADR 0006)
- **GitHub issue status sync** — automatic `shipped` transition when linked issues close
- **Dark mode** — theme toggle across developer and collaborator surfaces
