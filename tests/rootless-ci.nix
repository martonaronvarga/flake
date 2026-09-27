{
  pkgs,
  self,
  ...
}: let
  runner = self.nixosConfigurations.dusk.config.systemd.services.gitea-runner-dusk;
  image = pkgs.dockerTools.buildLayeredImage {
    name = "ci-network-test";
    tag = "latest";
    contents = [pkgs.curl pkgs.busybox];
    config.Cmd = ["/bin/sh"];
  };
in {
  name = "rootless-ci";
  requiredFeatures.kvm = false;
  nodes.machine = {pkgs, ...}: {
    imports = [../modules/nixos/services/rootless-ci.nix];
    local.rootlessCi = {
      enable = true;
      images = [image];
    };
    systemd.services.ci-client = {
      inherit (runner) environment;
      after = ["user@986.service"];
      requires = ["user@986.service"];
      serviceConfig =
        builtins.removeAttrs runner.serviceConfig ["ExecStart" "Restart" "RestartSec"]
        // {
          Type = "oneshot";
          ExecStart = "${pkgs.curl}/bin/curl --fail --unix-socket /run/user/986/podman/podman.sock http://localhost/_ping";
        };
    };
    virtualisation.memorySize = 2048;
    environment.systemPackages = [pkgs.curl pkgs.python3];
    networking.firewall.allowedTCPPorts = [8080];
  };
  testScript = ''
    import shlex

    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("user@986.service")
    user = "runuser -u gitea-runner -- env HOME=/var/lib/gitea-runner XDG_RUNTIME_DIR=/run/user/986 "
    machine.succeed("systemctl start ci-client.service")
    machine.succeed(user + "curl --fail --unix-socket /run/user/986/podman/podman.sock http://localhost/_ping")
    machine.succeed(user + "podman info --format '{{.Host.Security.Rootless}}' | grep '^true$'")
    machine.succeed("test ! -S /run/podman/podman.sock")
    machine.fail("id -nG gitea-runner | grep -w podman")

    # A separate network namespace provides deterministic public/private
    # destinations without depending on Internet availability in the sandbox.
    machine.succeed("ip netns add fixture")
    machine.succeed("ip link add fixture-host type veth peer name fixture-peer")
    machine.succeed("ip link set fixture-peer netns fixture")
    machine.succeed("ip addr add 10.77.0.1/24 dev fixture-host")
    machine.succeed("ip link set fixture-host up")
    machine.succeed("ip -n fixture addr add 10.77.0.2/24 dev fixture-peer")
    machine.succeed("ip -n fixture link set fixture-peer up")
    machine.succeed("ip -n fixture link set lo up")
    machine.succeed("ip -n fixture addr add 8.8.8.8/32 dev lo")
    machine.succeed("ip -n fixture addr add 10.200.200.3/32 dev lo")
    machine.succeed("ip route add 8.8.8.8/32 via 10.77.0.2")
    machine.succeed("ip route add 10.200.200.3/32 via 10.77.0.2")
    machine.succeed("ip addr add 8.8.4.4/32 dev lo")
    machine.succeed("systemd-run --unit=fixture ip netns exec fixture ${pkgs.python3}/bin/python3 -m http.server 8080")
    machine.succeed("systemd-run --unit=host-http ${pkgs.python3}/bin/python3 -m http.server 8080 --bind ::")
    machine.wait_until_succeeds("curl --fail --max-time 2 http://8.8.8.8:8080", timeout=30)
    machine.wait_until_succeeds("curl --fail --max-time 2 http://127.0.0.1:8080", timeout=30)
    machine.succeed("curl --fail http://[::1]:8080")
    machine.succeed("curl --fail http://8.8.4.4:8080")

    def container(command, options="--network=podman"):
        return user + "podman run --rm " + options + " ci-network-test:latest /bin/sh -c " + shlex.quote(command)

    def check_policy():
        machine.succeed(container("curl --fail --max-time 10 http://8.8.8.8:8080"))
        for address in ["10.77.0.1", "10.77.0.2", "10.200.200.3", "169.254.169.254", "8.8.4.4"]:
            command = "curl --fail --max-time 2 http://" + address + ":8080; code=$?; test $code = 7 -o $code = 28"
            machine.succeed(container(command))
        for options in ["--network=host", "--network=host --user=1000"]:
            for address in ["127.0.0.1", "[::1]", "10.200.200.3", "8.8.4.4"]:
                command = "curl --fail --max-time 2 http://" + address + ":8080; code=$?; test $code = 7 -o $code = 28"
                machine.succeed(container(command, options))

    check_policy()
    machine.succeed("systemctl reload nftables.service")
    machine.succeed(user + "podman network create recreated")
    machine.succeed(container("curl --fail --max-time 10 http://8.8.8.8:8080", "--network=recreated"))
    machine.succeed(container("curl --fail --max-time 2 http://10.200.200.3:8080; code=$?; test $code = 7 -o $code = 28", "--network=recreated"))
    check_policy()
    machine.succeed("systemctl stop nftables.service")
    machine.wait_until_fails("systemctl is-active user@986.service")
  '';
}
