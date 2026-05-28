# ices0 — Implementation Spec (HOW)

## Source of truth

This file is READ-ONLY. Project-specific values live in `IDEA.md`. Placeholders like `{project_name}` resolve from `IDEA.md § Project variables` at runtime.

---

## Directory layout

```
{project_name}/
├── docker/
│   ├── Dockerfile.build      # Alpine build environment image
│   ├── docker-compose.yml    # Reference Compose stack (icecast server + ices0 source)
│   └── rootfs/               # Files copied into runtime image (mirrors Linux FHS)
│       └── usr/local/bin/
│           ├── entrypoint.sh     # env var → XML config → exec ices0
│           └── rescan-playlist   # rescan media folder + SIGHUP ices0
├── .gitea/
│   └── workflows/
│       ├── build-env-image.yml    # Gitea-native mirror of GitHub build-env-image
│       ├── build-linux-binaries.yml  # Gitea-native mirror of GitHub build-linux-binaries
│       └── security.yml           # Gitea-native mirror of GitHub security
├── .forgejo/
│   └── workflows/
│       ├── build-env-image.yml    # Forgejo-native (forgejo.* vars)
│       ├── build-linux-binaries.yml  # Forgejo-native
│       └── security.yml           # Forgejo-native
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── pull_request_template.md
│   ├── SECURITY.md
│   └── workflows/
│       ├── build-env-image.yml    # Builds ghcr.io/{project_org}/{project_name}:build
│       ├── build-linux-binaries.yml  # Builds binaries + release + runtime image
│       └── security.yml           # secret-scan + workflow-policy + image-scan
├── .dockerignore
├── Dockerfile                # Runtime image (Alpine + tini + entrypoint.sh + static binary)
├── AI.md                     # This file — implementation spec
├── CLAUDE.md                 # Loader
├── IDEA.md                   # Project plan (WHAT)
├── Makefile                  # Local build convenience targets
├── renovate.json             # Renovate dependency update config
├── release.txt               # Version source of truth (semver, no v prefix)
└── SPEC.md                   # Project-specific rule overrides
```

---

## Versioning

- `release.txt` — single line, semver, no `v` prefix (e.g. `0.4.11`). Updated when upstream releases a new version.
- The `build-linux-binaries.yml` workflow reads the version from upstream `configure.ac` at build time using:
  ```sh
  MAJOR=$(sed -n 's/.*m4_define(ICES_MAJOR, \([0-9]*\)).*/\1/p' configure.ac)
  MINOR=$(sed -n 's/.*m4_define(ICES_MINOR, \([0-9]*\)).*/\1/p' configure.ac)
  MICRO=$(sed -n 's/.*m4_define(ICES_MICRO, \([0-9]*\)).*/\1/p' configure.ac)
  VERSION="${MAJOR}.${MINOR}.${MICRO}"
  ```
- GitHub release tag: `v{VERSION}`
- Container tags: `latest`, `{VERSION}`, `{YYMM}` (YYMM = `date -u +'%y%m'`)

---

## Build environment image (`build-env-image.yml`)

- **Trigger**: push to main/master touching `docker/Dockerfile.build` or the workflow file itself; quarterly schedule (`0 0 1 */3 *`); `workflow_dispatch`
- **Output**: `ghcr.io/{project_org}/{project_name}:build` (multi-platform, pushed to GHCR)
- **Dockerfile**: `docker/Dockerfile.build`
- **Permissions**: `packages: write` on the build job; `contents: read` at workflow level
- **Concurrency**: `group: ${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: true`

### `docker/Dockerfile.build` structure

1. `FROM alpine:latest` — rolling tag intentional (build env, not production)
2. Install Alpine build tools + static library packages (libogg, libvorbis, libxml2, faad2, flac, openssl, etc.)
3. Install glibc compat APK (for the Bootlin toolchain loader)
4. Download and install Bootlin `aarch64--musl--stable-{date}` cross-toolchain to `/opt/toolchains/aarch64-musl`
5. Source-build LAME, mp4v2, libshout for the amd64 host target (static only)
6. Embed `build-ices0` script via `COPY <<'EOF'`

### `build-ices0` script (embedded in Dockerfile.build)

