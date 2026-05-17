# ices0 — Project-Specific Rule Overrides

> SPEC.md wins over AI.md which wins over global CLAUDE.md.
> Add entries here only when this project's rules must actively contradict the template or global conventions.

## Dockerfile location exception

Per `dockerfile_conventions.md`, Dockerfiles must live at `docker/Dockerfile`. This project places the runtime
`Dockerfile` at the repo root because the `build-linux-binaries.yml` release job copies Linux binaries
(`ices0-linux-amd64`, `ices0-linux-arm64`) to the repo root before running `docker buildx build`, and the
build context is the repo root (binaries are referenced as `COPY ices0-linux-${TARGETARCH} /usr/local/bin/ices0`).

Moving the Dockerfile to `docker/Dockerfile` would require either changing how binaries are staged or passing
a different build context. This exception is intentional — do not "fix" it by moving the Dockerfile.
