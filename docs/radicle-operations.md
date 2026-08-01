# Radicle on shade, dusk, and gloam

Radicle complements Forgejo; it does not replace `git.martonaronvarga.dev` or
the Forgejo Actions runner.

## Topology

- `shade` owns the personal Radicle identity and working repositories.
- `dusk` runs the separate always-on seed identity, `radicle-node`, the
  read-only `radicle-httpd` API, and Radicle Explorer.
- Ubuntu `gloam` exposes the node and HTTPS services through WireGuard.
- `seed.martonaronvarga.dev:8776` is the public peer protocol endpoint.
- `https://seed.martonaronvarga.dev/api/v1` is the direct read-only seed API.
- `https://radicle.martonaronvarga.dev` is the browser Explorer; its `/api/`
  path exposes the same API without a cross-origin browser dependency.

The seed DNS record must be Cloudflare **DNS only**. Cloudflare's regular
orange-cloud proxy does not forward the Radicle TCP protocol on port 8776.
The Explorer hostname may remain proxied.

## Security model

The dusk seed and the shade user have separate Ed25519 identities. The seed
private key is stored only as `secrets/radicle_seed_key.age` in the flake and
as a systemd credential at runtime. The personal key stays under
`~/.radicle/keys` on shade.

The seed uses a default-deny selective seeding policy. Private repositories are
encrypted in transit and selectively replicated, but they are not encrypted at
rest on an authorized node. Root on dusk can read their contents. Never assume
that making a formerly public repository private retracts copies already held
by peers.

Official references:

