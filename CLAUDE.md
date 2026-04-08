# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository orchestrates automated Transifex translation synchronization across 36 ownCloud repositories using GitHub Actions. There is no build system for this repo itself — it is a configuration-only repository.

## Key Files

- **`.github/workflows/translations.yml`** — The active CI pipeline. Matrix job (one entry per managed repo) plus a notification job.
- **`.drone.star`** — Legacy Drone CI configuration (superseded by the GitHub Actions workflow above).
- **`config/github/notification.sh`** — Sends Matrix/Element chat notifications on build completion (used by the notification job).
- **`config/drone/notification.sh`** — Legacy Drone notification script.
- **`docs/sync_issues.md`** — Troubleshooting guide for translation string issues (unescaped characters, etc.).
- **`docs/migrate.md`** — Guide for migrating resources between Transifex projects using the `tx` CLI.

## Architecture

The pipeline system uses a matrix job model:

- `.github/workflows/translations.yml` defines a `sync` job with a matrix of all managed repositories running in parallel, followed by a `notification` job that depends on `sync`.
- All steps run inside the `owncloudci/transifex:latest` Docker container (via `container:` at the job level).
- The matrix encodes all repo-specific configuration: name, mode, branch, sub_path, package_manager, HTTPS clone URL, SSH push URL.

### Translation Modes

Each repository is assigned one of three modes (set via the `mode` field in the matrix):

| Mode | Description |
|------|-------------|
| `old` | Legacy `l10n` tool + `tx` CLI. Steps: `l10n write` → `tx push` → `tx pull` → `l10n read` |
| `make` | Modern Makefile targets: `l10n-read`, `l10n-push`, `l10n-pull`, `l10n-write`, `l10n-clean` |
| `native` | Android apps — special handling |

### Pipeline Steps (per repo)

1. Wipe checkout (clean slate)
2. Clone repo via HTTPS
3. (old mode only) Create translation directory
4. Reader — extract translatable strings
5. Push — send new strings to Transifex
6. Pull — fetch translations from Transifex
7. Writer — write translations to repo files
8. Cleanup — remove temp `.po`/`.pot` files
9. Commit — commit with standard message
10. Show commit — log diff
11. Switch remote — swap to SSH for push
12. Push commit — push to repository

Steps 5 (push) and 11–12 (SSH push) only run when `github.ref == 'refs/heads/master'`.

### GitHub Actions Secrets

Three secrets must be configured in the repository settings:

| Secret | Purpose |
|--------|---------|
| `TX_TOKEN` | Transifex API token |
| `GIT_PUSH_SSH_KEY` | SSH private key for pushing commits back to repos |
| `MATRIX_TOKEN` | Matrix/Element bot token for notifications |

## Local Testing

To manually test translation sync for a specific repo (e.g., `guests`):

```bash
git clone git@github.com:owncloud/guests /path/to/repo
cd /path/to/repo
export TX_TOKEN=<your_transifex_token>
tx pull -a --skip --minimum-perc=75 -f
```

For **old mode** repos using the legacy l10n tool:

```bash
docker run -ti -v $(pwd):/mnt -w /mnt --entrypoint=/bin/bash \
  owncloudci/transifex:latest -c "cd l10n; l10n 'guests' write"
```

To trigger the sync manually, use the **Actions → Translation Sync → Run workflow** button in the GitHub UI, or via the CLI:

```bash
gh workflow run translations.yml
```

## Adding a New Repository

Add a new entry under `matrix.include` in `.github/workflows/translations.yml`. Copy an existing entry of the same mode (old/make) and update `name`, `url`, `git`, `branch`, and `sub_path` as needed. The `sub_path` is `l10n` for old mode and `.` for make mode unless the repo uses a non-standard layout (see `twofactor_privacyidea` for an example).
