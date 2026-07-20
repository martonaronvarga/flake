# Grafana on dusk

Grafana on `dusk` is private to the WireGuard network. Prometheus runs on
`dusk`, scrapes `dusk` locally, scrapes `shade` over WireGuard, sends alerts to
local Alertmanager, and Grafana reads Prometheus from localhost.

Open Grafana from `shade`:

```sh
curl -I http://10.200.200.2:3000
```

Then browse to:

```text
http://10.200.200.2:3000
```

Read the admin password only when needed:

```sh
ssh dusk 'sudo cat /run/agenix/grafana-admin-password'
```

## Provisioned Dashboards

Dashboards are provisioned from Nix and should appear without manual creation:

- `Fleet overview`
- `Storage and backup`
- `Service health`
- `Security posture`

If a dashboard is missing, check:

```sh
ssh dusk 'systemctl status grafana --no-pager'
ssh dusk 'journalctl -u grafana -n 120 --no-pager'
```

## First Checks

In Grafana, go to **Connections -> Data sources -> Prometheus -> Save & test**.
It should report that the data source is working.

In **Explore**, run:

```promql
up
node_uname_info
node_systemd_unit_state{name="vaultwarden.service", state="active"}
node_filesystem_avail_bytes{mountpoint="/persist"}
```

If `shade` is missing, check WireGuard from `shade` first:

```sh
ip route get 10.200.200.2
systemctl status wg-quick-wg0.service
```

## Alerting

Prometheus sends alerts to Alertmanager on `127.0.0.1:9093`. Alertmanager sends
email through Gmail SMTP using a runtime env file generated from the existing
Gmail app-password secret. Notifications go directly to
`szemgolyobis@gmail.com`; an offline `shade` does not alert because it is a
laptop, although its metrics remain available whenever it is online.

Check the services:

```sh
ssh dusk 'systemctl is-active prometheus alertmanager alertmanager-smtp-env'
ssh dusk 'journalctl -u prometheus -u alertmanager -n 120 --no-pager'
```

Alertmanager is not exposed through the firewall. Query it from `dusk`:

```sh
ssh dusk 'curl -fsS http://127.0.0.1:9093/-/ready'
```

To test notification delivery without breaking a real service, post a
short-lived synthetic alert from `dusk`:

```sh
ssh dusk 'now=$(date --iso-8601=seconds); end=$(date -d "+2 minutes" --iso-8601=seconds); curl -fsS -H "Content-Type: application/json" -d "[{\"labels\":{\"alertname\":\"ManualDeliveryTest\",\"severity\":\"info\",\"instance\":\"dusk\"},\"annotations\":{\"summary\":\"manual Alertmanager delivery test\"},\"startsAt\":\"$now\",\"endsAt\":\"$end\"}]" http://127.0.0.1:9093/api/v2/alerts'
```

Wait for the configured `group_wait`, then confirm the message arrives in
Gmail. Do not tick real notification delivery until an inbox delivery is
confirmed.

## Weekly Review

Once a week:

1. Open each dashboard.
2. Review the last seven days.
3. Check failed units and backup panels.
4. Check `/persist` free space and disk IO.
5. Record incidents, backup status, and capacity concerns in private notes.
