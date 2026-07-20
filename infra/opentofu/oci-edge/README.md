# OCI edge infrastructure

The edge is split into two OpenTofu state authorities:

- `core/` runs from encrypted state on `shade` and owns stable networking,
  the AMD fallback, the reserved public IP, and manual backend promotion.
- `capacity/` runs as a restricted service on Ubuntu `gloam` and may only
  create the A1 candidate. It never moves the reserved public IP.

State, variable files, credentials, audit output, and provider directories live
under `/persist/state/opentofu/gloam` or the restricted runtime directories on
`gloam`; they must not be committed.

Before any state migration, stop `gloam-a1-retry.service`, archive the
authoritative state with its lineage and serial, and require zero-change plans
for both roots. Promotion remains a manual core apply from `shade`.
