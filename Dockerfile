# syntax=docker/dockerfile:1.7

# GoldSrc HLDS and Valve SteamCMD are 32-bit x86 binaries. Build their
# userspace separately, then run them on ARM64 with QEMU user-mode.
FROM --platform=linux/386 debian:bookworm-slim AS i386-libs
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates libc6 libgcc-s1 libstdc++6 \
      libcurl4 libssl3 zlib1g libtinfo6 libncurses6 \
 && rm -rf /var/lib/apt/lists/*

FROM --platform=$TARGETPLATFORM debian:bookworm-slim

ARG TARGETARCH
LABEL org.opencontainers.image.title="Counter-Strike 1.6 HLDS (ARM64 via QEMU)" \
      org.opencontainers.image.description="Pterodactyl-ready ARM64 runtime for the 32-bit x86 GoldSrc dedicated server" \
      org.opencontainers.image.source="https://github.com/ekretos/ogcounter"

RUN test "$TARGETARCH" = "arm64" \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash ca-certificates curl tini tar gzip qemu-user-static \
 && rm -rf /var/lib/apt/lists/*

# Keep the compatibility runtime outside /home/container in the image.
# Pterodactyl bind-mounts /home/container and hides image files placed there.
# The entrypoint seeds this runtime into the persistent server volume at boot.
RUN install -d -m 0755 /opt/ogcounter-runtime/usr/bin /opt/ogcounter-runtime/opt/i386
COPY --from=i386-libs /lib /opt/ogcounter-runtime/opt/i386/lib
COPY --from=i386-libs /usr/lib /opt/ogcounter-runtime/opt/i386/usr/lib
RUN cp /usr/bin/qemu-i386-static /opt/ogcounter-runtime/usr/bin/qemu-i386-static \
 && chmod 0755 /opt/ogcounter-runtime/usr/bin/qemu-i386-static

COPY docker/cs16-start /usr/local/bin/cs16-start
COPY docker/ogcounter-entrypoint /usr/local/bin/ogcounter-entrypoint
RUN chmod 0755 /usr/local/bin/cs16-start /usr/local/bin/ogcounter-entrypoint \
 && useradd --create-home --uid 1000 --shell /bin/bash container \
 && mkdir -p /home/container/server /home/container/.steamcmd \
 && chown -R container:container /home/container

ENV HOME=/home/container \
    SERVER_DIR=/home/container/server \
    STEAMCMD_DIR=/home/container/.steamcmd \
    SERVER_PORT=27015 \
    SERVER_MAP=de_dust2 \
    MAX_PLAYERS=16 \
    RCON_PASSWORD= \
    SERVER_PASSWORD=

WORKDIR /home/container
USER container
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/ogcounter-entrypoint"]
