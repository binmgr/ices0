# ices0 - Multi-Platform Static Binary Builds

Automated builds of static [ices0](https://github.com/Moonbase59/ices0) binaries for **Linux, macOS, Windows, and FreeBSD** (all amd64/arm64).

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
- ✅ Python scripting (dynamic - requires Python runtime on user system)
- ✅ Perl scripting (dynamic - requires Perl runtime on user system)

### Static Binaries

All audio codec libraries are statically linked. Python and Perl are dynamically linked to enable scripting features without bloating binaries.

**Static (built-in)**:
- All audio codecs (MP3/LAME, Vorbis, FLAC, AAC/FAAD2)
- XML configuration (libxml2)
- SSL/TLS support (OpenSSL)
- All streaming libraries (libshout)

**Dynamic (optional)**:
- Python 3 (for Python playlist scripts)
- Perl (for Perl playlist scripts)

If you don't use scripting features, the binaries work standalone without Python/Perl installed.

## Downloads

See [Releases](../../releases) for downloads.

### Available Builds

Each release includes binaries for:

| Platform | Architectures | Notes |
|----------|---------------|-------|
| **Linux** | x86_64, aarch64 | Fully static (musl libc) |
| **macOS** | x86_64, arm64 | Near-static (system libs dynamic) |
| **Windows** | x86_64, aarch64 | Static (.exe binaries) |
| **FreeBSD** | x86_64, aarch64 | Static |

Plus:
- **Source archive** (`ices0-X.X.X-src.tar.gz`) - No VCS files
- **SHA256SUMS.txt** - Checksums for verification

## Quick Start

### Linux/macOS/FreeBSD

```bash
# Download the appropriate binary for your platform and architecture
# Example for Linux x86_64:
wget https://github.com/YOUR-USERNAME/ices0/releases/latest/download/ices0-linux-x86_64

# Make it executable
chmod +x ices0-linux-x86_64

# Rename for convenience (optional)
mv ices0-linux-x86_64 ices0

# Run
./ices0 -V
```

### Windows

```powershell
# Download from releases page or use curl/wget
# Example: ices0-windows-x86_64.exe

# Run
.\ices0-windows-x86_64.exe -V
```

### Verify Integrity (Optional)

```bash
# Download checksums
wget https://github.com/YOUR-USERNAME/ices0/releases/latest/download/SHA256SUMS.txt

# Verify
sha256sum -c SHA256SUMS.txt --ignore-missing
```

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

These builds have Python and Perl **features compiled in** but **dynamically linked**. To use scripting features, install the runtime on your system:

### Linux
```bash
# Debian/Ubuntu
sudo apt install python3 perl

# RHEL/CentOS/Fedora
sudo dnf install python3 perl

# Alpine
apk add python3 perl

# Arch
sudo pacman -S python perl
```

### macOS
```bash
# Usually pre-installed, or via Homebrew
brew install python3 perl
```

### Windows
- **Python**: Download from [python.org](https://www.python.org/downloads/)
- **Perl**: Install [Strawberry Perl](https://strawberryperl.com/) or [ActivePerl](https://www.activestate.com/products/perl/)

### FreeBSD
```bash
pkg install python3 perl5
```

**Without Python/Perl installed**, you can still use:
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

This repository contains only the GitHub Actions workflow for automated multi-platform builds. All build logic is inline in [.github/workflows/build.yml](.github/workflows/build.yml).


### How It Works

1. **Triggers**: Builds run on push to main/master, monthly on the 1st at 00:00 UTC, or manually
2. **Platforms**: Linux (Alpine/musl), macOS (native), Windows (MinGW), FreeBSD (VM)
3. **Dependencies**: All 9 libraries built from source statically
4. **ices0**: Built with all features enabled, Python/Perl dynamically linked
5. **Release**: Automatic GitHub release with version from upstream

### What Gets Built

For each platform:
- zlib (compression)
- libogg (audio container)
- libvorbis (Vorbis codec)
- libFLAC (FLAC codec)
- libmp3lame (MP3 encoder)
- libfaad2 (AAC decoder)
- OpenSSL (TLS/SSL)
- libshout (Icecast streaming)
- libxml2 (XML configuration)
- ices0 (with all of the above)

### Build Times

Approximate build times per platform:
- **Linux**: ~30-45 minutes (per arch)
- **macOS**: ~25-35 minutes (per arch)
- **Windows**: ~35-50 minutes (per arch)
- **FreeBSD**: ~40-60 minutes (per arch, VM overhead)

**Total workflow**: ~2-3 hours for all 10 binaries in parallel

## Platform-Specific Notes

### Linux
- **Fully static** with musl libc
- Zero dynamic dependencies (except Python/Perl if using scripting)
- Works on any Linux distribution

### macOS
- **Near-static** (system libraries must be dynamic)
- Requires macOS 12+ (Monterey or later)
- Python/Perl support requires system runtimes

### Windows
- **Static** MinGW build
- No DLL dependencies (except Windows system DLLs)
- Python/Perl support requires separate installation

### FreeBSD
- **Static** build
- Tested on FreeBSD 14.0
- Python/Perl support requires pkg installation

## Troubleshooting

### Binary won't execute

```bash
# Linux/macOS/FreeBSD: Make sure it's executable
chmod +x ices0-*

# Check architecture matches your system
uname -m  # Should be x86_64 or aarch64/arm64
```

### Python/Perl scripting not working

```bash
# Check if Python/Perl are installed
python3 --version
perl --version

# If not, install them (see Python/Perl Scripting section above)
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

Test workflows locally using [`act`](https://github.com/nektos/act) to avoid consuming GitHub Actions minutes.

### Installation

**macOS:**
```bash
brew install act
```

**Linux:**
```bash
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Windows:**
```bash
choco install act-cli
# or with scoop
scoop install act
```

### What Works with `act`

| Platform | Works with `act`? | Notes |
|----------|-------------------|-------|
| **Linux builds** | ✅ Yes | Fully supported, uses Docker |
| **Windows builds** | ⚠️ Partial | MinGW cross-compile might work |
| **macOS builds** | ❌ No | Requires actual macOS runners |
| **FreeBSD builds** | ❌ No | Requires VM action |
| **Release job** | ❌ No | Needs GitHub release API |

### Quick Start

**Test Linux x86_64 build (fastest):**
```bash
act -j build-linux --matrix arch:x86_64
```

**Test Linux aarch64 build:**
```bash
act -j build-linux --matrix arch:aarch64
```

**List all jobs without running:**
```bash
act -l
```

**Dry run (validate syntax):**
```bash
act -j build-linux --matrix arch:x86_64 --dryrun
```

**Verbose output (debugging):**
```bash
act -j build-linux --matrix arch:x86_64 -v
```

### Expected Build Times

| Build | Time | Notes |
|-------|------|-------|
| Linux x86_64 | ~30-45 min | Native architecture |
| Linux aarch64 | ~45-60 min | QEMU emulation (slower) |

### Iterative Development Workflow

1. Make changes to `.github/workflows/build.yml`
2. Test locally: `act -j build-linux --matrix arch:x86_64`
3. Fix issues and repeat until it works
4. Push to GitHub for full multi-platform build
5. Monitor GitHub Actions for macOS/Windows/FreeBSD

### Common Issues

**"alpine.sh shell not found"**

Test manually in Docker:
```bash
docker run -it --rm -v $(pwd):/work -w /work alpine:latest sh
apk add build-base autoconf automake libtool pkgconfig git curl tar gzip bzip2 xz python3-dev perl-dev
# Copy build commands from .github/workflows/build.yml
```

**Build takes forever**

Only test x86_64 (ARM64 emulation is slow):
```bash
act -j build-linux --matrix arch:x86_64
```

**Out of disk space**

Clean Docker images:
```bash
docker system prune -a
```

### GitHub Actions Minutes Savings

Testing locally with `act` saves:
- **Initial development**: ~200-300 minutes per full run
- **Each iteration**: ~200-300 minutes per push
- **Total savings**: 1000+ minutes during development

With the free tier's 2000 minutes/month, local testing lets you develop unlimited times locally and only use GitHub Actions for final validation.

### Resources

- [act documentation](https://github.com/nektos/act)
- [act CLI reference](https://nektosact.com/usage/index.html)
- [GitHub Actions Docker images](https://github.com/nektos/act#default-runners)
