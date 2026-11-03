# CS 1.6 ARM64 Pterodactyl image

Experimental project for running the 32-bit x86 GoldSrc HLDS dedicated server on ARM64 Linux using QEMU user-mode emulation.

> **Status: experimental / unvalidated.** The HLDS and SteamCMD Linux binaries are 32-bit x86, not ARM64. This image uses `qemu-i386` plus an i386 userspace; it is not a native ARM64 game server. Performance and compatibility depend on the host kernel, CPU, and QEMU.

Development happens on the `dev` branch. See the project documentation there once the initial implementation lands.
