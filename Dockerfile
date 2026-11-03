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
      bash ca-certificates curl tar gzip \
 && rm -rf /var/lib/apt/lists/*


# The upstream steam user already owns UID 1000, which is the UID expected
# by Pterodactyl. Reuse it instead of creating a conflicting second account.
RUN id steam \
 && test "$(id -u steam)" = "1000" \
 && mkdir -p /home/container/server /home/steam/steamcmd \
 && if [[ ! -f /home/steam/steamcmd/steamcmd.sh ]]; then \
      curl -fsSL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' \
        | tar -xz -C /home/steam/steamcmd; \
    fi \
 && test -x /home/steam/steamcmd/steamcmd.sh \
 && chown -R steam:steam /home/steam/steamcmd /home/container

ENV HOME=/home/container \
    STEAMCMD_DIR=/home/steam/steamcmd \
    ARM64_DEVICE=generic

WORKDIR /home/container
USER steam
# Pterodactyl/Wings supplies and supervises the egg startup command.
# Clear any inherited entrypoint so the egg command is executed directly.
ENTRYPOINT []
CMD ["bash"]
