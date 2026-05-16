## Project description

Automated CI/CD system that builds and publishes static, multi-platform [ices0](https://github.com/Moonbase59/ices0) binaries (Moonbase59 fork). Produces fully static Linux (amd64/arm64) and native FreeBSD (amd64/arm64) binaries, a multi-arch Docker container image with environment-variable-driven configuration, and GitHub Releases with checksums. Users can drop in a single binary or use the container image with `STREAM_*` env vars in place of `zerg13/ices`.

## Project variables

project_name: ices0
project_org: binmgr
internal_name: ices0
internal_org: binmgr
upstream_source: https://github.com/Moonbase59/ices0
registry: ghcr.io/binmgr/ices0
build_image: ghcr.io/binmgr/ices0:build

## Business logic

### Platforms

- **Linux amd64/arm64** — fully static musl binaries built inside `ghcr.io/binmgr/ices0:build` (Alpine + Bootlin aarch64-musl toolchain)
- **FreeBSD amd64/arm64** — native builds in QEMU VMs via `vmactions/freebsd-vm`; dynamically linked against pkg-installed system libs
- macOS: not built
- Windows: not built

### Build pipeline

1. `build-env-image.yml` — builds and pushes `ghcr.io/binmgr/ices0:build` when `docker/Dockerfile.build` or its workflow file changes, on a quarterly schedule, or manually
2. `build-linux-binaries.yml` — triggered by successful `Build Environment Image` workflow run on main/master, or manually; builds Linux and FreeBSD binaries; creates GitHub release; pushes multi-arch container image

### Versioning

Version is extracted from upstream `configure.ac` at build time using `m4_define(ICES_MAJOR/MINOR/MICRO, N)` pattern. GitHub release tag: `v{version}`. Container tags: `latest`, `{version}`, `{yymm}` (YYMM of release date).

### Container image

The runtime image is multi-arch (`linux/amd64`, `linux/arm64`) based on Alpine with tini as the init process. `docker/entrypoint.sh` generates an ices0 XML config from `STREAM_*` environment variables before exec-ing ices0, allowing the image to be used as a drop-in for `zerg13/ices`.

#### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `STREAM_HOST` | `localhost` | Icecast server hostname |
| `STREAM_PORT` | `8000` | Icecast server port |
| `STREAM_PASSWORD` | `hackme` | Icecast source password |
| `STREAM_PROTOCOL` | `http` | Connection protocol (`http`/`https`) |
| `STREAM_MOUNTPOINT` | `/stream` | Mount point path |
| `STREAM_NAME` | `ices0 Stream` | Stream display name |
| `STREAM_GENRE` | `Various` | Stream genre |
| `STREAM_DESCRIPTION` | `ices0 audio stream` | Stream description |
| `STREAM_URL` | _(empty)_ | Stream URL |
| `STREAM_PRIVATE` | `0` | `1` = private (not listed in directory) |
| `STREAM_BITRATE` | `320` | Output MP3 bitrate (kbps) |
| `STREAM_REENCODED` | `0` | `1` = re-encode to MP3 |
| `STREAM_REENCODED_CHANNELS` | `2` | Number of output channels |
| `STREAM_REENCODED_SAMPLERATE` | `44100` | Output sample rate (Hz) |
| `STREAM_RANDOMIZE` | `0` | `1` = randomize playlist order |
| `STREAM_CROSSFADE` | `2` | Crossfade duration in seconds (`0` = off) |
| `STREAM_VERBOSE` | `0` | `1` = verbose logging |
| `STREAM_BACKGROUND` | `0` | `1` = daemon mode (avoid in containers) |
| `STREAM_PLAYLIST_TYPE` | `builtin` | Playlist module type |
| `STREAM_INTERPRETER_MODULE` | `ices` | Playlist interpreter module name |
| `STREAM_MEDIA_FOLDER` | `/media` | Directory scanned for audio files |
| `STREAM_CONFIG` | `/ices/ices.conf` | Path for generated XML config |
| `STREAM_PLAYLIST` | `/ices/playlist.txt` | Path for generated playlist |

When `STREAM_PLAYLIST_TYPE=builtin`, `entrypoint.sh` auto-scans `STREAM_MEDIA_FOLDER` for `*.mp3`, `*.ogg`, `*.flac`, `*.m4a`, `*.aac` and writes `STREAM_PLAYLIST`.

### Release integrity

Every GitHub release includes `checksums.txt` (SHA-256) for all release artifacts.

### CI/CD rules

- All third-party GitHub Actions pinned to full commit SHAs
- Workflow-level `permissions: contents: read` baseline; write grants only on the release job
- Concurrency groups on every workflow to cancel stale runs (except release job: `cancel-in-progress: false`)
- Artifact `retention-days: 7` for build artifacts
- `dependabot.yml` covering `github-actions` ecosystem
- `security.yml` running Trivy container scan on the published image

### Security

No auth, no secrets, no network services. Only secret used: `GITHUB_TOKEN` (auto-provided by GitHub). No external credential storage required.
