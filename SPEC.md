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

## Custom build toolchain

Global conventions prescribe language-specific Alpine base images (`golang:alpine`, `rust:alpine`). This project
builds a **C autotools project** (ices0), so the build image (`docker/Dockerfile.build`) uses `alpine:latest`
as its base — there is no `c:alpine` official image.

The arm64 build does not use an Alpine cross-compiler package. Instead it downloads a
**Bootlin aarch64-musl cross-compilation toolchain** at image-build time:

```
aarch64--musl--stable-2025.08-1  (from toolchains.bootlin.com)
```

This is required because Alpine's `cross-compile-aarch64` packages do not produce fully static musl binaries
compatible with the `FROM scratch` runtime image. The Bootlin toolchain is pinned by filename in the
`BOOTLIN_AARCH64_MUSL_URL` build arg — update it deliberately when upgrading.

The arm64 static dependency stack (zlib, xz, openssl, libxml2, libogg, libvorbis, faad2, flac, lame, mp4v2,
libshout) is built from source inside the image using that cross-compiler. Versions are pinned inside
`build-ices0` — change them intentionally, never automatically.

The build image tag is `:build` (rolling) per the dev-images convention. The `BOOTLIN_AARCH64_MUSL_URL`
arg is the version pin — do not additionally pin the base `alpine:latest` tag.

## Static Python and Perl embedding

The Linux binary statically embeds Python and Perl. Their source tarballs are built inside
`docker/Dockerfile.build` and version-pinned via build ARGs:

- `PYTHON_VERSION="3.12.10"` — built to `/usr/local/python-static` (amd64) and cross-built to `${ARM64_PREFIX}` (arm64)
- `PERL_VERSION="5.38.4"` — built to `/usr/local/perl-static` (amd64); for arm64 only `make libperl.a` is run (the arm64 perl binary can't execute on the amd64 host; headers + library are manually installed to the CORE path)

Update these version pins intentionally; never automatically.

**Do not add `-Dstatic_ext='none'` to the Perl Configure invocation.** That flag prevents the `PathTools/Cwd` extension from being built, which causes the utils phase (`cpan`, `corelist`) to fail with "Can't locate Cwd.pm in @INC". The amd64 host build uses the default extension set; the arm64 cross-build avoids the issue entirely by only building `libperl.a`.

**`libffi-static` does not exist as an Alpine package.** `libffi-dev` already ships `libffi.a`. Do not
add `libffi-static` to the `apk add` line — it will break the build with "no such package".
