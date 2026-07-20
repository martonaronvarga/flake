# Forgejo on dusk

Operations guide for the Forgejo instance at `git.martonaronvarga.dev`.

## Current topology

- Public web: `https://git.martonaronvarga.dev`
- Public edge: Ubuntu `gloam` at `129.159.11.56`
- Backend: NixOS `dusk` at `10.200.200.2` over WireGuard
- Forgejo HTTP: `10.200.200.2:3001`

`dusk` is declarative in this flake. `gloam` is still an Ubuntu edge host, so
the live nginx/certbot/firewall changes there are currently manual drift from
the future NixOS `gloam` config.

## Sign in for the first time

Forgejo registration is disabled. Create the first admin account over SSH:

```sh
ssh usu@10.200.200.2

forgejo_bin="$(systemctl cat forgejo | sed -n 's|^ExecStart=\([^ ]*\).*|\1|p')"
sudo -u forgejo env \
  FORGEJO_WORK_DIR=/var/lib/forgejo \
  FORGEJO_CUSTOM=/var/lib/forgejo/custom \
  "$forgejo_bin" admin user create \
    --admin \
    --username usu \
    --email git@martonaronvarga.dev \
    --password 'CHANGE_ME'
```

Then sign in at `https://git.martonaronvarga.dev/user/login` and rotate the
password immediately in the web UI.

After signing in:

1. Add your SSH public key under user settings.
2. Keep registration disabled.
3. Create colleague accounts manually from the admin UI when needed.
4. Use private repositories by default.

## Git remotes

On `shade`, Home Manager configures SSH host aliases and Git URL rewrites for
both GitHub and this Forgejo instance.

Short HTTPS remotes:

```sh
git clone gh-https:martonaronvarga/example.git
git clone forge-https:usu/example.git
```

Expanded forms:

HTTPS:

```sh
git clone https://github.com/martonaronvarga/example.git
git clone https://git.martonaronvarga.dev/usu/example.git
```

GitHub HTTPS uses `gh auth git-credential`, so run `gh auth login` once before
using HTTPS GitHub remotes. Forgejo HTTPS uses Git's credential cache with user
`usu`; use a Forgejo access token when prompted.

## Validation commands

From any internet-connected host:

```sh
curl -fsSI https://git.martonaronvarga.dev/
```

On `dusk`:

```sh
systemctl is-active forgejo postgresql forgejo-secrets
systemctl --no-pager --failed
ss -ltnp | grep ':3001'
journalctl -u forgejo -n 120 --no-pager
```

On `gloam`:

```sh
sudo nginx -t
sudo ss -ltnp | grep -E ':(80|443)'
sudo iptables -S INPUT | sed -n '1,16p'
sudo ufw status verbose
```

## OCI ingress

Required public ingress:

- TCP 80: HTTP and ACME
- TCP 443: HTTPS
- UDP 51820: WireGuard

Public Forgejo SSH is intentionally unsupported. Git access uses HTTPS tokens.

## Live Ubuntu edge changes

Until `gloam` is migrated to NixOS, the edge has manual config:

- `/etc/nginx/sites-available/git.martonaronvarga.dev`
- `/etc/nginx/sites-enabled/git.martonaronvarga.dev`

Any old port-2222 nginx stream, UFW, iptables, or OCI NSG rules are obsolete
and should be removed by the interim edge hardening procedure.

## Mail

Forgejo SMTP uses Gmail over SMTPS. The password is stored in:

```text
secrets/forgejo_mailer_password.age
```

Runtime decrypted path on `dusk`:

```text
/run/agenix/forgejo-mailer-password
```

If mail fails, check:

```sh
journalctl -u forgejo -n 200 --no-pager | grep -i mail
```