- Called as `build-ices0 amd64` or `build-ices0 arm64`
- For **amd64**: uses Alpine's own gcc + pre-built static deps in `/usr`
- For **arm64**: calls `build_arm64_deps()` which cross-builds all deps from source into `/opt/ices0-static/arm64` using the Bootlin toolchain
- Clones upstream ices0 from `https://github.com/Moonbase59/ices0.git`
- Runs `autoreconf -fi && ./configure && make`; falls back to manual link if libtool reorders C++ runtime
- Strips the binary; outputs to `/output/ices0-linux-{ARCH}` and `/output/VERSION`

---

## Binary build workflow (`build-linux-binaries.yml`)

- **Trigger**: `workflow_run` on successful `Build Environment Image` completion on main/master; `workflow_dispatch`
- **Concurrency**: `group: ${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: false` (release workflow — never cancel)
- **Workflow-level permissions**: `contents: read`

### `build-linux` job

- `runs-on: ubuntu-latest`
- `container: image: ghcr.io/{project_org}/{project_name}:build`
- Matrix: `arch: [amd64, arm64]`
- Steps:
  1. `build-ices0 ${{ matrix.arch }}` (script is in the container image)
  2. Upload artifact `ices0-linux-{arch}` from `/output/`, `retention-days: 7`

### `build-freebsd` job

- `runs-on: ubuntu-latest` (both matrix entries)
- Matrix: `[{arch: amd64, vm-arch: amd64}, {arch: arm64, vm-arch: arm64}]`
- Uses `vmactions/freebsd-vm` with `usesh: true`, `arch: ${{ matrix.vm-arch }}`, `disable-cache: true`
- `prepare`: `pkg install -y git autoconf automake libtool pkgconf gmake libshout libogg libvorbis faad2 flac lame libxml2 openssl mp4v2`
- `run`: clone ices0, extract version, configure with system libs, `gmake`, strip, copy to `output/ices0-freebsd-{arch}`
- Upload artifact `ices0-freebsd-{arch}` from `output/`, `retention-days: 7`

### `release` job

- `needs: [build-linux, build-freebsd]`
- `runs-on: ubuntu-latest`
- `permissions: contents: write, packages: write`
- Steps:
  1. `actions/checkout`
  2. `actions/download-artifact` with `merge-multiple: true` into `artifacts/`
  3. Extract version from `artifacts/VERSION`
  4. Compute YYMM tag
  5. `mkdir release && cp artifacts/ices0-* release/ && chmod +x release/* && sha256sum * > checksums.txt`
  6. `gh release delete v{version} --yes --cleanup-tag || true`; `gh release create v{version} ...`
  7. `docker/setup-buildx-action`, `docker/login-action` to GHCR
  8. Copy Linux binaries: `cp release/ices0-linux-* .`
  9. `docker/build-push-action` with `platforms: linux/amd64,linux/arm64`, push tags `latest`, `{version}`, `{yymm}`

---

## Runtime Dockerfile

- **Base**: `FROM alpine:latest` (not scratch — entrypoint.sh requires a shell)
- **Init**: `tini` installed via `apk add --no-cache tini python3 perl` — python3 and perl are present for `STREAM_PLAYLIST_TYPE=script` playlists; the ices0 binary itself has Python and Perl statically embedded (built with `--with-python --with-perl`)
- **Binary**: `COPY ices0-linux-${TARGETARCH} /usr/local/bin/ices0`
- **Rootfs**: `COPY docker/rootfs/ /` — copies `entrypoint.sh` to `/usr/local/bin/entrypoint.sh`
- **Startup chain**: `ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]`

---

## `docker/rootfs/usr/local/bin/entrypoint.sh`

The entrypoint generates `/config/ices0/ices.conf` from `STREAM_*` env vars, optionally scans `STREAM_MEDIA_FOLDER` for audio files to build a playlist, then execs ices0.

### Config generation

