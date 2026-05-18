# TODO.AI.md — ices0 compliance tasks

## 1. Fix AI.md directory layout — add .gitea/workflows/
Read: AI.md § Directory layout

Add `.gitea/workflows/` subtree to the directory layout. The three
files already exist on disk but are absent from the layout.

## 2. Add .forgejo/workflows/ (3 files)
Read: cicd_conventions.md § Workflow File Locations, Forgejo conventions

Forgejo uses `.forgejo/workflows/` (not `.gitea/`). Required files:
- `build-env-image.yml` — adapted from `.gitea/workflows/build-env-image.yml`
- `build-linux-binaries.yml` — adapted from `.gitea/workflows/build-linux-binaries.yml`
- `security.yml` — adapted from `.gitea/workflows/security.yml`

Use `forgejo.*` context variables (not `gitea.*`).

## 3. Add .gitlab-ci.yml
Read: cicd_conventions.md § GitLab CI Structure

Security stage (truffleHog + workflow-policy) and build stage
equivalent to the GitHub/Gitea workflows.

## 4. Add Jenkinsfile
Read: cicd_conventions.md § Jenkinsfile Structure

Declarative pipeline with Build, Security (parallel: secret-scan),
and Release (tag-triggered) stages.
