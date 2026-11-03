# Counter-Strike 1.6 HLDS on ARM64

A Pterodactyl-oriented ARM64 Docker image for the **32-bit x86** GoldSrc dedicated server. It uses QEMU user-mode emulation and an i386 userspace. This is compatibility emulation, **not** a native ARM64 HLDS build.

> **Experimental: not yet runtime-validated on the target VPS.** SteamCMD/App ID 90 content, QEMU compatibility, and server performance must be verified before production use.

## Image

```text
ghcr.io/ekretos/ogcounter:arm64
```

The GitHub Actions workflow builds and publishes `linux/arm64` on pushes to `dev` and version tags. The first GHCR package may be private: after the first successful publish, open the package settings on GitHub and change package visibility to **Public** if you want unauthenticated pulls.

## Why QEMU?

GoldSrc's Linux HLDS executable (`hlds_linux`) and the Linux SteamCMD client are 32-bit x86 binaries. An ARM64 Docker base image alone cannot execute them. This image includes `qemu-i386-static` and an i386 library root copied from a Debian i386 build stage.

This is distinct from Box64: Box64 targets x86-64; this workload's Linux server binary is 32-bit x86, so this project uses QEMU i386.

## Build locally

On an ARM64 or amd64 Docker host with Buildx and binfmt/QEMU support:

```bash
docker buildx build --platform linux/arm64 -t ghcr.io/ekretos/ogcounter:arm64 --load .
```

On an ARM64 host, verify the resulting image:

```bash
docker image inspect ghcr.io/ekretos/ogcounter:arm64 --format '{{.Os}}/{{.Architecture}}'
```

Expected: `linux/arm64`.

## Pterodactyl setup

1. Wait for the GitHub Actions workflow to complete successfully.
2. If the GHCR package is private, make it public in GitHub package settings, or configure registry credentials in Wings.
3. Import `egg/cs16-arm64.json` in the Pterodactyl panel.
4. Assign a UDP allocation (default port `27015`) to the server.
5. Select the `ARM64` Docker image and start the server.

On first start, the launcher downloads Valve SteamCMD and attempts to install/update HLDS using anonymous SteamCMD access and App ID 90. Subsequent starts reuse files in the server's persistent `/home/container` volume.

Environment variables:

| Variable | Default | Meaning |
|---|---:|---|
| `SERVER_PORT` | `27015` | HLDS UDP port |
| `SERVER_MAP` | `de_dust2` | Initial map |
| `MAX_PLAYERS` | `16` | Player slots (1-32) |
| `SERVER_PASSWORD` | empty | Optional join password |
| `RCON_PASSWORD` | empty | Optional RCON password |

## Important validation / troubleshooting

- **Missing `cstrike/` after App ID 90:** the launcher stops instead of pretending the server is ready. Verify the SteamCMD app/depot contents for your region and account. The exact Counter-Strike dedicated-server content may need an additional legitimate SteamCMD app/depot installation step; do not copy game content from untrusted images.
- **`Exec format error`:** confirm the image is `linux/arm64`, and that the host is actually aarch64.
- **QEMU errors / missing shared libraries:** inspect the failing binary with `file` and `ldd` inside an i386 environment, then add the missing i386 runtime library to the `i386-libs` Docker build stage.
- **Poor performance:** QEMU user-mode emulation adds overhead. A small ARM VPS may not deliver acceptable tick rate or player capacity.
- **SteamCMD download failures:** verify outbound HTTPS/DNS access from the Wings node.

Useful host checks:

```bash
uname -m
docker pull --platform linux/arm64 ghcr.io/ekretos/ogcounter:arm64
docker image inspect ghcr.io/ekretos/ogcounter:arm64 --format '{{.Os}}/{{.Architecture}}'
```

## License and game content

This repository contains the container build and launcher, not Counter-Strike game assets. SteamCMD downloads server files from Valve. You must comply with Valve/Steam terms and the applicable game-server distribution rules.
