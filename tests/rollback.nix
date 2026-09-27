{
  pkgs,
  self,
}: let
  scripts = map (host:
    pkgs.writeShellScript "${host}-rollback-test"
    self.nixosConfigurations.${host}.config.boot.initrd.systemd.services.btrfs-rollback.script) ["shade" "dusk" "gloam"];
in {
  name = "encrypted-root-rollback";
  requiredFeatures.kvm = false;
  nodes.machine = {pkgs, ...}: {
    virtualisation = {
      memorySize = 1024;
      emptyDiskImages = [512];
    };
    boot.supportedFilesystems = ["btrfs"];
    environment.systemPackages = [pkgs.btrfs-progs pkgs.cryptsetup];
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("printf 'disposable-test-key' > /tmp/key")
    machine.succeed("cryptsetup luksFormat --batch-mode /dev/vdb /tmp/key")
    machine.succeed("cryptsetup open /dev/vdb cryptroot --key-file /tmp/key")
    machine.succeed("mkfs.btrfs /dev/mapper/cryptroot")
    machine.succeed("mkdir -p /mnt")

    for script in ${builtins.toJSON (map toString scripts)}:
        machine.succeed("mount -o subvol=/ /dev/mapper/cryptroot /mnt")
        machine.succeed("btrfs subvolume create /mnt/root")
        machine.succeed("btrfs subvolume snapshot -r /mnt/root /mnt/root-blank")
        machine.succeed("btrfs subvolume create /mnt/root/nested")
        machine.succeed("btrfs subvolume create '/mnt/root/nested/with spaces'")
        machine.succeed("touch /mnt/root/discard /mnt/keep")
        machine.succeed("umount /mnt")
        machine.succeed(script)
        machine.fail("mountpoint -q /mnt")
        machine.succeed("mount -o subvol=/ /dev/mapper/cryptroot /mnt")
        machine.succeed("test -f /mnt/keep && test ! -e /mnt/root/discard && test ! -e /mnt/root/nested")
        machine.succeed("touch /mnt/root/preserve-on-failure")
        machine.succeed("btrfs subvolume delete /mnt/root-blank")
        machine.succeed("umount /mnt")
        machine.fail(script)
        machine.fail("mountpoint -q /mnt")
        machine.succeed("mount -o subvol=/ /dev/mapper/cryptroot /mnt")
        machine.succeed("test -f /mnt/root/preserve-on-failure")
        machine.succeed("touch /mnt/root-blank")
        machine.succeed("umount /mnt")
        machine.fail(script)
        machine.fail("mountpoint -q /mnt")
        machine.succeed("mount -o subvol=/ /dev/mapper/cryptroot /mnt")
        machine.succeed("test -f /mnt/root/preserve-on-failure")
        machine.succeed("btrfs subvolume delete /mnt/root && rm /mnt/root-blank")
        machine.succeed("umount /mnt")
    machine.succeed("cryptsetup close cryptroot")
  '';
}
