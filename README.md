# Counter-Strike 1.6 HLDS on ARM64

A Pterodactyl-oriented ARM64 Docker image for the **32-bit x86** GoldSrc dedicated server. It uses [Box64 with Box32](https://github.com/sonroyaalmerol/steamcmd-arm64) to run 32-bit SteamCMD and HLDS on ARM64.

> **Experimental:** validate SteamCMD/App ID 90 content, Box64 compatibility, and server performance on the target VPS before production use.

## Image

The project publishes exactly one image reference:

```text
ghcr.io/ekretos/ogcounter:arm64
```

GitHub Actions builds and pushes only this ARM64 image to GitHub Container Registry (GHCR). Docker Hub publishing and the `latest` tag are not used.

## Why Box64/Box32

The previous QEMU i386 approach fails with current SteamCMD because QEMU linux-user does not correctly support the robust-futex behavior SteamCMD now relies on. This image instead uses the ARM64 SteamCMD runtime maintained by `sonroyaalmerol/steamcmd-arm64`, which integrates Box64 and its Box32 compatibility layer. SteamCMD is launched through its provided `steamcmd.sh` wrapper; HLDS is launched through Box64.

## Pterodactyl setup

1. Wait for the GitHub Actions workflow to complete.
2. Make the GHCR package public or configure registry credentials in Wings.
3. Import `egg/cs16-arm64.json`.
4. Assign a UDP allocation (default `27015`).
5. Select the `ARM64` Docker image and start the server.

The egg startup command invokes `/usr/local/bin/ogcounter-entrypoint`. Game files are installed into the persistent `/home/container/server` directory; SteamCMD is supplied by the base runtime at `/home/steam/steamcmd`. First start attempts App ID 90 installation; later starts reuse the persistent server files.

## Environment variables

| Variable | Default | Meaning |
|---|---:|---|
| `SERVER_PORT` | `27015` | HLDS UDP port |
| `SERVER_MAP` | `de_dust2` | Initial map |
| `MAX_PLAYERS` | `16` | Player slots (1-32) |
| `SERVER_PASSWORD` | empty | Optional join password |
| `RCON_PASSWORD` | empty | Optional RCON password |
| `ARM64_DEVICE` | `generic` | Box64 build variant selector |

## Troubleshooting

- **Missing `cstrike/` after App ID 90:** the launcher stops rather than reporting a false-ready server. Verify the SteamCMD app/depot content delivered for your account and region.
- **Exec format error:** verify the image is `linux/arm64` and the node is `aarch64`.
- **Box64 library errors:** capture the complete Box64 output; the upstream ARM64 runtime provides the x86 compatibility libraries and Box32 setup.
- **SteamCMD download failures:** verify outbound HTTPS and DNS from the Wings node.
- **Permissions:** the Wings server volume must be writable by the image's `container` user (UID 1000).

## License and game content

This repository contains the container build and launcher, not Counter-Strike game assets. SteamCMD downloads server files from Valve. Comply with Valve/Steam terms and applicable game-server distribution rules.
