# Counter-Strike 1.6 HLDS on ARM64

A Pterodactyl-oriented ARM64 Docker image for the **32-bit x86** GoldSrc dedicated server. It uses QEMU user-mode emulation and an i386 userspace. This is compatibility emulation, not a native ARM64 HLDS build.

> **Experimental:** validate SteamCMD/App ID 90 content, QEMU compatibility, and server performance on the target VPS before production use.

## Image

```text
ghcr.io/ekretos/ogcounter:arm64
```

The GitHub Actions workflow publishes `arm64` and `latest` tags for pushes to `dev`, plus version tags.

## Why the runtime is seeded into /home/container

Pterodactyl/Wings bind-mounts the server's persistent directory at `/home/container`. Files baked into that path in a Docker image are hidden by the mount. Therefore the image stores its QEMU/i386 runtime at `/opt/ogcounter-runtime`; its entrypoint copies that payload into:

```text
/home/container/.ogcounter/runtime/
├── usr/bin/qemu-i386-static
└── opt/i386/
    ├── lib/
    └── usr/lib/
```

This makes the runtime visible in Pterodactyl File Manager and persistent across restarts. The launcher uses the copied paths. Existing `server/` and `.steamcmd/` contents are not overwritten.

## Build locally

```bash
docker buildx build --platform linux/arm64 -t ghcr.io/ekretos/ogcounter:arm64 --load .
docker image inspect ghcr.io/ekretos/ogcounter:arm64 --format '{{.Os}}/{{.Architecture}}'
```

Expected: `linux/arm64`.

## Pterodactyl setup

1. Wait for the GitHub Actions workflow to complete.
2. Make the GHCR package public or configure registry credentials in Wings.
3. Import `egg/cs16-arm64.json`.
4. Assign a UDP allocation (default `27015`).
5. Select the `ARM64` Docker image and start the server.

The egg startup command invokes `/usr/local/bin/ogcounter-entrypoint`. On every start it refreshes the runtime payload in `/home/container/.ogcounter/runtime`, then launches the CS server. First start downloads SteamCMD and attempts App ID 90 installation; later starts reuse the persistent server and SteamCMD directories.

## Environment variables

| Variable | Default | Meaning |
|---|---:|---|
| `SERVER_PORT` | `27015` | HLDS UDP port |
| `SERVER_MAP` | `de_dust2` | Initial map |
| `MAX_PLAYERS` | `16` | Player slots (1-32) |
| `SERVER_PASSWORD` | empty | Optional join password |
| `RCON_PASSWORD` | empty | Optional RCON password |
| `OGCOUNTER_RUNTIME_DIR` | `/home/container/.ogcounter/runtime` | Persistent runtime payload location |

## Troubleshooting

- **Missing `cstrike/` after App ID 90:** the launcher stops rather than reporting a false-ready server. Verify the SteamCMD app/depot content delivered for your account and region. Do not copy game content from untrusted images.
- **Exec format error:** verify the image is `linux/arm64` and the node is `aarch64`.
- **QEMU missing libraries:** inspect the failing i386 binary and add the required package to the `i386-libs` build stage.
- **SteamCMD download failures:** verify outbound HTTPS and DNS from the Wings node.
- **Permissions:** the Wings server volume must be writable by the image's `container` user (UID 1000).

## License and game content

This repository contains the container build and launcher, not Counter-Strike game assets. SteamCMD downloads server files from Valve. Comply with Valve/Steam terms and applicable game-server distribution rules.
