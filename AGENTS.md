# AGENTS.md

Bash tool that installs/manages the Proxmox Backup Client. No package manager, no build toolchain, no CI, no test harness, no linter config — verification is manual (`bash -n`) and running the scripts as root.

## Two deliverables

- **Native Linux (stable, v1.1.0)** — the flagship `pbs-client-installer.sh` (~2500 lines): interactive wizard, PBS client install (Ubuntu/Debian/Arch), multi-target backup management via systemd. Also `pbs-client-uninstaller.sh` and `test-connection.sh`.
- **Docker (in development, v1.2.0)** — `docker/` for Windows/macOS support. `Dockerfile`, per-OS `docker-compose-*.yml`, `scripts/entrypoint.sh` (modes: `daemon|backup|test|status|shell`), Python REST API (`scripts/api-server.py`) + static HTML dashboard. README marks this as not production-ready; native installer is the stable path.

## Verification (no test suite)

```bash
bash -n pbs-client-installer.sh   # syntax check; shellcheck is NOT installed
cd docker && ./build.sh           # build image; test with: docker run --rm pbsclient:latest test
```

Native installs mutate the host (systemd units, `/usr/local/bin/PBSClientTool`, `/etc/proxmox-backup-client`). Real end-to-end testing needs a root Linux host + reachable PBS server.

## Runtime layout (generated at install time)

- `/etc/proxmox-backup-client/targets/<TARGET>.conf` — plain bash files, `chmod 600`, contain `PBS_PASSWORD` in plaintext; loaded via `source` at runtime.
- `/etc/proxmox-backup-client/backup-<TARGET>.sh` — generated backup scripts.
- `/etc/systemd/system/pbs-backup-<TARGET>.{service,timer}` + `pbs-backup-<TARGET>-manual.service`.
- `migrate_legacy_config()` (installer line 232) upgrades old single-target `/etc/proxmox-backup-client/config` → `targets/default.conf`.

## Editing gotchas

- Runtime scripts/systemd units are **heredocs inside the installer** (e.g. lines 1696, 1720, 1913). Changing backup behavior means editing the heredoc templates, not just installer functions.
- The installer contains **two parallel generations of the same logic**: legacy single-target (`interactive_config`, `create_systemd_service`, ~lines 1121–1682) and multi-target versions (`interactive_config_for_target`, `create_systemd_service_for_target`, ~lines 986–1032, 1684–1970). They must be kept in sync; don't assume one is dead code.
- `.conf` files are `source`d, so quoting matters (passwords stored as `VAR="..."`). All scripts use `set -e`.
- Credentials are gitignored (`.env`, `*.key`, `encryption-key*`, `pbs-client.conf`) — never commit real tokens/secrets.

## Docs trust order

Docs are heavily copy-pasted and stale. Trust scripts + `README.md` over `quickstart.md`/`TROUBLESHOOTING.md`. Known mismatches: README references `uninstaller.sh` (real file: `pbs-client-uninstaller.sh`); quickstart uses legacy unit names `pbs-backup.timer` (actual: `pbs-backup-<TARGET>.timer`, default = `pbs-backup-default.timer`).

## Conventions

- `main` branch only; conventional-style commit messages.
- `CHANGELOG.md` is manually maintained (Keep a Changelog + SemVer, `[Unreleased]` section at top) — update it with feature work.
- Native installer version lives in `SCRIPT_VERSION=` (line 12); feature version bumps also appear in README and CHANGELOG.
