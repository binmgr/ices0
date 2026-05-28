# ices0 - Multi-Platform Static Binary Builds

Automated builds of static [ices0](https://github.com/Moonbase59/ices0) binaries for **Linux and FreeBSD** (amd64/arm64), plus a multi-arch Docker image with environment-variable-driven configuration. ices0 is the original ices (version 0.x) that streams MP3 audio to an Icecast server — supporting real-time re-encoding, transcoding from Vorbis/FLAC/AAC, crossfading, and XML-based playlist management.

---

## 📦 Install

Download the latest release from [GitHub Releases](https://github.com/binmgr/ices0/releases/latest).

### Linux

| Arch | Binary |
|------|--------|
| amd64 | `ices0-linux-amd64` |
| arm64 | `ices0-linux-arm64` |

```bash
# Detect arch automatically
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -LSsf "https://github.com/binmgr/ices0/releases/latest/download/ices0-linux-${ARCH}" \
  -o /usr/local/bin/ices0 && chmod +x /usr/local/bin/ices0
```

Fully static — zero dynamic dependencies. Works on any Linux distribution (glibc or musl).

### FreeBSD

| Arch | Binary |
|------|--------|
| amd64 | `ices0-freebsd-amd64` |
| arm64 | `ices0-freebsd-arm64` |

```bash
# Detect arch automatically
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
fetch -o /usr/local/bin/ices0 \
  "https://github.com/binmgr/ices0/releases/latest/download/ices0-freebsd-${ARCH}"
chmod +x /usr/local/bin/ices0
```

Dynamically linked against FreeBSD system libraries. Python/Perl scripting requires `pkg install python3 perl5`.

### Verify Integrity (Optional)

```bash
curl -LSsf https://github.com/binmgr/ices0/releases/latest/download/checksums.txt \
  | sha256sum -c --ignore-missing
```

---

## 🐳 Docker

Drop-in replacement for `zerg13/ices` — configure entirely via environment variables:

```bash
docker run --rm -it \
  -e STREAM_HOST=icecast-server \
  -e STREAM_PASSWORD=changeme \
  -e STREAM_MOUNTPOINT=/music \
  -e STREAM_NAME="My Music" \
  -v /path/to/music:/media:ro \
  -v /path/to/data:/data/ices0 \
  ghcr.io/binmgr/ices0:latest
```

Container images are published to `ghcr.io/binmgr/ices0`:

| Tag | Description |
|-----|-------------|
| `latest` | Newest released version |
| `{version}` | Numbered release (e.g. `1.3.2`) |
| `{yymm}` | Release month (e.g. `2605`) |

See [docker/docker-compose.yml](docker/docker-compose.yml) for a full Compose stack including an Icecast server.

### Docker Environment Variables

Configure the container entirely via `STREAM_*` environment variables — no config file needed.

| Variable | Default | Description |
|----------|---------|-------------|
| `STREAM_HOST` | `localhost` | Icecast server hostname |
| `STREAM_PORT` | `8000` | Icecast server port |
| `STREAM_PASSWORD` | `hackme` | Source password |
| `STREAM_PROTOCOL` | `http` | `http` or `https` |
| `STREAM_MOUNTPOINT` | `/stream` | Mount point path |
| `STREAM_NAME` | `ices0 Stream` | Stream display name |
| `STREAM_GENRE` | `Various` | Stream genre |
| `STREAM_DESCRIPTION` | `ices0 audio stream` | Stream description |
| `STREAM_URL` | _(empty)_ | Stream URL |
| `STREAM_PRIVATE` | `0` | `1` = unlisted (not in directory) |
| `STREAM_BITRATE` | `320` | Output bitrate (kbps) |
| `STREAM_REENCODED` | `0` | `1` = re-encode to MP3 |
| `STREAM_REENCODED_CHANNELS` | `2` | Output channels |
| `STREAM_REENCODED_SAMPLERATE` | `44100` | Output sample rate (Hz) |
| `STREAM_RANDOMIZE` | `0` | `1` = shuffle playlist |
| `STREAM_CROSSFADE` | `2` | Crossfade seconds (`0` = off) |
| `STREAM_MIN_CROSSFADE` | `0` | Minimum track length (s) before crossfade activates |
| `STREAM_CROSS_MIX` | `0` | `1` = crossfade at 100% volume |
| `STREAM_VERBOSE` | `0` | `1` = verbose logging |
| `STREAM_BACKGROUND` | `0` | `1` = daemon mode (avoid in containers) |
| `STREAM_PLAYLIST_TYPE` | `builtin` | `builtin`, `python`, `perl`, or `script` |
| `STREAM_INTERPRETER_MODULE` | `ices` | Interpreter module name (python/perl/script types) |
| `STREAM_MEDIA_FOLDER` | `/media` | Mount your audio files here |
| `STREAM_CONFIG` | `/config/ices0/ices.conf` | Generated config path |
| `STREAM_PLAYLIST` | `/data/ices0/playlist.txt` | Generated playlist path |
| `STREAM_CUE_FILE` | `/data/ices0/ices.cue` | Now-playing cue file (written by ices0) |

When `STREAM_PLAYLIST_TYPE=builtin`, the entrypoint automatically scans `STREAM_MEDIA_FOLDER` for `*.mp3`, `*.ogg`, `*.flac`, `*.m4a`, `*.aac` files and generates the playlist.

---

## ✨ Features

All optional features are compiled in:

- ✅ XML configuration support (libxml2)
- ✅ MP3 re-encoding (LAME)
- ✅ Vorbis transcoding (libvorbis)
- ✅ FLAC transcoding (libFLAC)
- ✅ MP4/AAC transcoding (FAAD2)
- ✅ TLS/SSL support (OpenSSL)
- ✅ Proper UTF-8 metadata handling (built-in)
- ✅ Python scripting (Docker image — `python3` included; set `STREAM_PLAYLIST_TYPE=python`)
- ✅ Perl scripting (Docker image — `perl` included; set `STREAM_PLAYLIST_TYPE=perl`)
- ❌ Python/Perl scripting (static Linux binary — disabled to keep the binary self-contained)

---

## ⚙️ Configuration

When using the Docker image, the entrypoint generates the config automatically from `STREAM_*` environment variables — no config file needed.

For the bare binary, create an XML config file manually:

```xml
<?xml version="1.0"?>
<ices:Configuration xmlns:ices="http://www.icecast.org/projects/ices">
  <Playlist>
    <Randomize>0</Randomize>
    <Type>builtin</Type>
    <File>/ices/playlist.txt</File>
    <Crossfade>2</Crossfade>
    <MinCrossfade>0</MinCrossfade>
    <CrossMix>0</CrossMix>
    <Module>ices</Module>
    <CueFile>/data/ices0/ices.cue</CueFile>
  </Playlist>
  <Execution>
    <Background>0</Background>
    <Verbose>0</Verbose>
    <Timestamp>0</Timestamp>
    <BaseDirectory>/tmp</BaseDirectory>
  </Execution>
  <Stream>
    <Server>
      <Hostname>localhost</Hostname>
      <Port>8000</Port>
      <Password>hackme</Password>
      <Protocol>http</Protocol>
    </Server>
    <Mountpoint>/stream</Mountpoint>
    <Name>My Audio Stream</Name>
    <Genre>Various</Genre>
    <Description>Audio stream powered by ices0</Description>
    <URL></URL>
    <Public>1</Public>
    <Encode>
      <Reencode>0</Reencode>
      <Channels>2</Channels>
      <Samplerate>44100</Samplerate>
      <Bitrate>320</Bitrate>
    </Encode>
  </Stream>
</ices:Configuration>
```

Then run:

```bash
./ices0 -c ices.xml
```

See also the [upstream example config](https://github.com/Moonbase59/ices0/blob/master/doc/ices.conf.dist).

### Command-Line Options

```
Usage: ices0 [options]
Options:
  -B           Run in background (daemon mode)
  -b <stream>  Start streaming from stream #
  -c <file>    Use configuration file <file>
  -D <dir>     Run in directory <dir>
  -f <file>    Use playlist file <file> (overrides config)
  -F <file>    Use XML configuration file <file>
  -h           Display help
  -i           Generate instant playlist from command line args
  -m <file>    Use metadata file (for ReplayGain, etc.)
  -n <file>    Use named pipe <file> for playlist
  -r           Randomize playlist
  -S           Run as a daemon, but not in the background
  -s           Activate stream #
  -v           Verbose output
  -V           Display version information
```

---

## 🔍 Troubleshooting

**Binary won't execute**

```bash
chmod +x ices0-*
uname -m  # Should be x86_64 or aarch64/arm64
```

**Garbled metadata characters (e.g. `ÿþ`)** — these builds include proper UTF-8 metadata handling for ID3 tags (MP3), Vorbis comments (FLAC/Vorbis), and other formats, covering UTF-16 (with BOM detection), ISO-8859-1, and UTF-8 passthrough. The issue is usually with older or improperly compiled versions.

**Connection issues** — verify the Icecast server is running, the port is reachable, the password matches, and the mount point is available.

**Audio formats:**

- Input: MP3, Vorbis (`.ogg`), FLAC (`.flac`), MP4/AAC (`.m4a`, `.aac`)
- Output: MP3 only (this is ices0, not ices2 — for Vorbis output use [ices2](https://icecast.org/ices/))

---

## 🛠️ Development

This repository contains three GitHub Actions workflows: [build-env-image.yml](.github/workflows/build-env-image.yml) maintains the reusable Linux build image, [build-linux-binaries.yml](.github/workflows/build-linux-binaries.yml) builds and releases binaries, and [security.yml](.github/workflows/security.yml) runs secret scanning, workflow policy checks, and container image scanning.

Linux builds run inside the reusable `ghcr.io/binmgr/ices0:build` image produced from [docker/Dockerfile.build](docker/Dockerfile.build). FreeBSD builds run in native QEMU VMs via `vmactions/freebsd-vm`.

### Make Targets

| Target | Description |
|--------|-------------|
| `make` / `make help` | Show all targets and current version |
| `make build-env` | Build and push the Docker build environment image (`docker/Dockerfile.build`) |
| `make build` | Build ices0 binary for the host architecture into `binaries/` |
| `make docker` | Build the runtime image locally for testing (single-arch, `--load`) |
| `make clean` | Remove `binaries/` |

### How It Works

1. `build-env-image.yml` builds `ghcr.io/binmgr/ices0:build` when `docker/Dockerfile.build` changes, quarterly, or manually
2. `build-linux-binaries.yml` triggers on successful `Build Environment Image` completion on main/master, or manually
3. Linux amd64 builds natively with Alpine GCC; Linux arm64 cross-builds with the Bootlin musl toolchain
4. FreeBSD builds natively inside QEMU VMs via `vmactions/freebsd-vm`
5. Version is extracted from upstream `configure.ac` at build time
6. Release is created with all binaries, checksums, and container image tags `latest`, `{version}`, `{yymm}`

### Build Times

| Job | Approximate Time |
|-----|-----------------|
| Linux amd64 | ~30–45 min (container-based) |
| Linux arm64 | ~45–60 min (cross-compilation with Bootlin toolchain) |
| FreeBSD amd64 | ~40–60 min (QEMU VM overhead) |
| FreeBSD arm64 | ~40–60 min (QEMU VM overhead) |

### Local Testing with `act`

Test workflows locally using [`act`](https://github.com/nektos/act):

```bash
# List all jobs in a workflow
act --list -W .github/workflows/build-linux-binaries.yml

# Run all Linux build matrix jobs
act -j build-linux -W .github/workflows/build-linux-binaries.yml
```

FreeBSD builds and the release job require live GitHub Actions (QEMU VM provisioning and GitHub release API).

```bash
# Manual test in the build container
docker run --rm -it ghcr.io/binmgr/ices0:build sh
# Then: build-ices0 amd64
```

### 🐳 Docker build

Build the runtime image locally (requires `binaries/ices0-linux-{arch}` from `make build` first):

```bash
make build       # produces binaries/ices0-linux-amd64 (or arm64)
make docker      # builds ghcr.io/binmgr/ices0:dev locally
```

To build and push the Docker build environment image:

```bash
make build-env   # builds + pushes ghcr.io/binmgr/ices0:build (multi-arch)
```

---

## 📄 License

- **ices0**: GPL-2.0 — see [LICENSE.md](LICENSE.md)
- **Build workflow**: MIT License

**Credits:** [Xiph.Org Foundation](https://www.xiph.org/) (ices0 original) · [Moonbase59](https://github.com/Moonbase59/ices0) (ices0 enhanced) · this repository (multi-platform builds)

**Links:** [Upstream ices0 source](https://github.com/Moonbase59/ices0) · [Official ices documentation](https://icecast.org/ices/) · [Icecast server](https://icecast.org/) · [Configuration examples](https://github.com/Moonbase59/ices0/tree/master/doc)

For ices0 bugs report to [upstream](https://github.com/Moonbase59/ices0/issues). For build issues report to [this repository](../../issues).
