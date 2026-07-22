# nix infrastructure

This is my flake-parts based NixOS infrastructure repository. Hosts are declared once in `parts/hosts.nix`; the same inventory generates `nixosConfigurations`, package build aliases, and `colmenaHive` deployment nodes.

## Layout

- `parts/` contains flake-parts modules: host inventory, Colmena integration, and the dev shell.
- `lib/` contains small helpers such as `mkHost`.
- `hosts/<name>/` contains host-specific hardware, disk layout, persistence, users, and local policy.
- `profiles/nixos/` contains opt-in machine profiles such as `base`, `laptop`, `desktop`, `server`, and `laptop-server`.
- `modules/nixos/` contains reusable NixOS functionality.
- `modules/home/` contains Home Manager configuration for the `<user>`environment.
- `assets/` contains repository-owned files referenced by modules, such as wallpapers.

## Hosts

- `shade` is my personal Lenovo X1C 6th Gen laptop. It imports `base`, `laptop`, and `desktop`, uses Home Manager, impermanence, Hyprland.
- `dusk` is a laptop-server / edge host for small services. It imports `base` and `laptop-server`, is managed by Colmena, and deploys to `dusk.local` as `root`.

## Topology

![Declarative infrastructure topology](assets/topology.svg)

The diagram is generated from the same NixOS configurations that define the hosts. Host roles, service metadata, the WireGuard mesh, and the public Cloudflare ingress are declared through the local topology module. Regenerate the export with:

```sh
nix build .#topology
cp result/main.svg assets/topology.svg
```

The build also produces `result/network.svg`, a network-centric view.

## Common Commands

```sh
nix develop
nix flake check --no-write-lock-file
nh os build
nh os test
nh os switch
dix /run/current-system result
colmena build --on dusk
colmena apply --on dusk
```
