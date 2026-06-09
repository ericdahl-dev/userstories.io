# userstories.io — GitHub Pages site

Public dev log, features, and roadmap for the project.

**Live URL (after enabling Pages):** `https://ericdahl-dev.github.io/userstories.io/`

## Update the dev log

From the repo root:

```bash
# Pull in merged PRs labeled devlog since the last run
script/devlog.rb update

# Preview what would sync
script/devlog.rb update --dry-run

# One-off PR or manual note
script/devlog.rb update --pr 93 --force
script/devlog.rb new "Quarterly recap" --type milestone -e

# Check last run
script/devlog.rb status
```

Label any PR you want published with `devlog` before merge. Optional type labels: `feature`, `fix`, `milestone`, `note`.

Auth uses `GITHUB_TOKEN` or `gh auth login`.

Then commit `pages/` and push to `main` — `.github/workflows/pages.yml` deploys the site.

## Local preview

```bash
cd pages
bundle install
bundle exec jekyll serve
```

Open http://127.0.0.1:4000/userstories.io/

## One-time setup

Repo **Settings → Pages → Build and deployment → Source:** GitHub Actions