- `STREAM_PRIVATE` is inverted to `<Public>`: `STREAM_PRIVATE=0` → `<Public>1</Public>`
- When `STREAM_PLAYLIST_TYPE=builtin`: `find $STREAM_MEDIA_FOLDER` for `*.mp3`, `*.ogg`, `*.oga`, `*.flac`, `*.m4a`, `*.aac`, `*.mp4` piped through `sort -u` into `STREAM_PLAYLIST`; ices0 detects format by magic bytes, not extension
- Config written to `STREAM_CONFIG` (default `/config/ices0/ices.conf`) — ephemeral; mount `/config/ices0` as a volume only if you want to inspect it
- Exec: `exec /usr/local/bin/ices0 -c "${STREAM_CONFIG}"` — ices0 loops the playlist indefinitely (rewinds at EOF); `restart: always` in Compose is for crash recovery only
- `rescan-playlist` script: reruns the find/sort-u, rewrites `STREAM_PLAYLIST`, sends `SIGHUP` to ices0 to reload the playlist at next track change without restarting the container
- `/data/ices0` is a named Docker volume — `playlist.txt` and `ices.cue` persist across restarts and are inspectable

### Path layout

| Path | Purpose | Persist |
|---|---|---|
| `/config/ices0/ices.conf` | Generated XML config | Optional |
| `/data/ices0/playlist.txt` | Generated playlist | Yes (named volume) |
| `/data/ices0/ices.cue` | Now-playing cue file (written by ices0) | Yes (named volume) |

### Env vars

| Variable | Default | XML element | Notes |
|---|---|---|---|
| `STREAM_CONFIG` | `/config/ices0/ices.conf` | — | Generated config path |
| `STREAM_PLAYLIST` | `/data/ices0/playlist.txt` | `<File>` | |
| `STREAM_CUE_FILE` | `/data/ices0/ices.cue` | `<CueFile>` | Written by ices0; records now-playing info |
| `STREAM_RANDOMIZE` | `0` | `<Randomize>` | |
| `STREAM_CROSSFADE` | `2` | `<Crossfade>` | seconds |
| `STREAM_MIN_CROSSFADE` | `0` | `<MinCrossfade>` | min track length before crossfade kicks in |
| `STREAM_CROSS_MIX` | `0` | `<CrossMix>` | crossfade at 100% volume |
| `STREAM_PLAYLIST_TYPE` | `builtin` | `<Type>` | `builtin`, `python`, `perl`, `script` |
| `STREAM_INTERPRETER_MODULE` | `ices` | `<Module>` | module name for python/perl handlers |

---

## Action SHA pinning

All third-party GitHub Actions **must** be pinned to a full commit SHA. Use the verified node24 SHAs from `~/.claude/memory/cicd_conventions.md`. Update SHAs only when Renovate opens a PR.

Current pinned SHAs:
- `actions/checkout` → `de0fac2e4500dabe0009e67214ff5f5447ce83dd` # v6.0.2
- `actions/upload-artifact` → `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` # v7.0.1
- `actions/download-artifact` → `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` # v8.0.1
- `docker/setup-buildx-action` → `4d04d5d9486b7bd6fa91e7baf45bbb4f8b9deedd` # v4.0.0
- `docker/login-action` → `4907a6ddec9925e35a0a9e82d7399ccc52663121` # v4.1.0
- `docker/build-push-action` → `bcafcacb16a39f128d818304e6c9c0c18556b85f` # v7.1.0
- `vmactions/freebsd-vm` → `d1e65811565151536c0c894fff74f06351ed26e6` # v1.4.5

---

## Security workflow (`security.yml`)

- **Trigger**: push to main/master, pull_request, weekly schedule, `workflow_dispatch`
- Always-required jobs (every run, no conditions):
  - `secret-scan` — truffleHog (`trufflesecurity/trufflehog@37b77001d0174ebec2fcca2bd83ff83a6d45a3ab`, v3.95.3); `fetch-depth: 0`; `--only-verified`
  - `workflow-policy` — inline shell verifying all `uses:` lines are pinned to 40-char SHAs; blocks `pull_request_target`
- Conditional jobs:
  - `image-scan` — Trivy against the published `ghcr.io/{project_org}/{project_name}:latest`; `--ignore-unfixed --severity CRITICAL,HIGH`
- Critical/high CVEs are hard failures

---

## Renovate (`renovate.json`)

Covers `github-actions` ecosystem (SHA pinning) for all five CI/CD providers. No language package managers in use.

---

## Docker Compose conventions

Follows `~/.claude/memory/dockerfile_conventions.md`:
- Compose file in `docker/docker-compose.yml`
- Hardcoded sane defaults; works with zero `.env`
- Users override by editing the file
- All log drivers use `json-file` with `max-size: 5m`, `max-file: 1`
- Named volumes for persistent data (`/data/ices0`); config is ephemeral (`/config/ices0`)
