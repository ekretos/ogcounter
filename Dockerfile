# syntax=docker/dockerfile:1.7

# Box64 provides Box32 for 32-bit x86 SteamCMD/GoldSrc binaries on ARM64.
# This upstream runtime already handles the SteamCMD robust-futex limitation
# that makes qemu-i386 user-mode unusable with current SteamCMD.
FROM --platform=linux/arm64 ghcr.io/sonroyaalmerol/steamcmd-arm64:root-trixie

ARG TARGETARCH
LABEL org.opencontainers.image.title="Counter-Strike 1.6 HLDS (ARM64 via Box64)" \
      org.opencontainers.image.description="Pterodactyl-ready ARM64 runtime for 32-bit x86 SteamCMD and GoldSrc HLDS using Box64/Box32" \
      org.opencontainers.image.source="https://github.com/ekretos/ogcounter"

RUN test "$TARGETARCH" = "arm64" \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash ca-certificates curl tini tar gzip \
 && rm -rf /var/lib/apt/lists/*

COPY docker/cs16-start /usr/local/bin/cs16-start
COPY docker/ogcounter-entrypoint /usr/local/bin/ogcounter-entrypoint

# The upstream steam user already owns UID 1000, which is the UID expected
# by Pterodactyl. Reuse it instead of creating a conflicting second account.
RUN chmod 0755 /usr/local/bin/cs16-start /usr/local/bin/ogcounter-entrypoint \
 && id steam \
 && test "$(id -u steam)" = "1000" \
 && mkdir -p /home/container/server \
 && chown -R steam:steam /home/container

ENV HOME=/home/container \
    SERVER_DIR=/home/container/server \
    STEAMCMD_DIR=/home/steam/steamcmd \
    SERVER_PORT=27015 \
    SERVER_MAP=de_dust2 \
    MAX_PLAYERS=16 \
    RCON_PASSWORD= \
    SERVER_PASSWORD= \
    ARM64_DEVICE=generic

WORKDIR /home/container
USER steam
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/ogcounter-entrypoint"]
