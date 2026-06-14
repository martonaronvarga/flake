# nix infrastructure

This is a flake-parts based NixOS infrastructure repository. Hosts are declared once in `parts/hosts.nix`; the same inventory generates `nixosConfigurations`, package build aliases, and Colmena deployment nodes.

## Layout

- `parts/` contains flake-parts modules: host inventory, Colmena integration, and the dev shell.
- `lib/` contains small helpers such as `mkHost`.
- `hosts/<name>/` contains host-specific hardware, disk layout, persistence, users, and local policy.
- `profiles/nixos/` contains opt-in machine profiles such as `base`, `laptop`, `desktop`, `server`, and `laptop-server`.
- `modules/nixos/` contains reusable NixOS functionality.
- `modules/home/` contains Home Manager configuration for the `usu` desktop environment.
- `assets/` contains repository-owned files referenced by modules, such as wallpapers.

## Hosts

- `shade` is my personal Lenovo X1C Gen6 laptop. It imports `base`, `laptop`, and `desktop`, uses Home Manager, impermanence, Hyprland
- `dusk` is a laptop-server / edge host for small services. It imports `base` and `laptop-server`, is managed by Colmena, and deploys to `dusk.local` as `root`.

## Topology

`nix-topology` is wired through flake-parts and receives the generated NixOS configurations. Build the diagrams with:

```sh
nix build .#topology
```

The output appears under `result/` and contains rendered SVG topology diagrams.

## Common Commands

```sh
nix develop
alejandra --check . && statix check . && deadnix --fail . && nix flake check --no-write-lock-file
nix build .#shade
nix build .#dusk
colmena apply --on dusk
```
