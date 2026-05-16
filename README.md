# ices0 - Multi-Platform Static Binary Builds

Automated builds of static [ices0](https://github.com/Moonbase59/ices0) binaries for **Linux and FreeBSD** (amd64/arm64), plus a multi-arch Docker image with environment-variable-driven configuration.

## What is ices0?

ices0 is a source client for streaming MP3 audio to an Icecast server. It's the original ices (version 0.x) that supports MP3 format streaming.

### Key Features

- Stream MP3 files to Icecast servers
- Real-time re-encoding at different bitrates
- Transcoding from Vorbis, FLAC, and MP4/AAC to MP3
- Crossfading between tracks
- XML-based configuration
- Playlist management (static files, shell scripts, Python, Perl)
- Metadata and ReplayGain support
- Proper UTF-8 metadata handling

## Features in These Builds

All optional features are compiled in:

- ✅ XML configuration support (libxml2)
- ✅ MP3 re-encoding (LAME)
- ✅ Vorbis transcoding (libvorbis)
- ✅ FLAC transcoding (libFLAC)
- ✅ MP4/AAC transcoding (FAAD2)
- ✅ TLS/SSL support (OpenSSL)
- ✅ Proper UTF-8 metadata handling (built-in)
- ❌ Python scripting (disabled in the fully static Linux build)
- ❌ Perl scripting (disabled in the fully static Linux build)

### Static Binaries

All supported libraries in the Linux build are statically linked so the runtime image can stay `FROM scratch`.

**Static (built-in)**:
- All audio codecs (MP3/LAME, Vorbis, FLAC, AAC/FAAD2)
- XML configuration (libxml2)
- SSL/TLS support (OpenSSL)
- All streaming libraries (libshout)

**Not included in the static Linux build**:
- Python playlist scripting
- Perl playlist scripting

## Downloads

See [Releases](../../releases) for downloads.

Container images are also published to `ghcr.io/binmgr/ices0` with these tags:

- `latest` - newest released version
- `{version}` - numbered release tag such as `1.3.2`
- `{yymm}` - release month tag such as `2605`

### Available Builds

Each release includes binaries for:

| Platform | Architectures | Notes |
|----------|---------------|-------|
| **Linux** | amd64, arm64 | Fully static (musl) |
| **FreeBSD** | amd64, arm64 | Native build, dynamic system libs |

Plus:
- **checksums.txt** — SHA-256 checksums for all binaries

## Quick Start

### Binary

```bash
# Download the binary for your platform and architecture, e.g. Linux amd64:
wget https://github.com/binmgr/ices0/releases/latest/download/ices0-linux-amd64

chmod +x ices0-linux-amd64
./ices0-linux-amd64 -V
```

### Docker

```bash
# Drop-in replacement for zerg13/ices — configure entirely via environment variables:
docker run --rm \
  -e STREAM_HOST=icecast-server \
  -e STREAM_PASSWORD=changeme \
  -e STREAM_MOUNTPOINT=/music \
  -e STREAM_NAME="My Music" \
  -v /path/to/music:/media:ro \
  ghcr.io/binmgr/ices0:latest
```

See [docker/docker-compose.yml](docker/docker-compose.yml) for a full Compose stack.

### Verify Integrity (Optional)

```bash
wget https://github.com/binmgr/ices0/releases/latest/download/checksums.txt
sha256sum -c checksums.txt --ignore-missing
```

## Docker Environment Variables

The container image is a drop-in replacement for `zerg13/ices`. Configure it entirely via environment variables — no config file needed.

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
| `STREAM_VERBOSE` | `0` | `1` = verbose logging |
| `STREAM_BACKGROUND` | `0` | `1` = daemon mode (avoid in containers) |
| `STREAM_PLAYLIST_TYPE` | `builtin` | Playlist module |
| `STREAM_INTERPRETER_MODULE` | `ices` | Interpreter module name |
| `STREAM_MEDIA_FOLDER` | `/media` | Mount your audio files here |
| `STREAM_CONFIG` | `/ices/ices.conf` | Generated config path |
| `STREAM_PLAYLIST` | `/ices/playlist.txt` | Generated playlist path |

When `STREAM_PLAYLIST_TYPE=builtin`, the entrypoint automatically scans `STREAM_MEDIA_FOLDER` for `*.mp3`, `*.ogg`, `*.flac`, `*.m4a`, `*.aac` files and generates the playlist.

## Configuration

Create an `ices.xml` configuration file. See the [upstream example](https://github.com/Moonbase59/ices0/blob/master/doc/ices.conf.dist):

```xml
<?xml version="1.0"?>
<ices:Configuration xmlns:ices="http://www.icecast.org/projects/ices">
  <Server>
    <Hostname>localhost</Hostname>
    <Port>8000</Port>
    <Password>hackme</Password>
    <Protocol>http</Protocol>
  </Server>

  <Execution>
    <Background>0</Background>
    <Verbose>1</Verbose>
  </Execution>

  <Stream>
    <Server>
      <Mount>/stream.mp3</Mount>
      <Name>My Audio Stream</Name>
      <Genre>Various</Genre>
      <Description>Audio stream powered by ices0</Description>
    </Server>

    <Playlist>
      <File>/path/to/playlist.txt</File>
      <Type>basic</Type>
      <Module>playlist_basic</Module>
      <Randomize>1</Randomize>
    </Playlist>
  </Stream>
</ices:Configuration>
```

Then run:

```bash
./ices0 -c ices.xml
```

## Command-Line Options

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

## Python/Perl Scripting

Python and Perl playlist scripting are disabled in the fully static Linux build so the binary stays scratch-compatible.

You can still use:
- Static file playlists
- Shell script playlists
- Built-in playlist module

## Metadata UTF-8 Support

These builds include proper UTF-8 metadata handling for ID3 tags (MP3), Vorbis comments (FLAC/Vorbis), and other formats. The built-in conversion handles:

- UTF-16 (with byte-order mark detection)
- ISO-8859-1 (Latin-1)
- UTF-8 (passthrough)

If you're seeing garbled characters like `ÿþ` in your metadata, these properly compiled binaries should fix the issue.

## Build System

This repository contains two GitHub Actions workflows: [.github/workflows/build-env-image.yml](.github/workflows/build-env-image.yml) maintains the reusable Linux build image, and [.github/workflows/build-linux-binaries.yml](.github/workflows/build-linux-binaries.yml) builds and releases binaries.

Linux builds run inside the reusable `ghcr.io/binmgr/ices0:build` image produced from [docker/Dockerfile.build](docker/Dockerfile.build). FreeBSD builds run in native QEMU VMs via `vmactions/freebsd-vm`.

### How It Works

1. `build-env-image.yml` builds `ghcr.io/binmgr/ices0:build` when `docker/Dockerfile.build` changes, quarterly, or manually
2. `build-linux-binaries.yml` triggers on successful `Build Environment Image` completion on main/master, or manually
3. Linux amd64 builds natively with Alpine GCC; Linux arm64 cross-builds with the Bootlin musl toolchain
4. FreeBSD builds natively inside QEMU VMs via `vmactions/freebsd-vm`
5. Version is extracted from upstream `configure.ac` at build time
6. Release is created with all binaries, checksums, and container image tags `latest`, `{version}`, `{yymm}`

### What Gets Built

For Linux (statically linked into the binary):
- zlib, libogg, libvorbis, libFLAC, libmp3lame, libfaad2, OpenSSL, libshout, libxml2
- ices0 with all the above

For FreeBSD (dynamically linked against pkg-installed system libs):
- All of the above via `pkg install`

### Build Times

- **Linux amd64**: ~30–45 min (container-based)
- **Linux arm64**: ~45–60 min (cross-compilation with Bootlin toolchain)
- **FreeBSD amd64/arm64**: ~40–60 min each (QEMU VM overhead)

## Platform-Specific Notes

### Linux
- Fully static — zero dynamic dependencies
- Works on any Linux distribution (glibc or musl)

### FreeBSD
- Dynamically linked against FreeBSD 15.0 system libraries
- Python/Perl scripting requires `pkg install python3 perl5`

## Troubleshooting

### Binary won't execute

```bash
# Make sure it's executable
chmod +x ices0-*

# Check architecture matches your system
uname -m  # Should be x86_64 or aarch64/arm64
```

### Metadata issues

Make sure you're using these binaries which have proper UTF-8 conversion built-in. The issue is usually with older or improperly compiled versions.

### Connection issues

Check your Icecast server configuration:
- Server is running
- Port is accessible
- Password matches
- Mount point is available

### Audio format issues

These builds support:
- **Input**: MP3, Vorbis (.ogg), FLAC (.flac), MP4/AAC (.m4a, .aac)
- **Output**: MP3 only (this is ices0, not ices2)

For Vorbis output, use [ices2](https://icecast.org/ices/).

## Credits

- **ices0 original**: [Xiph.Org Foundation](https://www.xiph.org/)
- **ices0 enhanced**: [Moonbase59](https://github.com/Moonbase59/ices0)
- **Multi-platform builds**: This repository

## License

- **ices0**: GPL-2.0 (see [LICENSE.md](LICENSE.md))
- **Build workflow**: MIT License

## Links

- [Upstream ices0 source](https://github.com/Moonbase59/ices0)
- [Official ices documentation](https://icecast.org/ices/)
- [Icecast server](https://icecast.org/)
- [Configuration examples](https://github.com/Moonbase59/ices0/tree/master/doc)

## Support

For issues with:
- **ices0 itself**: Report to [upstream](https://github.com/Moonbase59/ices0/issues)
- **These builds**: Report to [this repository](../../issues)
- **Icecast server**: See [Icecast docs](https://icecast.org/)

## Local Testing with `act`

Test Linux builds locally using [`act`](https://github.com/nektos/act):

```bash
# Test Linux amd64 build
act -j build-linux --matrix arch:amd64

# Test Linux arm64 build
act -j build-linux --matrix arch:arm64

# List all jobs
act -l
```

FreeBSD and the release job require live GitHub Actions (VM and GitHub release API).

```bash
# Manual test in the build container
docker run --rm -it ghcr.io/binmgr/ices0:build sh
# Then: build-ices0 amd64
```
