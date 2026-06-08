# Core Data Model

## Entities

### User (developer)
The account owner. Authenticates via Devise. Connects their GitHub repositories
and manages projects on the platform.

```
users
  id
  email
  encrypted_password
  github_token         (encrypted; OAuth token for GitHub API calls)
  created_at
  updated_at
```

### Project
A developer's userstories.io project, linked to one GitHub repository.
Has a shareable link token for collaborator access.

```
projects
  id
  user_id              (FK → users; the developer who owns this)
  name
  github_repo          (e.g. "ericdahl/my-app")
  share_token          (secure random; rotatable; drives /p/:share_token URL)
  created_at
  updated_at
```

### Collaborator
A non-developer user who submits stories. Global identity keyed on email —
one record per person regardless of how many projects they contribute to.
Authenticates via magic link only; no password.

```
collaborators
  id
  email                (unique)
  name
  created_at
  updated_at
```

### Submission
A user story submitted by a collaborator against a project.
Owns the triage lifecycle state and the GitHub issue reference once accepted.

```
submissions
  id
  collaborator_id      (FK → collaborators)
  project_id           (FK → projects)
  title
  body
  status               (pending | accepted | shipped)
  github_issue_number  (set when accepted; nil until then)
  github_issue_url     (set when accepted)
  created_at
  updated_at
```

### MagicToken
A single-use, time-limited token for collaborator authentication.
Generated when a collaborator requests a login link; consumed on first use.

```
magic_tokens
  id
  collaborator_id      (FK → collaborators)
  token                (secure random hex; indexed)
  expires_at
  used_at              (nil until consumed)
  created_at
```

---

## Relationships

```
User
  has_many :projects

Project
  belongs_to :user
  has_many :submissions

Collaborator
  has_many :submissions
  has_many :projects, through: :submissions  (implicit; no join table needed for MVP)
  has_many :magic_tokens

Submission
  belongs_to :collaborator
  belongs_to :project

MagicToken
  belongs_to :collaborator
```

---

## Status lifecycle

```
pending   →   accepted   →   shipped
                  ↓
         GitHub issue created
         (github_issue_number set)
```

- **pending**: submitted, awaiting developer triage
- **accepted**: developer approved; GitHub issue created via API
- **shipped**: GitHub issue closed (manual for MVP; webhook-driven later)

---

## Access model

- Developers access their projects via standard session auth (Devise).
- Collaborators access via magic link session (`collaborator_id` stored in session,
  separate from the developer `user_id` session key).
- The `/p/:share_token` route is unauthenticated — it renders the submission form
  and the magic link email prompt. The `share_token` is resolved to a `Project`
  before the collaborator authenticates.
- Collaborator sessions are scoped: a collaborator can only see their own submissions.
  Pundit policies enforce this.
