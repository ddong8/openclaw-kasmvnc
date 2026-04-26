# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

One-click deployment tool for OpenClaw + KasmVNC. Four self-contained scripts (two versions) generate all Docker build files at runtime — no static Dockerfiles or Compose files in the repo.

### File Structure

| File | Version | Description |
|------|---------|-------------|
| `openclaw-kasmvnc.sh` | International | Bash script for macOS/Linux — official sources, en_US locale, UTC timezone |
| `openclaw-kasmvnc.ps1` | International | PowerShell script for Windows — same as above |
| `openclaw-kasmvnc-zh.sh` | Chinese (中文) | Bash script — China mirrors, zh_CN locale, Asia/Shanghai, Fcitx5 + Rime |
| `openclaw-kasmvnc-zh.ps1` | Chinese (中文) | PowerShell script — same as above |

Each `.sh` / `.ps1` pair shares identical logic and must be kept in sync. The `-zh` variants add:
- China-optimized mirrors: Tsinghua (apt), Aliyun (Docker CE), npmmirror (npm), Huawei Cloud (base image), claw.ihasy.com (KasmVNC/Rime)
- Chinese locale (`zh_CN.UTF-8`) and timezone (`Asia/Shanghai`)
- Fcitx5 + Rime Ice (雾凇拼音) input method with full CJK fonts
- KasmVNC downloaded from self-hosted mirror instead of GitHub releases

## Architecture

The scripts dynamically generate these files in the install directory at runtime:
- `Dockerfile.kasmvnc` — Node 22 + KasmVNC + XFCE4 + Docker-in-Docker (+ Fcitx5 in zh version)
- `docker-compose.yml` — Service definition with port mappings, volumes, GPU support
- `.env` — Auto-generated tokens, passwords, ports, proxy settings
- `scripts/docker/kasmvnc-startup.sh` — Container entrypoint (VNC → desktop → gateway supervisor)
- `scripts/docker/systemctl-shim.sh` — systemd emulation via process signals and `lsof`-based PID detection

Key design decisions:
- **Supervisor loop** in `kasmvnc-startup.sh` auto-restarts the gateway on crash (runs in foreground)
- **systemctl shim** intercepts `systemctl` calls so `openclaw gateway restart/stop/start` works without systemd
- **Port-based PID detection** via `lsof` because Node.js overwrites its process title
- **Clipboard DLP override** removes `chromium/x-web-custom-data` MIME to prevent `pkill -f chromium` from killing VNC

## Commands

No build/test/lint system — this is a deployment automation project. To test changes locally:

```bash
# International version
./openclaw-kasmvnc.sh install

# Chinese version
./openclaw-kasmvnc-zh.sh install

# Other commands: uninstall, restart, upgrade, status, logs
./openclaw-kasmvnc.sh status
./openclaw-kasmvnc.sh logs --tail 200
```

## Development Notes

- `README.md` is English; `README-zh.md` is Chinese — keep both updated
- Generated files use `cat <<'HEREDOC_TAG'` — watch for quoting/escaping when editing heredocs
- The `ensure_build_context()` function contains all generated file content — this is the core function to modify for Docker/container changes
- `upgrade` does a hot npm update without rebuilding the image; `install` does a full rebuild
- GPU support is auto-detected via `nvidia-smi` and conditionally adds `runtime: nvidia` to compose
- When making changes, apply to both international and zh versions where applicable
