# Email workflow plan

## Objective

Add `varga.marton.aron@ttk.hu` as a separate HUN-REN TTK mailbox without
changing the Gmail identity used by infrastructure services, then optionally
move both personal and institutional mail to an offline, searchable workflow.

## Phase 1: verify the TTK service

1. Confirm the supported settings with HUN-REN TTK IT:
   - IMAP host, port, TLS mode, and login name;
   - SMTP submission host, port, TLS mode, and permitted sender;
   - password, application-password, MFA, or OAuth requirements;
   - VPN or institutional-network requirements;
   - canonical Sent, Drafts, Trash, Junk, and Archive folder names.
2. Use `imap.ttk.hu` and `smtp.ttk.hu` only after those settings are confirmed.
   Public DNS identifies them as the institutional endpoints, but does not
   publish enough information to infer authentication or submission policy.
3. Test login and sending independently before integrating the account into
   aerc. Send a message to Gmail, reply to it, and verify the envelope sender,
   From header, Sent folder, and threading in both directions.

## Phase 2: add a direct aerc account

1. Refactor the account-specific values in `aerc.nix` so Gmail OAuth helpers,
   folder mapping, identity, and signature remain explicitly personal.
2. Add a separate `work` account for `varga.marton.aron@ttk.hu` using direct
   TLS IMAP and authenticated SMTP.
3. Store the TTK credential as an agenix secret exposed below `/run/agenix`.
   Do not put it in the Nix store or generated `accounts.conf`.
4. Give the work account its own HUN-REN signature and verified folder map.
5. Enable automatic GPG signing only after the signing key has a suitable UID
   for the TTK address.
6. Extend address completion to combine Google CardDAV results with addresses
   learned from institutional mail.
7. Validate receiving, replying, composing, attachments, drafts, deletion,
   archiving, and credential failure notifications.

This phase is the minimum recommended deployment. It preserves the current
simple architecture and isolates account or authentication problems.

## Phase 3: improve direct-account reliability

1. Add an independent user service or timer for TTK connectivity checks so a
   failed institutional account cannot hide Gmail failures.
2. Decide whether five-minute polling is sufficient. If not, evaluate one
   independently supervised IMAP IDLE watcher per account.
3. Keep Gmail as `inventory.mail.sender`; Forgejo, monitoring, and other
   services must not silently switch to the personal work mailbox.
4. Document credential rotation and recovery commands next to the module.

## Phase 4: optional offline and unified workflow

Adopt this phase only after both direct accounts are stable.

1. Synchronize each account into a separate Maildir with `mbsync`.
2. Start with INBOX, Sent, Drafts, Trash, and Archive channels. Add wildcard
   folder synchronization only after checking for duplicate Gmail-label paths.
3. Index the common mail root with notmuch and synchronize Maildir flags.
4. Add saved queries for unified inbox, unread mail, flagged mail, TTK mail,
   and recent threads.
5. Point aerc at notmuch plus the appropriate Maildir store so searches are
   unified while moves and sent-message copies still work.
6. Send through account-specific `msmtp` profiles and add a recoverable
   outgoing queue for offline use.
7. Run incremental inbox synchronization frequently and full synchronization
   less often. Keep services independent per account to contain failures.
8. Persist `~/.mail`, `~/.local/state/isync`, the notmuch database, and the
   outgoing queue under `/persist` with restrictive permissions.

## Acceptance criteria

- Both accounts receive and send with the correct identity.
- Replies select the account that received the original message.
- Credentials never enter the Nix store, repository, process arguments, or
  service logs.
- Gmail service mail remains unaffected.
- Folder operations agree with Roundcube and any mobile client.
- Failure of either account is visible and does not stop the other account.
- After the optional migration, mail is readable and searchable offline and
  queued messages are retried safely after connectivity returns.
