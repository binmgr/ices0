# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | ✅ |
| Older releases | ❌ |

Only the most recent release receives security updates. Update to the latest release to receive fixes.

## Reporting a Vulnerability

To report a security vulnerability, email **casjay@yahoo.com** with:

- A description of the vulnerability
- Steps to reproduce
- Potential impact

**Do not open a public GitHub issue for security vulnerabilities.**

**Response SLA:**

- Acknowledge within 48 hours
- Patch within 14 days for critical/high severity issues after acknowledgement
- Coordinated disclosure — details published in GitHub Security Advisories after the fix is released

## Disclosure Timeline

1. Reporter notifies maintainer privately
2. Maintainer acknowledges within 48 hours
3. Maintainer investigates and develops a fix
4. Fix released; CVE details published in GitHub Security Advisories

## Out of Scope

The following are **not** considered vulnerabilities for this project:

- Vulnerabilities in the upstream [ices0](https://github.com/Moonbase59/ices0) source — report to that project
- Vulnerabilities in icecast or other third-party components in the Docker Compose reference stack — report to those projects directly
- Weak default `STREAM_PASSWORD=hackme` — this is a documented default for local development; change it before production use
- Container base image CVEs acknowledged upstream but not yet patched in Alpine — tracked and resolved when Alpine updates
