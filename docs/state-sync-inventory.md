# State And Sync Inventory

This is the staging checklist for lowercase directories, Syncthing, and
impermanence coverage. Do not enable broad sync until every synced path is
explicitly listed here or in a follow-up issue.

## Directory Policy

- Prefer lowercase user directories:
  `~/documents`, `~/downloads`, `~/pictures`, `~/music`, `~/videos`.
- Keep generated directories out of sync:
  `result`, `result-*`, `.direnv`, `node_modules`, `target`, caches.
- Sync project sources explicitly, not the entire home directory.
- Enable versioning for folders containing documents, notes, or source work.

## Candidate Syncthing Folders

- `~/documents`: explicit documents and notes only.
- `~/pictures`: original images and curated assets.
- `~/music`: personal library if needed on both machines.
- `~/documents/dev`: source trees that are not already Git remotes.

## Impermanence Review

Before moving a directory to lowercase or adding it to Syncthing:

```sh
nix eval .#nixosConfigurations.shade.config.home-manager.users.usu.home.persistence."/persist".directories --json | jq .
nix eval .#nixosConfigurations.shade.config.environment.persistence."/persist".directories --json | jq .
```

Then verify the live path:

```sh
test -d /persist/home/usu
find /persist/home/usu -maxdepth 2 -mindepth 1 | sort
```

Only delete old mixed-case paths after the new path is persisted, synced if
needed, and backed up.