- [User guide](https://radicle.xyz/guides/user/)
- [Protocol guide](https://radicle.xyz/guides/protocol/)
- [Seeder guide](https://radicle.xyz/guides/seeder/)
- [Official downloads](https://radicle.xyz/download)

## First deployment

Create these Cloudflare records before requesting certificates:

| Name | Type | Value | Proxy |
| --- | --- | --- | --- |
| `seed` | A | `129.159.11.56` | DNS only |
| `radicle` | A | `129.159.11.56` | Proxied |

Apply the tracked OCI ingress change from shade:

```sh
cd /persist/home/usu/flake/infra/opentofu/oci-edge/core
tofu fmt -check
tofu validate
tofu plan -detailed-exitcode
tofu apply
```

Deploy dusk before opening the public relay:

```sh
cd /persist/home/usu/flake
nix develop -c colmena apply --on dusk
ssh dusk 'systemctl is-active radicle-node radicle-httpd nginx'
ssh dusk 'sudo rad-system self'
ssh dusk 'curl -fsS http://10.200.200.2:8082/api/v1'
curl -fsS -H 'Host: radicle.martonaronvarga.dev' \
  http://10.200.200.2:8083/ >/dev/null
```

Then install the tracked Ubuntu edge configuration:

```sh
scripts/deploy-gloam-radicle --check
scripts/deploy-gloam-radicle --apply
```

The helper backs up replaced files under `/var/backups/radicle-edge`, obtains
separate Certbot certificates, installs a systemd socket proxy for TCP 8776,
validates Nginx before reload, and opens both UFW and gloam's provider-supplied
persistent iptables firewall only after validation. OCI's NSG must also permit
TCP 8776.

## Initialize shade

After switching shade, create the personal identity once:

```sh
rad auth --alias usu
systemctl --user restart radicle-node
rad self
rad node status
```

The user service binds to localhost. It can dial the public seed but does not
expose shade on the LAN or Internet. Obtain the complete seed address with:

```sh
rad node connect \
  'z6MknCPa2uX2xtrRHHj5e9joMAmAnukNznzTgqSLLbJ1uHtv@seed.martonaronvarga.dev:8776'
```

## Publish and seed a repository

Keep Forgejo as `origin` and let `rad init` add the `rad` remote:

```sh
cd repository
rad init
git remote -v
rad sync
```

Explicitly seed the resulting RID on dusk:

```sh
ssh dusk
sudo rad-system seed 'rad:<RID>' --from '<shade-NID>'
sudo rad-system seed
```

Confirm availability while shade's node is stopped:

```sh
systemctl --user stop radicle-node
rad clone 'rad:<RID>' --seed '<seed-NID>'
systemctl --user start radicle-node
```

For a private repository, use `rad init --private`, add collaborator and dusk
seed DIDs to its allow list, and use `rad seed ... --from ...` on dusk. Before
storing sensitive data, use a dummy private repository and confirm its RID is
absent from the public API and Explorer.

## Public repository inventory

Forgejo is authoritative, GitHub is a Forgejo-managed push mirror, and Radicle
is an additional public replica. `graph` intentionally has no Radicle identity.

| Repository | Default branch | Radicle RID |
| --- | --- | --- |
| `flake` | `main` | `rad:zKjLfiXhv6bDM45sQYmc5USsNj9E` |
| `rfcs` | `main` | `rad:z2tptGJa4cpaYngCznDqTR5EsBcjC` |
| `alea` | `main` | `rad:z4423gBk4sGrUZHVx4PdTAcJzKZ57` |
| `ba-thesis` | `main` | `rad:z3jRy39UjS4zHpPas6umX4ha89xQu` |
| `cc-mverse` | `main` | `rad:z3jrfAWRRg6nftXvaHQNARhxzELRX` |
| `cogex` | `main` | `rad:z47Grp8FZEDoJ92KRTQFaeNbrAyaS` |
| `cse_simulation` | `master` | `rad:z4HvfSYxqPaG5FjrqCjqGb5Np3htg` |
| `lp-simplex` | `main` | `rad:z4X2TuTucuBXNV8ijLCT4kcF8JTqe` |
| `math` | `experiment/wiener-ratio-bounds` | `rad:z4XNG5K3JUEzftSjErcGtJi5kiEcA` |

Local checkouts use `origin` for Forgejo, `github` for the read-only GitHub
mirror, and `rad` for Radicle. Forgejo SSH listens only through WireGuard at
the `forgejo` SSH alias. Shade's Radicle node likewise accepts inbound protocol
connections only on its WireGuard address so dusk can fetch repositories.

For routine publication, run this from a checkout or pass its path:

```sh
repo-publish
repo-publish /persist/home/usu/documents/dev/cogex
```

The helper pushes and verifies Forgejo first, synchronizes Radicle when the
checkout has an RID, and then waits for Forgejo's GitHub push mirror. It warns
about a dirty worktree but publishes committed work only. Do not push directly
to `github` during normal operation.

Shade's encrypted identity passphrase is stored as the agenix secret
`radicle_user_passphrase.age`; the user service reads it from
`/run/agenix/radicle-user-passphrase`. Rotate it together with the encrypted
Radicle key and never place its plaintext in Git or a systemd unit.

## Routine operations

```sh
# shade
systemctl --user status radicle-node
rad node status
rad sync

# dusk
ssh dusk 'systemctl is-active radicle-node radicle-httpd'
ssh dusk 'sudo rad-system node status'
ssh dusk 'sudo rad-system seed'
ssh dusk 'journalctl -u radicle-node -u radicle-httpd -n 200 --no-pager'

# gloam
ssh gloam 'systemctl is-active radicle-proxy.socket nginx'
ssh gloam 'sudo ss -lntp | grep :8776'

# public
curl -fsS https://seed.martonaronvarga.dev/api/v1
curl -fsSI https://radicle.martonaronvarga.dev/
```

After suspend, `systemctl --user is-active radicle-node` and
`rad node status` should recover without manual intervention.

## Backups and restore

Shade's Restic job includes `/persist/home/usu`, including personal Radicle
state. Dusk's removable Restic backup includes `/var/lib/radicle`. The seed
private key is independently protected by agenix.

Restore the encrypted key and `/var/lib/radicle` with ownership
`radicle:radicle` and mode `0750`, then deploy the same NixOS generation. Never
run two live seeds with the same restored private key. Public repositories can
be reconstructed from healthy peers, but identity keys cannot.

## Upgrade and rollback

Radicle versions follow the locked nixpkgs input. Review upstream migration
notes before updating it, then build dusk and test the API before deployment.

To remove public access without deleting data:

```sh
ssh gloam 'sudo systemctl disable --now radicle-proxy.socket'
ssh gloam 'sudo ufw delete allow 8776/tcp'
ssh gloam 'sudo iptables -D INPUT -p tcp --dport 8776 -j ACCEPT'
ssh gloam 'sudo sh -c "iptables-save > /etc/iptables/rules.v4"'
```

Remove or disable the public DNS records and OCI NSG rule, then roll dusk back
to its previous NixOS generation. Preserve `/var/lib/radicle` and encrypted
keys until a restore test or deliberate decommission is complete.
