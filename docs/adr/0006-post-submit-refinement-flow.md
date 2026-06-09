# ADR 0006 — Post-Submit Refinement-First Flow

## Status

Accepted

## Context

MVP PRD story 34 specified a confirmation message after a collaborator submits a
user story. Since the refinement chat feature (#73), `POST /submissions` redirects
directly to the refine page with no visible confirmation. Confirmation only appeared
after **Submit for review** (`RefinementsController#finalize`).

Collaborators need to know their story was saved — not lost — even when refinement
is the immediate next step.

## Decision

Keep the **refinement-first flow**: after a successful submission, redirect to the
refinement chat page with a flash notice:

> Story received — let's refine it before review.

The submission is created with `pending` status immediately. If refinement is skipped
or fails, the submission remains visible in the collaborator's submissions list.

Final confirmation after refinement ("Your story has been submitted for review!")
is unchanged.

## Rationale

- Refinement improves story quality before developer triage — worth keeping as the
  default path.
- A flash notice on the refine page satisfies the PRD requirement that collaborators
  know their submission was saved.
- Redirecting to the submissions list (PRD-original flow) would add an extra click
  before refinement and weaken the refinement funnel.

## Alternatives considered

**Redirect to submissions list with confirmation**
Matches original PRD wording but interrupts the refinement workflow.

**Document deviation only**
Insufficient — collaborators still wouldn't see confirmation on submit.

## Consequences

- `Portal::SubmissionsController#create` sets a `notice` flash on redirect to refine.
- `docs/user-stories.md` US-012 acceptance criteria reflect refinement-first flow.
- Request specs cover post-create redirect and user-visible confirmation.
