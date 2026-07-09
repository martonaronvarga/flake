# Operating dusk

`dusk` is the home server. `shade` is the workstation that builds and deploys
it. `gloam` is the public edge that lets the two keep talking when `shade` is no
longer on the home Wi-Fi.

The setup has two paths on purpose:

- at home, `dusk.local` is convenient and human;
- away from home, the WireGuard address behind `gloam` is stable and boring.

## Local path

`dusk` publishes itself with Avahi as:

```sh
dusk.local
```

`shade` also runs Avahi with `nssmdns4`, so local discovery should be enough on
the home LAN:

```sh
getent hosts dusk.local
ssh usu@dusk.local
```

If that stops working, first check the simple things:

```sh
systemctl status avahi-daemon
resolvectl status
getent hosts dusk.local
```

Some routers isolate Wi-Fi clients or mishandle multicast. If Avahi is healthy
on both machines but `dusk.local` still does not resolve, use the WireGuard path
or a router-side DHCP/DNS entry instead of fighting the LAN.

## WireGuard path

The private management network is:

- `gloam`: `10.200.200.1/24`
- `dusk`: `10.200.200.2/32`

`dusk` dials out to the public edge:

```sh
129.159.11.56:51820
```

It only routes the edge peer through the tunnel:

```nix
allowedIPs = ["10.200.200.1/32"];
```

So this is not a full-tunnel VPN for all home-server traffic. It is a management
and ingress spine: enough to deploy, inspect, and later hang public services off
the edge deliberately.

Quick tunnel checks:

```sh
ssh -F /dev/null usu@dusk.local 'sudo wg show wg0'
ssh -F /dev/null ubuntu@129.159.11.56 'sudo wg show wg0'
```

The useful signs are a recent handshake and non-zero transfer counters on both
sides.

## Gloam today

`gloam` currently runs Ubuntu as `gloam-amd`. The live WireGuard config there is
manual state:

```sh
/etc/wireguard/gloam.key
/etc/wireguard/wg0.conf
systemctl status wg-quick@wg0
```

The NixOS `hosts/gloam` config in this repo already has `dusk`'s real peer key,
so a future NixOS deployment of `gloam` should preserve the intended topology.
Until that migration happens, treat Ubuntu `gloam` as live infrastructure that
must be checked before changing firewall or WireGuard state.

## Deploying dusk

Colmena now uses the remote-capable path by default:

```text
shade -> gloam public SSH -> dusk WireGuard IP
```

The relevant deployment shape is:

```nix
targetHost = "10.200.200.2";
targetUser = "usu";
privilegeEscalationCommand = ["sudo" "-H" "--"];
sshOptions = ["-F" "/dev/null" "-J" "ubuntu@129.159.11.56"];
```

That makes the normal command work from home or away:

```sh
cd /persist/home/usu/flake
nix develop
colmena apply --on dusk
```

The `-F /dev/null` is intentional. Home Manager owns `~/.ssh/config`, and
Colmena should not depend on whether local aliases have been activated yet.

## Triage

When local access breaks, ask whether this is a naming problem or a host problem:

```sh
getent hosts dusk.local
ssh -F /dev/null usu@dusk.local hostname
```

If the name fails but the laptop is online, check Avahi. If Avahi looks fine,
suspect the router and use the tunnel.

When remote deployment breaks, walk the path from the outside inward:

```sh
ssh -F /dev/null ubuntu@129.159.11.56 hostname
ssh -F /dev/null ubuntu@129.159.11.56 'sudo wg show wg0'
ssh -F /dev/null -J ubuntu@129.159.11.56 usu@10.200.200.2 hostname
```

If the last command reports a host key issue for `10.200.200.2`, refresh that
one entry deliberately:

```sh
ssh-keygen -R 10.200.200.2
ssh -F /dev/null -o StrictHostKeyChecking=accept-new \
  -J ubuntu@129.159.11.56 usu@10.200.200.2 hostname
```

If `gloam` has a handshake but cannot reach `dusk`, check whether `dusk` is
still sending keepalives:

```sh
ssh -F /dev/null usu@dusk.local 'sudo wg show wg0'
```

If `dusk` has no handshake, the likely culprits are the public UDP listener on
`gloam`, Oracle network security rules, or a peer key mismatch.
