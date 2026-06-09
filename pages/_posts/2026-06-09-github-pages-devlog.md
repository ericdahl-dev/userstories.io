---
title: GitHub Pages dev log goes live
date: 2026-06-09
type: milestone
summary: Launched a public site to track features, roadmap, and ship notes as we build.
tags:
  - docs
  - github-pages
---

We're publishing progress in the open. This site lives alongside the main app repo and tracks what we're building, why, and when it ships.

## What's here

- **Home** — product overview and latest updates
- **Features** — current capabilities for developers and collaborators
- **Dev log** — dated entries for milestones, fixes, and notes
- **Roadmap** — shipped work and what's next

## Adding entries

Label noteworthy PRs with `devlog`, then run:

```bash
script/devlog.rb update
```

The script only pulls PRs merged since the last run. Manual notes:

```bash
script/devlog.rb new "Your title here" --type feature
```

Commit `pages/` and push to deploy via GitHub Actions.
