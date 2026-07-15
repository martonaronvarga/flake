# Dusk Media Role

This is a design placeholder. Do not deploy media or torrent services until the
backup and recovery TODOs have passed a real restore drill.

## Goals

- Store reproducible media separately from irreplaceable personal state.
- Keep bandwidth and legal exposure explicit.
- Exclude reproducible media from encrypted off-site backups by default.
- Monitor disk pressure before adding large libraries.

## Storage Layout

Proposed paths:

- `/persist/media/library`: curated media library.
- `/persist/media/incoming`: temporary downloads and imports.
- `/persist/media/torrents`: torrent client state and incomplete data.
- `/persist/backups/media-metadata`: small metadata exports only.

## Network Policy

- Prefer WireGuard-only admin UI access.
- Public access requires a separate review.
- Torrent traffic must have bandwidth limits before enablement.
- VPN or network isolation must be decided before any torrent daemon runs.

## Backup Policy

- Back up metadata, configuration, and manifests.
- Do not back up reproducible video/audio payloads off-site by default.
- Add Grafana panels for `/persist/media` free space and IO before import.

## Open Decisions

- Whether torrenting is in scope at all.
- Whether media should be served only on LAN/WireGuard.
- Whether a future storage host should own bulk media instead of `dusk`.
