{
  self,
  lib,
  pkgs,
}: let
  dusk = self.nixosConfigurations.dusk.config;
  gloam = self.nixosConfigurations.gloam.config;
  shade = self.nixosConfigurations.shade.config;
  home = shade.home-manager.users.usu;
  invariants = [
    (builtins.attrNames self.colmenaHive.nodes == ["dusk"])
    (lib.all (name:
      self.colmenaHive.nodes.${name}.pkgs.path
      == self.nixosConfigurations.${name}.pkgs.path
      && self.colmenaHive.nodes.${name}.pkgs.stdenv.hostPlatform.system == self.nixosConfigurations.${name}.pkgs.stdenv.hostPlatform.system)
    (builtins.attrNames self.colmenaHive.nodes))
    (!dusk.systemd.services.i2pd.serviceConfig.DynamicUser)
    (dusk.users.users.i2pd.uid == 150 && dusk.users.groups.i2pd.gid == 150)
    (!lib.elem "wg0" dusk.networking.firewall.trustedInterfaces)
    (!lib.elem 22 gloam.networking.firewall.allowedTCPPorts)
    (lib.elem 22 gloam.networking.firewall.interfaces.wg0.allowedTCPPorts)
    (!dusk.systemd.sockets.podman.enable && !dusk.systemd.services.podman.enable)
    (!lib.elem "podman" dusk.users.users.gitea-runner.extraGroups)
    dusk.networking.nftables.tables.ci-egress.enable
    (gloam.disko.devices.disk.main.content.partitions.root.content.type == "luks")
    (gloam.disko.devices.disk.main.content.partitions.swap.content.type == "luks")
    (home.wayland.windowManager.hyprland.package == null)
    (home.wayland.windowManager.hyprland.portalPackage == null)
    (shade.age.secrets.ttk-mail-password.path == "/run/agenix/ttk-mail-password")
    (shade.age.secrets.ttk-mail-password.owner == "usu")
    (shade.age.secrets.ttk-mail-password.mode == "0400")
    (lib.elem "/var/lib/martonaronvarga" dusk.local.backups.removable.paths)
    (lib.elem "shade.rollback_home=1" shade.boot.kernelParams)
  ];
in
  assert lib.assertMsg (lib.all (value: value) invariants) "Host security/architecture invariant failed";
    pkgs.runCommand "configuration-invariants" {} "touch $out"
